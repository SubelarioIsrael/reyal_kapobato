import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:breathe_better/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can log in', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(seconds: 10));

    await tester.enterText(
        find.byKey(const Key('login_email')), 'boiblek04@gmail.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'lolz1433');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Student Home'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 5))); // Increase timeout);
}
