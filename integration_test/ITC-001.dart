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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: 'important_stuff.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  });

  testWidgets('ITC-001: Registration triggers verification email dialog', (tester) async {
    await app.testMain();
    await tester.pumpAndSettle();

    // Prepare unique email for the test
    final ts = DateTime.now().millisecondsSinceEpoch;
    final testEmail = dotenv.env['ITC001_EMAIL'] ?? 'itc001+$ts@example.com';
    final password = dotenv.env['ITC001_PASSWORD'] ?? 'TestPass123!';

    // Navigate to signup
    Navigator.of(tester.element(find.byType(MaterialApp))).pushNamed('/signup');
    await tester.pumpAndSettle();

    // Fill Phase 1
    await tester.pumpUntilFound(find.byKey(const Key('signup_email')));
    await tester.enterText(find.byKey(const Key('signup_email')), testEmail);
    await tester.enterText(find.byKey(const Key('signup_password')), password);
    await tester.enterText(find.byKey(const Key('signup_confirm_password')), password);
    await tester.pumpAndSettle();

    // Tap Next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Fill Phase 2 fields by hint text
    // Locate the phase-2 text fields by position (Student ID, First Name, Last Name, Year Level).
    final tfFinder = find.byType(TextFormField);
    await tester.pumpUntilFound(tfFinder);
    await tester.enterText(tfFinder.at(0), 'ITC001$ts'); // Student ID
    await tester.enterText(tfFinder.at(1), 'ITCFirst$ts'); // First Name
    await tester.enterText(tfFinder.at(2), 'ITCLast$ts'); // Last Name

    // Select Basic Education (dropdown)
    final dropdownFinder = find.byType(DropdownButtonFormField<String>).first;
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basic Education (Grades 1-6)').last);
    await tester.pumpAndSettle();

    // Enter Year Level (Grade 1) - the year field becomes the next TextFormField in the form
    await tester.pumpAndSettle();
    final tfAfterDropdown = find.byType(TextFormField);
    await tester.pumpUntilFound(tfAfterDropdown);
    // Year Level should be the 4th TextFormField in this phase (index 3)
    await tester.enterText(tfAfterDropdown.at(3), '1');
    await tester.pumpAndSettle();

    // Submit Create
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Expect success dialog with 'Registration Successful!'
    await tester.pumpUntilFound(find.text('Registration Successful!'), timeout: const Duration(seconds: 15));
    expect(find.textContaining(testEmail), findsOneWidget);

    // Cleanup created user record (try best-effort)
    try {
      final supabase = Supabase.instance.client;
      final userRow = await supabase.from('users').select('user_id').eq('email', testEmail).maybeSingle();
      if (userRow != null && userRow['user_id'] != null) {
        await supabase.from('users').delete().eq('user_id', userRow['user_id']);
      }
    } catch (_) {}
  }, timeout: const Timeout(Duration(seconds: 90)));
}
