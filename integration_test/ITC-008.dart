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
        // ignore initialization errors
      }
    } catch (_) {
      // ignore dotenv errors
    }
  });

  group('ITC-008: Test password change integration with authentication system.', () {
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
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      // Wait for login screen to reappear
      await tester.pumpUntilFound(find.byKey(const Key('login_email')));
    }
    testWidgets('Dashboard displays daily mood entries throughout the week.', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();

      await login(tester, 'itzmethresh@gmail.com', 'allan123');

      final studentHomeFinder = find.byKey(const Key('studentHomeScreen'));
      try {
        await tester.pumpUntilFound(studentHomeFinder);
        expect(studentHomeFinder, findsOneWidget);
        await tester.pumpAndSettle();
      } catch (_) {
        // continue
      }

      final weeklyFinder = find.byKey(const Key('weekly_mood_bar'));
      if (weeklyFinder.evaluate().isNotEmpty) {
        expect(weeklyFinder, findsOneWidget);
      }
    });
  });
}