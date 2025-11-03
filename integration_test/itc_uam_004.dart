import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breathe_better/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ITC-UAM-004: Counselor Account Setup Integration Tests', () {
    
    String? adminUserId;
    
    setUp(() async {
      // Setup test environment - main() is void, don't await it
      app.main();
      // Add a small delay to ensure initialization completes
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Create admin user for testing
      try {
        final testAdminEmail = 'admin@email.com';
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: testAdminEmail,
          password: 'adminadmin',
        );
        adminUserId = authResponse.user?.id;
        
        if (adminUserId != null) {
          await Supabase.instance.client.auth.admin.updateUserById(
            adminUserId!,
            attributes: AdminUserAttributes(emailConfirm: true),
          );
          
          await Supabase.instance.client.from('users').insert({
            'user_id': adminUserId,
            'email': testAdminEmail,
            'user_type': 'admin',
            'status': 'active',
            'username': 'Test Admin',
          });
        }
      } catch (e) {
        print('Admin setup error: $e');
      }
    });

    tearDown(() async {
      try {
        await Supabase.instance.client.auth.signOut();
        if (adminUserId != null) {
          await Supabase.instance.client.from('users').delete().eq('user_id', adminUserId!);
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    testWidgets('Admin creates counselor account with email verification workflow', (WidgetTester tester) async {
      if (adminUserId == null) {
        fail('Admin user not created');
      }

      // Test data for counselor
      final counselorEmail = 'counselor_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const counselorPassword = 'CounselorPass123';
      const counselorName = 'Dr. Jane Smith';

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Step 1: Login as admin
      final adminEmail = await Supabase.instance.client
          .from('users')
          .select('email')
          .eq('user_id', adminUserId!)
          .single()
          .then((data) => data['email'] as String);

      await tester.enterText(find.byKey(const Key('login_email')), adminEmail);
      await tester.enterText(find.byKey(const Key('login_password')), 'AdminPassword123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify admin dashboard
      expect(find.byKey(const Key('adminHomeScreen')), findsOneWidget);

      // Step 2: Navigate to Account Management
      await tester.tap(find.text('User Management'));
      await tester.pumpAndSettle();

      // Should be on admin accounts page
      expect(find.text('Manage Accounts'), findsOneWidget);

      // Step 3: Create new counselor account
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify add account dialog
      expect(find.text('Add New Account'), findsOneWidget);

      // Fill in counselor details
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name *'), counselorName);
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address *'), counselorEmail);
      
      // Select counselor role
      await tester.tap(find.text('Counselor'));
      await tester.pumpAndSettle();

      // Enter passwords
      await tester.enterText(find.widgetWithText(TextFormField, 'Password *'), counselorPassword);
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password *'), counselorPassword);

      // Submit account creation
      await tester.tap(find.text('Add Account'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Step 4: Verify account creation success
      expect(find.text('Account created successfully'), findsOneWidget);

      // Step 5: Verify counselor records in database
      final userRecord = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', counselorEmail)
          .maybeSingle();
      
      expect(userRecord, isNotNull);
      expect(userRecord!['user_type'], equals('counselor'));
      expect(userRecord['status'], equals('active'));

      final counselorRecord = await Supabase.instance.client
          .from('counselors')
          .select()
          .eq('email', counselorEmail)
          .maybeSingle();
      
      expect(counselorRecord, isNotNull);
      expect(counselorRecord!['first_name'], equals('Dr. Jane'));
      expect(counselorRecord['last_name'], equals('Smith'));

      // Step 6: Verify email verification requirement
      // Logout admin and try to login as counselor
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Try to login as counselor before email verification
      await tester.enterText(find.byKey(const Key('login_email')), counselorEmail);
      await tester.enterText(find.byKey(const Key('login_password')), counselorPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show email not verified dialog
      expect(find.text('Email Not Verified'), findsOneWidget);

      // Step 7: Simulate email verification (in real test, counselor would click email link)
      final counselorUserId = userRecord['user_id'] as String;
      await Supabase.instance.client.auth.admin.updateUserById(
        counselorUserId,
        attributes: AdminUserAttributes(emailConfirm: true),
      );

      // Now login should work
      await tester.tap(find.text('OK')); // Dismiss dialog
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should redirect to counselor profile setup (since profile is incomplete)
      expect(find.text('Welcome, Counselor!'), findsOneWidget);
      expect(find.text('Set Up Profile'), findsOneWidget);

      // Cleanup
      try {
        await Supabase.instance.client.from('counselors').delete().eq('user_id', counselorUserId);
        await Supabase.instance.client.from('users').delete().eq('user_id', counselorUserId);
      } catch (e) {
        // Cleanup error acceptable
      }
    });

    testWidgets('Counselor account activation flow after email verification', (WidgetTester tester) async {
      // Create a counselor account that needs profile setup
      final counselorEmail = 'setup_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const counselorPassword = 'TestPassword123';
      
      String? counselorUserId;
      try {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: counselorEmail,
          password: counselorPassword,
        );
        counselorUserId = authResponse.user?.id;
        
        if (counselorUserId != null) {
          await Supabase.instance.client.auth.admin.updateUserById(
            counselorUserId,
            attributes: AdminUserAttributes(emailConfirm: true),
          );
          
          await Supabase.instance.client.from('users').insert({
            'user_id': counselorUserId,
            'email': counselorEmail,
            'user_type': 'counselor',
            'status': 'active',
          });
          
          // Create incomplete counselor profile (missing required fields)
          await Supabase.instance.client.from('counselors').insert({
            'user_id': counselorUserId,
            'email': counselorEmail,
            'first_name': '', // Empty - needs setup
            'last_name': '',  // Empty - needs setup
            'department_assigned': '', // Empty - needs setup
            'bio': '', // Empty - needs setup
            'availability_status': 'available',
          });
        }
      } catch (e) {
        print('Counselor setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Login as counselor
      await tester.enterText(find.byKey(const Key('login_email')), counselorEmail);
      await tester.enterText(find.byKey(const Key('login_password')), counselorPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show welcome dialog for profile setup
      expect(find.text('Welcome, Counselor!'), findsOneWidget);
      expect(find.text('Let\'s set up your professional profile'), findsOneWidget);

      // Start profile setup
      await tester.tap(find.text('Set Up Profile'));
      await tester.pumpAndSettle();

      // Should be on counselor profile setup page
      expect(find.text('Complete Your Profile'), findsOneWidget);

      // Fill in profile information
      await tester.enterText(find.widgetWithText(TextFormField, 'First Name'), 'Dr. Sarah');
      await tester.enterText(find.widgetWithText(TextFormField, 'Last Name'), 'Johnson');
      
      // Select department
      await tester.tap(find.text('Select Department'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Psychology').first);
      await tester.pumpAndSettle();

      // Enter bio
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Professional Bio'),
        'Experienced counselor specializing in student mental health and wellness.'
      );

      // Submit profile
      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should redirect to counselor dashboard
      expect(find.byKey(const Key('counselorHomeScreen')), findsOneWidget);
      expect(find.text('Dr. Dr. Sarah Johnson'), findsOneWidget);

      // Verify profile completion in database
      final updatedProfile = await Supabase.instance.client
          .from('counselors')
          .select()
          .eq('user_id', counselorUserId!)
          .single();
      
      expect(updatedProfile['first_name'], equals('Dr. Sarah'));
      expect(updatedProfile['last_name'], equals('Johnson'));
      expect(updatedProfile['department_assigned'], equals('Psychology'));

      // Cleanup
      if (counselorUserId != null) {
        try {
          await Supabase.instance.client.from('counselors').delete().eq('user_id', counselorUserId);
          await Supabase.instance.client.from('users').delete().eq('user_id', counselorUserId);
        } catch (e) {
          // Cleanup error acceptable
        }
      }
    });
  });
}
