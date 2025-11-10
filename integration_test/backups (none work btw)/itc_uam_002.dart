import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breathe_better/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ITC-UAM-002: Login Dashboard Redirection Integration Tests', () {
    
    setUp(() async {
      // Setup test environment - main() is void, don't await it
      await app.initApp();
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

    testWidgets('Student login redirects to student dashboard', (WidgetTester tester) async {
      // Create test student user
      final testEmail = 'itzmethresh@gmail.com';
      const testPassword = 'allanjayz';
      
      String? userId;
      try {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: testEmail,
          password: testPassword,
        );
        userId = authResponse.user?.id;
        
        if (userId != null) {
          // Mark email as confirmed for test
          await Supabase.instance.client.auth.admin.updateUserById(
            userId,
            attributes: AdminUserAttributes(
              emailConfirm: true,
            ),
          );
          
          // Create user record
          await Supabase.instance.client.from('users').insert({
            'user_id': userId,
            'email': testEmail,
            'user_type': 'student',
            'status': 'active',
          });
          
          // Create student record
          await Supabase.instance.client.from('students').insert({
            'user_id': userId,
            'student_code': 'TEST001',
            'first_name': 'Test',
            'last_name': 'Student',
            'education_level': 'college',
            'year_level': 1,
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Verify we're on login page
      expect(find.byKey(const Key('login_email')), findsOneWidget);
      expect(find.byKey(const Key('login_password')), findsOneWidget);

      // Enter credentials
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);

      // Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify redirection to student dashboard
      expect(find.byKey(const Key('studentHomeScreen')), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Hi, Test Student!'), findsOneWidget);

      // Cleanup
      if (userId != null) {
        try {
          await Supabase.instance.client.from('students').delete().eq('user_id', userId);
          await Supabase.instance.client.from('users').delete().eq('user_id', userId);
        } catch (e) {
          // Cleanup error acceptable
        }
      }
    });

    testWidgets('Counselor login redirects to counselor dashboard', (WidgetTester tester) async {
      final testEmail = 'counselor_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123';
      
      String? userId;
      try {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: testEmail,
          password: testPassword,
        );
        userId = authResponse.user?.id;
        
        if (userId != null) {
          // Mark email as confirmed
          await Supabase.instance.client.auth.admin.updateUserById(
            userId,
            attributes: AdminUserAttributes(emailConfirm: true),
          );
          
          // Create user record
          await Supabase.instance.client.from('users').insert({
            'user_id': userId,
            'email': testEmail,
            'user_type': 'counselor',
            'status': 'active',
          });
          
          // Create complete counselor record
          await Supabase.instance.client.from('counselors').insert({
            'user_id': userId,
            'first_name': 'Dr. Test',
            'last_name': 'Counselor',
            'email': testEmail,
            'department_assigned': 'Psychology',
            'bio': 'Test counselor for integration testing',
            'availability_status': 'available',
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Login as counselor
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify redirection to counselor dashboard
      expect(find.byKey(const Key('counselorHomeScreen')), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Dr. Dr. Test Counselor'), findsOneWidget);

      // Cleanup
      if (userId != null) {
        try {
          await Supabase.instance.client.from('counselors').delete().eq('user_id', userId);
          await Supabase.instance.client.from('users').delete().eq('user_id', userId);
        } catch (e) {
          // Cleanup error acceptable
        }
      }
    });

    testWidgets('Admin login redirects to admin dashboard', (WidgetTester tester) async {
      final testEmail = 'admin_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123';
      
      String? userId;
      try {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: testEmail,
          password: testPassword,
        );
        userId = authResponse.user?.id;
        
        if (userId != null) {
          // Mark email as confirmed
          await Supabase.instance.client.auth.admin.updateUserById(
            userId,
            attributes: AdminUserAttributes(emailConfirm: true),
          );
          
          // Create admin user record
          await Supabase.instance.client.from('users').insert({
            'user_id': userId,
            'email': testEmail,
            'user_type': 'admin',
            'status': 'active',
            'username': 'Test Admin',
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Login as admin
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify redirection to admin dashboard
      expect(find.byKey(const Key('adminHomeScreen')), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);

      // Cleanup
      if (userId != null) {
        try {
          await Supabase.instance.client.from('users').delete().eq('user_id', userId);
        } catch (e) {
          // Cleanup error acceptable
        }
      }
    });

    testWidgets('Invalid credentials should show error', (WidgetTester tester) async {
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Enter invalid credentials
      await tester.enterText(find.byKey(const Key('login_email')), 'invalid@example.com');
      await tester.enterText(find.byKey(const Key('login_password')), 'wrongpassword');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show error dialog
      expect(find.text('Login Failed'), findsOneWidget);
      expect(find.text('Invalid email or password'), findsOneWidget);
    });
  });
}
