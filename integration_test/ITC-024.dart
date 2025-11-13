import 'dart:async';
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

Future<void> login(WidgetTester tester, String email, String password) async {
  await tester.pumpAndSettle();
  await tester.pumpUntilFound(find.byKey(const Key('login_email')));
  await tester.enterText(find.byKey(const Key('login_email')), email);
  await tester.enterText(find.byKey(const Key('login_password')), password);
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: 'important_stuff.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  });

  testWidgets('ITC-024: Test integration between emergency contact management and quick call function.', (tester) async {
    // Launch the app
    await app.testMain();
    await tester.pumpAndSettle();

    // Read student credentials from env for test flexibility
    // Prefer environment variables, otherwise fall back to the student credentials
    // used in ITC-002 (for local/integration test convenience).
    final studentEmail = dotenv.env['STUDENT_EMAIL'] ?? 'itzmethresh@gmail.com';
    final studentPassword = dotenv.env['STUDENT_PASSWORD'] ?? 'allan123';

    // Log in as student
    await login(tester, studentEmail, studentPassword);

    // Wait until the student home screen is visible
    await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')));

    // Navigate to student contacts route
    Navigator.of(tester.element(find.byKey(const Key('studentHomeScreen')))).pushNamed('student-contacts');
    await tester.pumpAndSettle();

    // Wait for the Support Contacts page title to appear
    await tester.pumpUntilFound(find.text('Support Contacts'));

    // Find the first hotline call icon (blue call icon) and tap it.
    // We avoid relying on keys and target the Icon widget used in hotline call buttons.
    final hotlineIconFinder = find.byWidgetPredicate((w) {
      if (w is Icon) {
        return w.icon == Icons.call_rounded && w.color == const Color(0xFF7C83FD);
      }
      return false;
    });
    await tester.pumpUntilFound(hotlineIconFinder, timeout: const Duration(seconds: 15));
    await tester.tap(hotlineIconFinder.first);
    await tester.pumpAndSettle();

    // Verify the confirmation dialog shows up (title 'Call Hotline')
    await tester.pumpUntilFound(find.text('Call Hotline'), timeout: const Duration(seconds: 10));

    // Short delay so test ends after dialog appearance (per test requirement)
    await tester.pump(const Duration(milliseconds: 500));
  }, timeout: const Timeout(Duration(seconds: 60)));
}
