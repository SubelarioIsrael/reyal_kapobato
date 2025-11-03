import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breathe_better/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ITC-UAM-001: User Registration Integration Tests', () {
    
    
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

  

      // Setup test environment - main() is void, don't await it
      await app.initApp();
      // Add a small delay to ensure initialization completes
      await Future.delayed(const Duration(milliseconds: 500));
    });

    tearDown(() async {
      // Cleanup: Sign out any authenticated user
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        // Ignore sign out errors in teardown
      }
    });

    testWidgets('Complete user registration flow with email verification workflow', (WidgetTester tester) async {
      // Test data
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123';
      const testStudentId = 'STU2024001';
      const testFirstName = 'John';
      const testLastName = 'Doe';

      // Load the app
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Step 1: Navigate to sign up from login page
      expect(find.byKey(const Key('go_to_signup')), findsOneWidget);
      await tester.tap(find.byKey(const Key('go_to_signup')));
      await tester.pumpAndSettle();

      // Verify we're on signup page
      expect(find.text('BreatheBetter'), findsOneWidget);
      expect(find.text('Create your account to get started'), findsOneWidget);

      // Step 2: Fill in Phase 1 - Login Information
      await tester.enterText(find.byKey(const Key('signup_email')), testEmail);
      await tester.enterText(find.byKey(const Key('signup_password')), testPassword);
      await tester.enterText(find.byKey(const Key('signup_confirm_password')), testPassword);

      // Proceed to Phase 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify Phase 2 is shown
      expect(find.text('Personal Information'), findsOneWidget);

      // Step 3: Fill in Phase 2 - Personal Information
      await tester.enterText(find.widgetWithText(TextFormField, 'Student ID Number'), testStudentId);
      await tester.enterText(find.widgetWithText(TextFormField, 'First Name'), testFirstName);
      await tester.enterText(find.widgetWithText(TextFormField, 'Last Name'), testLastName);

      // Select education level
      await tester.tap(find.text('Select Education Level'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('College').last);
      await tester.pumpAndSettle();

      // Select course
      await tester.tap(find.text('Select Course/Program'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bachelor of Science in Computer Science').first);
      await tester.pumpAndSettle();

      // Enter year level
      await tester.enterText(find.widgetWithText(TextFormField, 'Year Level (1-4)'), '2');

      // Step 4: Submit registration
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Step 5: Verify success dialog appears
      expect(find.text('Registration Successful!'), findsOneWidget);
      expect(find.text('Welcome to BreatheBetter!'), findsOneWidget);
      expect(find.text('A verification link has been sent to:'), findsOneWidget);
      expect(find.text(testEmail), findsOneWidget);
      
      // Verify user record created in Supabase
      final userResponse = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', testEmail)
          .maybeSingle();
      
      expect(userResponse, isNotNull);
      expect(userResponse!['user_type'], equals('student'));
      expect(userResponse['status'], equals('active'));

      // Verify student record created
      final studentResponse = await Supabase.instance.client
          .from('students')
          .select()
          .eq('student_code', testStudentId)
          .maybeSingle();
      
      expect(studentResponse, isNotNull);
      expect(studentResponse!['first_name'], equals(testFirstName));
      expect(studentResponse['last_name'], equals(testLastName));

      // Step 6: Go to login page
      await tester.tap(find.text('Go to Sign In'));
      await tester.pumpAndSettle();

      // Verify navigation to login page
      expect(find.text('Welcome back. Take a deep breath and log in.'), findsOneWidget);

      // Step 7: Verify email verification is required
      // Try to login before verification
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show email not verified dialog
      expect(find.text('Email Not Verified'), findsOneWidget);
      expect(find.text('Your email address has not been verified'), findsOneWidget);

      // Cleanup: Delete test user
      try {
        await Supabase.instance.client
            .from('students')
            .delete()
            .eq('student_code', testStudentId);
        await Supabase.instance.client
            .from('users')
            .delete()
            .eq('email', testEmail);
      } catch (e) {
        // Cleanup errors are acceptable in tests
      }
    });

    testWidgets('Registration validation - duplicate email should fail', (WidgetTester tester) async {
      final testEmail = 'duplicate_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      // First, create a user manually
      try {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: testEmail,
          password: 'TestPassword123',
        );
        
        if (authResponse.user != null) {
          await Supabase.instance.client.from('users').insert({
            'user_id': authResponse.user!.id,
            'email': testEmail,
            'user_type': 'student',
            'status': 'active',
          });
        }
      } catch (e) {
        // Continue with test
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to signup
      await tester.tap(find.byKey(const Key('go_to_signup')));
      await tester.pumpAndSettle();

      // Fill in duplicate email
      await tester.enterText(find.byKey(const Key('signup_email')), testEmail);
      await tester.enterText(find.byKey(const Key('signup_password')), 'TestPassword123');
      await tester.enterText(find.byKey(const Key('signup_confirm_password')), 'TestPassword123');

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Wait for any dialogs or error messages to appear
      await Future.delayed(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Check for various possible error indicators
      final accountExistsDialog = find.text('Account Already Exists');
      final emailExistsDialog = find.text('Email already exists');
      final errorDialog = find.text('Error');
      final duplicateEmailText = find.textContaining('already');
      
      // Print debug info to see what's actually on screen
      print('Available text widgets: ${find.text('').evaluate().map((e) => (e.widget as Text).data)}');
      
      // At least one error indicator should be present
      final hasError = accountExistsDialog.evaluate().isNotEmpty ||
                      emailExistsDialog.evaluate().isNotEmpty ||
                      errorDialog.evaluate().isNotEmpty ||
                      duplicateEmailText.evaluate().isNotEmpty;
      
      expect(hasError, isTrue, reason: 'Expected duplicate email error to be shown');
      
      // Cleanup
      try {
        await Supabase.instance.client
            .from('users')
            .delete()
            .eq('email', testEmail);
      } catch (e) {
        // Cleanup error acceptable
      }
    });
  });
}
