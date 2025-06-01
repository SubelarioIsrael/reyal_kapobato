import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes.dart';
import 'pages/student/student_daily_checkin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String url = 'https://yferkhdvbykfnsdnstwu.supabase.co';
  String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZXJraGR2YnlrZm5zZG5zdHd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYyMzY0MDUsImV4cCI6MjA2MTgxMjQwNX0.4nNYEgRkSmFQwa_2cuQCNEsDywHlUYXKBmY0248dzxA';

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
