// TEST CASE 001C: Integration Testing Example
// This WOULD run the actual app and perform real login attempts

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breathe_better/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Real App Login Tests', () {
    testWidgets('Student tries to login with invalid email format in real app', (WidgetTester tester) async {
      // Start the actual BreatheBetter app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login page (if not already there)
      // This depends on your app's navigation structure
      
      // Find the actual email field in your LoginPage
      final emailField = find.byKey(Key('login_email'));
      expect(emailField, findsOneWidget);

      // Real user interaction: Type invalid email
      await tester.enterText(emailField, 'invalidemailformat');
      
      // Find and tap the actual login button
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify the error message appears in the real app
      expect(find.text('Invalid email format'), findsOneWidget);
      
      print('✅ Integration Test: Real app shows email validation error');
    });

    testWidgets('Student tries valid email but wrong password (real network)', (WidgetTester tester) async {
      // This would test actual Supabase authentication
      app.main();
      await tester.pumpAndSettle();

      // Enter valid email format
      final emailField = find.byKey(Key('login_email'));
      await tester.enterText(emailField, 'test@example.com');
      
      // Enter wrong password
      final passwordField = find.byKey(Key('login_password'));
      await tester.enterText(passwordField, 'wrongpassword');
      
      // Tap login button
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(Duration(seconds: 5)); // Wait for network

      // Check for authentication error from Supabase
      expect(find.textContaining('Invalid login credentials'), findsOneWidget);
      
      print('✅ Integration Test: Real authentication fails with wrong credentials');
    });
  });
}

/* 
HOW TO RUN INTEGRATION TESTS:
1. flutter test integration_test/
2. Or run on real device: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/login_test.dart
*/