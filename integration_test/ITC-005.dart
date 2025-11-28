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

  group('ITC-005: Password reset (Forgot Password) flow', () {
    Future<void> openApp(WidgetTester tester) async {
      await app.testMain();
      await tester.pumpAndSettle();
    }

    testWidgets('Pressing Forgot Password sends reset link and shows confirmation dialog', (tester) async {
      await openApp(tester);

      // Open Forgot Password dialog from Login screen
      await tester.pumpUntilFound(find.text('Forgot Password?'));
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Find the dialog's email field and enter email
      final dialogEmailField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      await tester.pumpUntilFound(dialogEmailField);
      final testEmail = dotenv.env['ITC005_EMAIL'] ?? 'itc005@example.com';
      await tester.enterText(dialogEmailField.first, testEmail);
      await tester.pumpAndSettle();

      // Tap Send Link
      await tester.pumpUntilFound(find.text('Send Link'));
      await tester.tap(find.text('Send Link'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Expect success dialog with 'Reset Link Sent' and the email is mentioned in the message
      await tester.pumpUntilFound(find.text('Reset Link Sent'), timeout: const Duration(seconds: 10));
      expect(find.textContaining(testEmail), findsOneWidget);
    });
  });
}