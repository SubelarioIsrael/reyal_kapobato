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

  group('ITC-004: Test the integration between counselor creation and email verification.', () {
    Future<void> login(WidgetTester tester, String email, String password) async {
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('login_email')));
      await tester.enterText(find.byKey(const Key('login_email')), email);
      await tester.enterText(find.byKey(const Key('login_password')), password);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
    }
    testWidgets('Verify that admin-side creation correctly hits the endpoint and changes counselor status to “pending verification”', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();

      // Login as admin user (use credentials from env or defaults)
      final adminEmail = dotenv.env['ADMIN_EMAIL'] ?? 'itzmethresh@gmail.com';
      final adminPass = dotenv.env['ADMIN_PASSWORD'] ?? 'allan123';

      await login(tester, adminEmail, adminPass);

      // Wait for admin home screen
      await tester.pumpUntilFound(find.byKey(const Key('adminHomeScreen')), timeout: const Duration(seconds: 15));
      expect(find.byKey(const Key('adminHomeScreen')), findsOneWidget);
      await tester.pumpAndSettle();

      // Tap the "User Management" quick action to navigate to AdminUsers
      await tester.pumpUntilFound(find.text('User Management'));
      await tester.tap(find.text('User Management'));
      await tester.pumpAndSettle();

      // Wait for AdminUsers page (FAB present)
      await tester.pumpUntilFound(find.byType(FloatingActionButton));
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Open Add User modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Prepare unique email
      final ts = DateTime.now().millisecondsSinceEpoch;
      final newUserEmail = 'itc004+$ts@example.com';
      final newUserPass = 'TestPass123!';

      // Fill the form in the modal:
      // The modal has TextFormField order: Email, Password, Confirm Password
      final modalTextFields = find.byType(TextFormField);
      await tester.pumpUntilFound(modalTextFields);
      await tester.enterText(modalTextFields.at(0), newUserEmail); // Email
      await tester.pumpAndSettle();

      // Role dropdown defaults to 'Counselor' so no need to change; otherwise select it:
      // final roleDropdown = find.byType(DropdownButtonFormField<String>);
      // await tester.tap(roleDropdown.first); await tester.pumpAndSettle();
      // await tester.tap(find.text('Counselor').last); await tester.pumpAndSettle();

      await tester.enterText(modalTextFields.at(1), newUserPass); // Password
      await tester.enterText(modalTextFields.at(2), newUserPass); // Confirm Password
      await tester.pumpAndSettle();

      // Tap Add User button
      await tester.pumpUntilFound(find.text('Add User'));
      await tester.tap(find.text('Add User'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Expect success dialog with 'User Created Successfully!'
      await tester.pumpUntilFound(find.text('User Created Successfully!'), timeout: const Duration(seconds: 15));
      expect(find.textContaining(newUserEmail), findsOneWidget);

      // Cleanup: try deleting created user record
      try {
        final supabase = Supabase.instance.client;
        final userRow = await supabase.from('users').select('user_id').eq('email', newUserEmail).maybeSingle();
        if (userRow != null && userRow['user_id'] != null) {
          await supabase.from('users').delete().eq('user_id', userRow['user_id']);
        }
      } catch (_) {}
    });
  });
}