import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:breathe_better/routes.dart';
import 'package:breathe_better/main.dart' show MyApp;

Future<void> testMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  // // Load environment variables
  // await dotenv.load(fileName: 'important_stuff.env');

  // // Initialize Supabase (mocked/stubbed backend recommended)
  // await Supabase.initialize(
  //   url: dotenv.env['SUPABASE_URL'] ?? '',
  //   anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  // );

  // Do not call Firebase, OneSignal, or PushNotiService here.
  runApp(const MyApp());
  
  // Give the app a moment to initialize
  await Future.delayed(const Duration(milliseconds: 500));
}
