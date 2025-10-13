import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breathe_better/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can sign up', (tester) async {
    // Load the app
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Navigate to signup page
    final goToSignupButton = find.byKey(const Key('go_to_signup'));
    expect(goToSignupButton, findsOneWidget);
    await tester.tap(goToSignupButton);
    await tester.pumpAndSettle();

    // Fill out phase 1 of the signup form
    await tester.enterText(
        find.byKey(const Key('signup_email')), 'testuser@example.com');
    await tester.enterText(
        find.byKey(const Key('signup_password')), 'testpassword123');
    await tester.enterText(
        find.byKey(const Key('signup_confirm_password')), 'testpassword123');

    // Proceed to phase 2
    final nextButton = find.text('Next');
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Fill out phase 2 of the signup form
    await tester.enterText(
        find.byType(TextFormField).at(0), '123456'); // Student ID
    await tester.enterText(
        find.byType(TextFormField).at(1), 'Test'); // First Name
    await tester.enterText(
        find.byType(TextFormField).at(2), 'User'); // Last Name
    await tester.enterText(find.byType(TextFormField).at(3), '1'); // Year Level

    // Select education level
    final educationDropdown = find.byType(DropdownButtonFormField<String>);
    expect(educationDropdown, findsOneWidget);
    await tester.tap(educationDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('College').last);
    await tester.pumpAndSettle();

    // Submit the form
    final createButton = find.text('Create');
    expect(createButton, findsOneWidget);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    // Verify navigation to login page
    final loginPage = find.byKey(const Key('login_page'));
    expect(loginPage, findsOneWidget);
  });
}
