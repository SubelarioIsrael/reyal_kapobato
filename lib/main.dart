import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes.dart';
import 'pages/student/student_daily_checkin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'important_stuff.env');

  final String? url = dotenv.env['SUPABASE_URL'];
  final String? anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
  }

  await Supabase.initialize(url: url, anonKey: anonKey);
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
