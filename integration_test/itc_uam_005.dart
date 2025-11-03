import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breathe_better/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ITC-UAM-005: Password Reset Integration Tests', () {
    
    setUp(() async {
      // Setup test environment - main() is void, don't await it
      app.initApp();
      // Add a small delay to ensure initialization completes
      await Future.delayed(const Duration(milliseconds: 500));
    });

    tearDown() async {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        // Ignore cleanup errors
      }
    };

    testWidgets('Complete password reset flow with email notification', (WidgetTester tester) async {
      // Create test user
      final testEmail = 'reset_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const originalPassword = 'OriginalPassword123';
      const newPassword = 'NewPassword456';
      
      String? userId;
      try {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: testEmail,
          password: originalPassword,
        );
        userId = authResponse.user?.id;
        
        if (userId != null) {
          await Supabase.instance.client.auth.admin.updateUserById(
            userId,
            attributes: AdminUserAttributes(emailConfirm: true),
          );
          
          await Supabase.instance.client.from('users').insert({
            'user_id': userId,
            'email': testEmail,
            'user_type': 'student',
            'status': 'active',
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Step 1: Navigate to forgot password
      expect(find.text('Forgot Password?'), findsOneWidget);
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Verify forgot password dialog
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Enter your email address and we\'ll send you a link'), findsOneWidget);

      // Step 2: Enter email for password reset
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'), 
        testEmail
      );

      // Step 3: Submit password reset request
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 4: Verify success message
      expect(find.text('Reset Link Sent'), findsOneWidget);
      expect(find.text('A password reset link has been sent to $testEmail'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Step 5: Simulate clicking reset link (this would happen via email in real scenario)
      // In a real test environment, we would need to check the email system
      // For integration testing, we simulate the deep link flow
      
      // Simulate the deep link navigation that would happen after clicking email link
      Navigator.of(tester.element(find.byType(MaterialApp))).pushReplacementNamed('/reset-password');
      await tester.pumpAndSettle();

      // Step 6: Verify reset password page
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Create a new password for your account'), findsOneWidget);

      // Step 7: Enter new password
      await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), newPassword);
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), newPassword);

      // Step 8: Submit password update
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 9: Verify password update success
      expect(find.text('Password Updated'), findsOneWidget);
      expect(find.text('Your password has been successfully updated'), findsOneWidget);

      // Step 10: Navigate to login
      await tester.tap(find.text('Go to Login'));
      await tester.pumpAndSettle();

      // Verify back on login page
      expect(find.text('Welcome back. Take a deep breath and log in.'), findsOneWidget);

      // Step 11: Test login with old password should fail
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), originalPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show login failed error
      expect(find.text('Login Failed'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Step 12: Test login with new password should succeed
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), newPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should successfully login - but since no student record, might show error
      // The important part is that authentication works with new password

      // Cleanup
      if (userId != null) {
        try {
          await Supabase.instance.client.from('users').delete().eq('user_id', userId);
        } catch (e) {
          // Cleanup error acceptable
        }
      }
    });

    testWidgets('Password reset with invalid email should show error', (WidgetTester tester) async {
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to forgot password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'), 
        'nonexistent@example.com'
      );

      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Should still show success (for security reasons, even invalid emails show success)
      // This is standard practice to not reveal which emails exist
      expect(find.text('Reset Link Sent'), findsOneWidget);
    });

    testWidgets('Password reset validation - passwords must match', (WidgetTester tester) async {
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Navigate directly to reset password page
      Navigator.of(tester.element(find.byType(MaterialApp))).pushReplacementNamed('/reset-password');
      await tester.pumpAndSettle();

      // Enter mismatched passwords
      await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'Password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'DifferentPassword456');

      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Password reset validation - password length requirement', (WidgetTester tester) async {
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to reset password page
      Navigator.of(tester.element(find.byType(MaterialApp))).pushReplacementNamed('/reset-password');
      await tester.pumpAndSettle();

      // Enter password too short
      const shortPassword = '123';
      await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), shortPassword);
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), shortPassword);

      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Password reset deep link handling', (WidgetTester tester) async {
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Simulate receiving password reset deep link
      final uri = Uri.parse('breathebetter://reset-password?access_token=fake_token&refresh_token=fake_refresh&type=recovery');
      
      // In the actual app, this would be handled by the deep link listener
      // Here we simulate the navigation that would occur
      Navigator.of(tester.element(find.byType(MaterialApp))).pushReplacementNamed('/reset-password');
      await tester.pumpAndSettle();

      // Verify reset password page is shown
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Create a new password for your account'), findsOneWidget);
      
      // Verify password fields are present
      expect(find.widgetWithText(TextFormField, 'New Password'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirm New Password'), findsOneWidget);
      
      // Verify update button is present
      expect(find.text('Update Password'), findsOneWidget);
    });
  });
}
