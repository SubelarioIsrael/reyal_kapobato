import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:breathe_better/main.dart'; // adjust this to your app entry

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can sign up', (tester) async {
    // Load the app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Navigate to signup page
    await tester.tap(find.byKey(const Key('go_to_signup')));
    await tester.pumpAndSettle();

    // Fill out signup form
    await tester.enterText(find.byKey(const Key('signup_name')), 'Test User');
    await tester.enterText(
        find.byKey(const Key('signup_email')), 'studenttestacc555@gmail.com');
    await tester.enterText(
        find.byKey(const Key('signup_password')), 'testpassword123');
    await tester.enterText(
        find.byKey(const Key('signup_confirm_password')), 'testpassword123');

    // Tap on signup button
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pumpAndSettle();

    // Check if redirected (adjust key to whatever page comes next)
    expect(find.byKey(const Key('login_page')), findsOneWidget);
  });
}
