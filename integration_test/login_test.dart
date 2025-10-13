import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breathe_better/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can log in', (tester) async {
    // Load the app
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Enter login credentials
    await tester.enterText(
        find.byKey(const Key('login_email')), 'boiblek04@gmail.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'lolz1433');

    // Tap login button
    final loginButton = find.byKey(const Key('login_button'));
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Define all possible home screen keys
    final homeKeys = [
      find.byKey(const Key('studentHomeScreen')),
      find.byKey(const Key('adminHomeScreen')),
      find.byKey(const Key('counselorHomeScreen')),
    ];

    // Check if *any* of the home keys is found in the widget tree
    final isInHome = homeKeys.any((finder) => finder.evaluate().isNotEmpty);

    expect(
      isInHome,
      true,
      reason:
          'Expected user to be on one of the home screens, but none were found.',
    );
  });
}
