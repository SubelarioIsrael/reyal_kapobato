import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BreatheBetter',
      initialRoute: '/login',
      routes: appRoutes,
    );
  }
}
