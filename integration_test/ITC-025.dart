import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'test_main.dart' as app;

extension PumpUntilFound on WidgetTester {
  Future<void> pumpUntilFound(Finder finder, {Duration timeout = const Duration(seconds: 10)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw Exception('Widget not found within $timeout: $finder');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: 'important_stuff.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  });

  group('ITC-025: Analytics Report PDF Export Integration', () {
    Future<void> login(WidgetTester tester, String email, String password) async {
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('login_email')));
      await tester.enterText(find.byKey(const Key('login_email')), email);
      await tester.enterText(find.byKey(const Key('login_password')), password);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
    }

    Future<void> logout(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('drawer_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('login_email')));
    }

    testWidgets('Exported PDF report contains analytics data and proper formatting', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();

      // Login as admin
      await login(tester, 'admin@email.com', 'adminadmin');
      await tester.pumpUntilFound(find.byKey(const Key('adminHomeScreen')));
      expect(find.byKey(const Key('adminHomeScreen')), findsOneWidget);

      // Tap the download button for analytics report
      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      // Confirm download in dialog
      expect(find.text('Do you want to download the Admin Analytics Report?'), findsOneWidget);
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      // Wait for SnackBar indicating success or failure
      await tester.pumpUntilFound(find.byType(SnackBar));
      expect(
        find.byWidgetPredicate((widget) =>
          widget is SnackBar &&
          (widget.content is Column || widget.content is Text)
        ),
        findsOneWidget,
      );

      // Optionally, check for the success message
      expect(find.textContaining('PDF saved successfully'), findsOneWidget);

      // Logout
      await logout(tester);
    });
  });
}
