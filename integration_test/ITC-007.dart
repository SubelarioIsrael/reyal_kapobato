import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'test_main.dart' as app;

extension PumpUntilFound on WidgetTester {
  Future<void> pumpUntilFound(Finder finder, {Duration timeout = const Duration(seconds: 10)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw Exception('Widget not found within $timeout: $finder');
  }
}
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase only once before all tests
  setUpAll(() async {
    try {
      await dotenv.load(fileName: 'important_stuff.env');
      try {
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        );
      } catch (_) {
        // ignore
      }
    } catch (_) {
      // ignore
    }
  });

  group('ITC-007: Test integration of dashboard data with assessment results.', () {
    Future<void> login(WidgetTester tester, String email, String password) async {
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('login_email')));
      await tester.enterText(find.byKey(const Key('login_email')), email);
      await tester.enterText(find.byKey(const Key('login_password')), password);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
    }
    Future<void> logout(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('drawer_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();
      // Wait for login screen to reappear
      await tester.pumpUntilFound(find.byKey(const Key('login_email')));
    }

    testWidgets('Dashboard displays assessment-derived metrics (weekly mood bar).', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();

      final studentEmail = dotenv.env['STUDENT_EMAIL'] ?? 'itzmethresh@gmail.com';
      final studentPass = dotenv.env['STUDENT_PASSWORD'] ?? 'allan123';

      // Log in
      await login(tester, studentEmail, studentPass);

      // Wait for student home
      try {
        await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')), timeout: const Duration(seconds: 15));
      } catch (_) {
        // continue and try to navigate to home if needed
      }
      await tester.pumpAndSettle();

      // If the weekly mood bar isn't visible immediately, try navigating via drawer -> Home/Dashboard
      final weeklyFinder = find.byKey(const Key('weekly_mood_bar'));
      if (weeklyFinder.evaluate().isEmpty) {
        // open drawer and try to navigate to Home/Dashboard
        try {
          await tester.tap(find.byKey(const Key('drawer_button')));
          await tester.pumpAndSettle();
          if (find.text('Home').evaluate().isNotEmpty) {
            await tester.tap(find.text('Home'));
            await tester.pumpAndSettle();
          } else if (find.text('Dashboard').evaluate().isNotEmpty) {
            await tester.tap(find.text('Dashboard'));
            await tester.pumpAndSettle();
          } else {
            // try replacing route to student-home if button isn't present
            // this is a best-effort navigation attempt in test environment
            await tester.tap(find.byKey(const Key('drawer_button')));
            await tester.pumpAndSettle();
          }
        } catch (_) {}
      }

      // Final assertion - weekly mood bar should be present
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('weekly_mood_bar')), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}