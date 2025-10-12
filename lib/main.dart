import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("c0c552e3-f8d6-49fc-9d0c-a7b23267b9f0");
  await OneSignal.Notifications.requestPermission(true);

  await dotenv.load(fileName: 'important_stuff.env');

  final String? url = dotenv.env['SUPABASE_URL'];
  final String? anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
  }

  await Supabase.initialize(url: url, anonKey: anonKey);

  Future<void> registerDeviceWithSupabase() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final playerId = OneSignal.User.pushSubscription.id;
    if (playerId == null) return;

    try {
      await supabase.from('device_push_tokens').upsert({
        'user_id': userId,
        'onesignal_player_id': playerId,
        'platform': 'android',
        'last_seen': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,onesignal_player_id');
    } catch (_) {}
  }

  // Register immediately if already logged in
  await registerDeviceWithSupabase();

  // Also register whenever auth state changes to a signed-in user
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    if (event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.tokenRefreshed) {
      await registerDeviceWithSupabase();
    }
  });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _setupDeepLinkListener();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      
      print('Auth event: $event');
      
      // Handle password recovery
      if (event == AuthChangeEvent.passwordRecovery) {
        print('Password recovery event detected');
        // Navigate to reset password page when user clicks the reset link
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushReplacementNamed('/reset-password');
        });
      }
      
      // Note: Removed automatic email verification message on sign in
      // This was causing the message to show on every login for users with verified emails
      // Email verification success is now only handled through the deep link flow
      
      // Also handle token refresh which might happen during password recovery
      if (event == AuthChangeEvent.tokenRefreshed && session != null) {
        // Check if this is a password recovery session
        final accessToken = session.accessToken;
        if (accessToken.isNotEmpty) {
          // Additional check for recovery context if needed
          print('Token refreshed, checking if password recovery...');
        }
      }
    });
  }

  void _setupDeepLinkListener() {
    _appLinks = AppLinks();
    
    // Handle app launch from deep link
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
    
    // Handle deep links while app is running
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    print('Received deep link: $uri');
    
    // Handle password reset deep link
    if (uri.scheme == 'breathebetter' && uri.host == 'reset-password') {
      print('Password reset deep link detected');
      
      // Extract query parameters if needed (like access_token, refresh_token)
      final queryParams = uri.queryParameters;
      print('Query parameters: $queryParams');
      
      // Navigate to reset password page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushReplacementNamed('/reset-password');
      });
    }
    
    // Handle email verification deep link
    if (uri.scheme == 'breathebetter' && uri.host == 'verify-email') {
      print('Email verification deep link detected');
      
      // Extract query parameters
      final queryParams = uri.queryParameters;
      print('Query parameters: $queryParams');
      
      // Navigate to login page with verification success message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushReplacementNamed('/login');
        
        // Show success message after navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text(
                  'Email verified successfully! You can now log in.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Color(0xFF4CAF50),
                duration: Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'BreatheBetter',
      initialRoute: '/login',
      routes: appRoutes,
    );
  }
}
