import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breathe_better/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can log in', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('login_email')),
        const String.fromEnvironment('TEST_LOGIN_EMAIL',
            defaultValue: 'default_email@example.com'));
    await tester.enterText(
        find.byKey(const Key('login_password')),
        const String.fromEnvironment('TEST_LOGIN_PASSWORD',
            defaultValue: 'default_password'));
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Student Home'), findsOneWidget);
  });
}
