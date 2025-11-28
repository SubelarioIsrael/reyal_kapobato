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
    try {
      await dotenv.load(fileName: 'important_stuff.env');
      // Supabase initialize wrapped so failures won't break tests
      try {
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        );
      } catch (_) {
        // ignore initialization errors in CI/local where network isn't available
      }
    } catch (_) {
      // ignore dotenv load errors
    }
  });

  testWidgets('ITC-001: Registration triggers verification email dialog', (tester) async {
    await app.testMain();
    await tester.pumpAndSettle();

    // Prepare unique email for the test
    final ts = DateTime.now().millisecondsSinceEpoch;
    final testEmail = dotenv.env['ITC001_EMAIL'] ?? 'itc001+$ts@example.com';
    final password = dotenv.env['ITC001_PASSWORD'] ?? 'TestPass123!';

    // Navigate to signup via UI (follow main -> login flow)
    await tester.pumpUntilFound(find.byKey(const Key('go_to_signup')));
    await tester.tap(find.byKey(const Key('go_to_signup')));
    await tester.pumpAndSettle();

    // Phase 1: fill email/password/confirm
    await tester.pumpUntilFound(find.byKey(const Key('signup_email')));
    await tester.enterText(find.byKey(const Key('signup_email')), testEmail);
    await tester.enterText(find.byKey(const Key('signup_password')), password);
    await tester.enterText(find.byKey(const Key('signup_confirm_password')), password);
    await tester.pumpAndSettle();

    // Tap Next (phase 1 -> phase 2)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Phase 2: there are multiple TextFormField in order:
    // Student ID, First Name, Last Name, (maybe other fields), Year Level
    final tfFinder = find.byType(TextFormField);
    await tester.pumpUntilFound(tfFinder);

    // Fill Student ID, First Name, Last Name (use indices matching the form)
    await tester.enterText(tfFinder.at(0), 'ITC001$ts'); // Student ID
    await tester.enterText(tfFinder.at(1), 'ITCFirst$ts'); // First Name
    await tester.enterText(tfFinder.at(2), 'ITCLast$ts'); // Last Name
    await tester.pumpAndSettle();

    // Select Education Level (dropdown uses label 'Select Education Level' / items include 'Basic Education')
    final dropdownFinder = find.byType(DropdownButtonFormField<String>);
    await tester.pumpUntilFound(dropdownFinder);
    await tester.tap(dropdownFinder.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basic Education').last);
    await tester.pumpAndSettle();

    // After selecting education level, fill year/grade level (last TextFormField in the form)
    await tester.pumpAndSettle();
    final allTextFields = find.byType(TextFormField);
    await tester.pumpUntilFound(allTextFields);
    // Attempt to find a numeric year field at the end; fallback to index 3
    final yearIndex = allTextFields.evaluate().length > 3 ? 3 : allTextFields.evaluate().length - 1;
    await tester.enterText(allTextFields.at(yearIndex), '1');
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
