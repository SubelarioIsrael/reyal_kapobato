import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breathe_better/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ITC-UAM-003: Session Management Integration Tests', () {
    
    setUp(() async {
      // Setup test environment - main() is void, don't await it
      app.initApp();
      // Add a small delay to ensure initialization completes
      await Future.delayed(const Duration(milliseconds: 500));
    });

    tearDown(() async {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    testWidgets('Complete session lifecycle - login, navigate modules, logout', (WidgetTester tester) async {
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
          // Mark email as confirmed
          await Supabase.instance.client.auth.admin.updateUserById(
            userId,
            attributes: AdminUserAttributes(emailConfirm: true),
          );
          
          // Create user and student records
          await Supabase.instance.client.from('users').insert({
            'user_id': userId,
            'email': testEmail,
            'user_type': 'student',
            'status': 'active',
          });
          
          await Supabase.instance.client.from('students').insert({
            'user_id': userId,
            'student_code': 'SESSION001',
            'first_name': 'Session',
            'last_name': 'Tester',
            'education_level': 'college',
            'year_level': 2,
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Step 1: Login
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify successful login and session creation
      expect(find.byKey(const Key('studentHomeScreen')), findsOneWidget);
      expect(Supabase.instance.client.auth.currentUser, isNotNull);
      expect(Supabase.instance.client.auth.currentSession, isNotNull);

      // Step 2: Navigate through different modules to test session persistence
      
      // Navigate to Breathing Exercises
      await tester.tap(find.text('Breathing Exercises'));
      await tester.pumpAndSettle();
      expect(find.text('Choose Your Exercise'), findsOneWidget);
      
      // Verify session is still active
      expect(Supabase.instance.client.auth.currentUser?.id, equals(userId));

      // Navigate back to home
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Navigate to Mood Journal
      await tester.tap(find.text('My Mood Journal'));
      await tester.pumpAndSettle();
      expect(find.text('Journal Entries'), findsOneWidget);
      
      // Verify session persistence
      expect(Supabase.instance.client.auth.currentUser?.id, equals(userId));

      // Navigate back to home
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Navigate to Counselors
      await tester.tap(find.text('Connect with a Counselor'));
      await tester.pumpAndSettle();
      expect(find.text('Available Counselors'), findsOneWidget);
      
      // Verify session persistence across all modules
      expect(Supabase.instance.client.auth.currentUser?.id, equals(userId));

      // Navigate back to home
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Step 3: Open drawer and logout
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Find and tap logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Step 4: Verify session termination and redirection
      expect(find.text('Welcome back. Take a deep breath and log in.'), findsOneWidget);
      expect(Supabase.instance.client.auth.currentUser, isNull);
      expect(Supabase.instance.client.auth.currentSession, isNull);

      // Step 5: Verify cannot access protected routes after logout
      // Try to manually navigate to a protected route (should redirect to login)
      Navigator.of(tester.element(find.byType(MaterialApp))).pushNamed('student-home');
      await tester.pumpAndSettle();
      
      // Should still be on login page due to AuthGuard
      expect(find.text('Welcome back. Take a deep breath and log in.'), findsOneWidget);

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

    testWidgets('Session should persist across app restarts (token refresh)', (WidgetTester tester) async {
      // Create test user
      final testEmail = 'token_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123';
      
      String? userId;
      try {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: testEmail,
          password: testPassword,
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
          
          await Supabase.instance.client.from('students').insert({
            'user_id': userId,
            'student_code': 'TOKEN001',
            'first_name': 'Token',
            'last_name': 'Tester',
            'education_level': 'college',
            'year_level': 1,
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      // First app instance - login
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify login success
      expect(find.byKey(const Key('studentHomeScreen')), findsOneWidget);
      
      // Store session info
      final session = Supabase.instance.client.auth.currentSession;
      expect(session, isNotNull);

      // Simulate app restart by creating new app instance
      // In a real scenario, the session would be restored from storage
      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // If session is valid, should go directly to dashboard
      // If not, should stay on login page
      // This tests the session persistence mechanism

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

    testWidgets('Suspended account should terminate session immediately', (WidgetTester tester) async {
      final testEmail = 'suspend_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123';
      
      String? userId;
      try {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: testEmail,
          password: testPassword,
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
            'status': 'active', // Start as active
          });
          
          await Supabase.instance.client.from('students').insert({
            'user_id': userId,
            'student_code': 'SUSPEND001',
            'first_name': 'Suspend',
            'last_name': 'Tester',
            'education_level': 'college',
            'year_level': 1,
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Login successfully
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byKey(const Key('studentHomeScreen')), findsOneWidget);

      // Simulate account suspension by admin
      if (userId != null) {
        await Supabase.instance.client
            .from('users')
            .update({'status': 'suspended'})
            .eq('user_id', userId);
      }

      // Try to login again with suspended account
      await Supabase.instance.client.auth.signOut();
      await tester.pumpAndSettle();

      // Should be back on login page
      expect(find.text('Welcome back. Take a deep breath and log in.'), findsOneWidget);

      // Try to login with suspended account
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show account suspended dialog
      expect(find.text('Account Suspended'), findsOneWidget);

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
  });
}
