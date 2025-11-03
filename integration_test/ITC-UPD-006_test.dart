import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:breathe_better/main.dart';
import 'package:breathe_better/main.dart' as app;
import 'package:breathe_better/pages/student/student_profile.dart';

void main() {
  group('ITC-UPD-006: User Profile Management Integration Tests', () {
    late WidgetTester tester;

    setUp(() async {
      // Login as student before each test
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'itzmethresh@gmail.com',
        password: 'allanjayz',
      );
    });

    tearDown(() async {
      // Sign out after each test
      await Supabase.instance.client.auth.signOut();
    });

    testWidgets('should authenticate user and load profile data', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to profile page
      await tester.tap(find.byKey(const Key('profile_nav')));
      await tester.pumpAndSettle();

      // Verify user is authenticated and profile loads
      expect(find.byType(StudentProfile), findsOneWidget);
      expect(find.text('Student Profile'), findsOneWidget);
      
      // Verify profile data is loaded
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should validate and update profile information', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to profile
      await tester.tap(find.byKey(const Key('profile_nav')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Update first name
      final firstNameField = find.byType(TextFormField).first;
      await tester.enterText(firstNameField, 'UpdatedFirstName');
      await tester.pump();

      // Update education level
      final educationDropdown = find.byType(DropdownButtonFormField<String>).first;
      await tester.tap(educationDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('College').last);
      await tester.pumpAndSettle();

      // Submit update
      final updateButton = find.text('Update Profile');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Profile updated successfully'), findsOneWidget);
    });

    testWidgets('should validate required fields before saving', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to profile
      await tester.tap(find.byKey(const Key('profile_nav')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Clear required field
      final firstNameField = find.byType(TextFormField).first;
      await tester.enterText(firstNameField, '');
      await tester.pump();

      // Try to submit
      final updateButton = find.text('Update Profile');
      await tester.tap(updateButton);
      await tester.pump();

      // Verify validation error
      expect(find.text('Please enter your first name'), findsOneWidget);
    });

    testWidgets('should handle profile picture upload', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to profile
      await tester.tap(find.byKey(const Key('profile_nav')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Tap camera icon
      final cameraIcon = find.byIcon(Icons.camera_alt);
      await tester.tap(cameraIcon);
      await tester.pumpAndSettle();

      // Verify image picker dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}