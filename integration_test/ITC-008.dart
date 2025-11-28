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
      try {
        await tester.tap(find.byKey(const Key('drawer_button')));
        await tester.pumpAndSettle();
        if (find.byKey(const Key('logout_button')).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(const Key('logout_button')));
        } else if (find.text('Logout').evaluate().isNotEmpty) {
          await tester.tap(find.text('Logout'));
        }
        await tester.pumpAndSettle();
        await tester.pumpUntilFound(find.byKey(const Key('login_email')));
      } catch (_) {}
    }

    testWidgets('Change password updates authentication and allows login with new credentials.', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();

      final email = dotenv.env['ITC008_EMAIL'] ?? 'itzmethresh@gmail.com';
      final oldPass = dotenv.env['ITC008_OLD_PASSWORD'] ?? 'allan123';
      final newPass = dotenv.env['ITC008_NEW_PASSWORD'] ?? 'NewPass123!';

      // Log in with current credentials
      await login(tester, email, oldPass);

      // Ensure at student home
      try {
        await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')), timeout: const Duration(seconds: 15));
      } catch (_) {}
      await tester.pumpAndSettle();

      // Open drawer -> Settings
      await tester.pumpUntilFound(find.byKey(const Key('drawer_button')));
      await tester.tap(find.byKey(const Key('drawer_button')));
      await tester.pumpAndSettle();

      await tester.pumpUntilFound(find.text('Settings'));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Tap Change Password item on Settings page
      await tester.pumpUntilFound(find.text('Change Password'));
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      // Fill current and new password fields
      await tester.pumpUntilFound(find.widgetWithText(TextFormField, 'Current Password'));
      await tester.enterText(find.widgetWithText(TextFormField, 'Current Password'), oldPass);
      await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), newPass);
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), newPass);
      await tester.pumpAndSettle();

      // Submit Update Password
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Expect success dialog and press Done
      await tester.pumpUntilFound(find.text('Password Updated'), timeout: const Duration(seconds: 10));
      await tester.pumpAndSettle();
      if (find.text('Done').evaluate().isNotEmpty) {
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
      } else if (find.text('OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }

      // Return to home (pop settings if needed)
      try {
        if (find.byIcon(Icons.arrow_back_ios).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.arrow_back_ios));
          await tester.pumpAndSettle();
        }
      } catch (_) {}

      // Open drawer and logout to reach login screen
      try {
        await tester.pumpUntilFound(find.byKey(const Key('drawer_button')));
        await tester.tap(find.byKey(const Key('drawer_button')));
        await tester.pumpAndSettle();
        if (find.byKey(const Key('logout_button')).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(const Key('logout_button')));
        } else if (find.text('Logout').evaluate().isNotEmpty) {
          await tester.tap(find.text('Logout'));
        }
        await tester.pumpAndSettle();
        await tester.pumpUntilFound(find.byKey(const Key('login_email')));
      } catch (_) {}

      // Try login with new password (should succeed)
      await login(tester, email, newPass);
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')), timeout: const Duration(seconds: 15));
      expect(find.byKey(const Key('studentHomeScreen')), findsOneWidget);

      // Cleanup: try to reset password back to oldPass (best-effort)
      try {
        // Navigate to Settings -> Change Password and set back (silent best-effort)
        await tester.tap(find.byKey(const Key('drawer_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Change Password'));
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextFormField, 'Current Password'), newPass);
        await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), oldPass);
        await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), oldPass);
        await tester.tap(find.text('Update Password'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } catch (_) {}
    }, timeout: const Timeout(Duration(seconds: 120)));
  });
}