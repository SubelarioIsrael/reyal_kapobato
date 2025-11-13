import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'package:breathe_better/services/push_noti_service.dart';
import 'routes.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('FCM background message received: ${message.messageId}, data: ${message.data}');
}

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("c0c552e3-f8d6-49fc-9d0c-a7b23267b9f0");
  await OneSignal.Notifications.requestPermission(true);

  await dotenv.load(fileName: 'important_stuff.env');

  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
    throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
  }

  await Supabase.initialize(url: url, anonKey: anonKey);

  final pushNotiService = PushNotiService();
  await pushNotiService.initNotification();

  await _registerDeviceWithSupabase(pushNotiService);

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    if (event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.tokenRefreshed) {
      await _registerDeviceWithSupabase(pushNotiService);
    } else if (event == AuthChangeEvent.signedOut) {
      pushNotiService.setCurrentUserId('');
    }
  });
}

Future<void> _registerDeviceWithSupabase(PushNotiService pushNotiService) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  pushNotiService.setCurrentUserId(userId);

  final playerId = OneSignal.User.pushSubscription.id;
  if (playerId == null) return;

  await supabase.from('device_push_tokens').upsert({
    'user_id': userId,
    'onesignal_player_id': playerId,
    'platform': 'android',
    'last_seen': DateTime.now().toIso8601String(),
  }, onConflict: 'user_id,onesignal_player_id');
}

Future<void> main() async {
  await initApp();
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
    // Set navigator key for push notification service
    PushNotiService.setNavigatorKey(_navigatorKey);
    _setupAuthListener();
    _setupDeepLinkListener();
    _setupFcmListeners(); // Added: register FCM listeners
  }

  void _setupAuthListener() {
    final pushNotiService = PushNotiService();
    
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      print('Auth event: $event');

      // Set user ID in push notification service for signed in users
      if (event == AuthChangeEvent.signedIn && session?.user.id != null) {
        pushNotiService.setCurrentUserId(session!.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        pushNotiService.setCurrentUserId('');
      }

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
    final links = _appLinks; // local reference ensures it’s ready

    links.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    links.uriLinkStream.listen(_handleDeepLink);
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

  // New: set up FCM listeners for terminated, foreground, and background->opened states
  void _setupFcmListeners() {
    // Terminated state: if the app was opened from a notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('FCM initialMessage (terminated -> opened): ${message.messageId}');
        _handleMessageOpenedApp(message);
      }
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('FCM onMessage (foreground): ${message.messageId}, notification: ${message.notification}');
      _showForegroundNotification(message);
    });

    // Background (app in background) -> user taps notification and app opens/resumes
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('FCM onMessageOpenedApp (background -> opened): ${message.messageId}');
      _handleMessageOpenedApp(message);
    });
  }

  // Show simple in-app feedback for foreground notifications.
  void _showForegroundNotification(RemoteMessage message) {
    final ctx = _navigatorKey.currentContext;
    final notif = message.notification;
    final title = notif?.title ?? message.data['title'] ?? 'Notification';
    final body = notif?.body ?? message.data['body'] ?? '';

    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            '$title\n$body',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Note: If you later add a local notification helper in PushNotiService,
    // you can call it here to show a system notification while app is foreground.
  }

  // Handle navigation when a notification is opened (from background or terminated).
  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    print('Handling opened FCM message: $data');

    // Example routing: notification payload can include a 'route' key
    final route = data['route'] as String?;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route != null && route.isNotEmpty) {
        _navigatorKey.currentState?.pushNamed(route, arguments: data);
      } else {
        // Default fallback route when no route provided
        _navigatorKey.currentState?.pushNamed('/messages', arguments: data);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BreatheBetter',
      navigatorKey: _navigatorKey,
      initialRoute: '/login',
      routes: appRoutes,
    );
  }
}
