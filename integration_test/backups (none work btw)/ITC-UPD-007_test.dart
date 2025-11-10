import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breathe_better/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ITC-UPD-007: User Dashboard Integration Tests', () {
    
    setUp(() async {
      // Setup test environment - main() is void, don't await it
      await app.initApp();
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

    testWidgets('should load dashboard with assessment data', (WidgetTester tester) async {
      // Create test student user with assessment data
      final testEmail = 'dashboard_student_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123';
      
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
            'student_code': 'DASH001',
            'first_name': 'Test',
            'last_name': 'Student',
            'education_level': 'college',
            'year_level': 1,
          });

          // Create assessment records for the student
          await Supabase.instance.client.from('assessments').insert({
            'student_id': userId,
            'challenge_score': 85,
            'commitment_score': 78,
            'control_score': 90,
            'overall_score': 84,
            'assessment_date': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify we're on student dashboard
      expect(find.byKey(const Key('studentHomeScreen')), findsOneWidget);
      
      // Wait for data to load
      await tester.pump(const Duration(seconds: 3));
      
      // Verify dashboard elements are displayed
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      
      // Verify assessment-related widgets are present
      expect(find.byType(Card), findsWidgets);

      // Cleanup
      if (userId != null) {
        try {
          await Supabase.instance.client.from('assessments').delete().eq('student_id', userId);
          await Supabase.instance.client.from('students').delete().eq('user_id', userId);
          await Supabase.instance.client.from('users').delete().eq('user_id', userId);
        } catch (e) {
          // Cleanup error acceptable
        }
      }
    });

    testWidgets('should display latest assessment results', (WidgetTester tester) async {
      final testEmail = 'assessment_display_${DateTime.now().millisecondsSinceEpoch}@example.com';
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
            'student_code': 'ASSESS001',
            'first_name': 'Assessment',
            'last_name': 'Test',
            'education_level': 'college',
            'year_level': 2,
          });

          // Create recent assessment with high scores
          await Supabase.instance.client.from('assessments').insert({
            'student_id': userId,
            'challenge_score': 92,
            'commitment_score': 88,
            'control_score': 95,
            'overall_score': 91,
            'assessment_date': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Login and navigate to dashboard
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 3));

      // Look for assessment results section
      expect(find.textContaining('Recent Assessment'), findsAny);
      
      // Verify metrics are displayed
      expect(find.byType(LinearProgressIndicator), findsAny);

      // Cleanup
      if (userId != null) {
        try {
          await Supabase.instance.client.from('assessments').delete().eq('student_id', userId);
          await Supabase.instance.client.from('students').delete().eq('user_id', userId);
          await Supabase.instance.client.from('users').delete().eq('user_id', userId);
        } catch (e) {
          // Cleanup error acceptable
        }
      }
    });

    testWidgets('should navigate to questionnaire from dashboard', (WidgetTester tester) async {
      final testEmail = 'nav_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
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
            'student_code': 'NAV001',
            'first_name': 'Navigation',
            'last_name': 'Test',
            'education_level': 'college',
            'year_level': 1,
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Login and navigate to dashboard
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 2));

      // Find and tap questionnaire button/card
      final questionnaireButton = find.textContaining('Questionnaire');
      if (questionnaireButton.evaluate().isNotEmpty) {
        await tester.tap(questionnaireButton.first);
        await tester.pumpAndSettle();
        
        // Verify navigation to questionnaire
        expect(find.text('Mental Toughness Questionnaire'), findsOneWidget);
      }

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

    testWidgets('should handle no assessment data gracefully', (WidgetTester tester) async {
      final testEmail = 'no_assessment_${DateTime.now().millisecondsSinceEpoch}@example.com';
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
          
          // Create student without assessment records
          await Supabase.instance.client.from('students').insert({
            'user_id': userId,
            'student_code': 'EMPTY001',
            'first_name': 'Empty',
            'last_name': 'Test',
            'education_level': 'college',
            'year_level': 1,
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 2));

      // Verify empty state or prompt to take assessment
      expect(find.textContaining('No assessment'), findsAny);

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

    testWidgets('should refresh dashboard data on pull-to-refresh', (WidgetTester tester) async {
      final testEmail = 'refresh_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
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
            'student_code': 'REF001',
            'first_name': 'Refresh',
            'last_name': 'Test',
            'education_level': 'college',
            'year_level': 1,
          });
        }
      } catch (e) {
        print('Setup error: $e');
      }

      await tester.pumpWidget(const app.MyApp());
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 2));

      // Perform pull-to-refresh gesture
      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 300), 1000);
      await tester.pump();
      
      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      await tester.pumpAndSettle();
      
      // Verify data is refreshed
      expect(find.byType(CircularProgressIndicator), findsNothing);

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