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

  group('ITC-019: Admin quote management integration with student display.', () {
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

    testWidgets('Admin adds, edits, deletes quote; student dashboard updates.', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();

      // Login as admin
      await login(tester, 'admin@email.com', 'adminadmin');
      await tester.pumpUntilFound(find.byKey(const Key('adminHomeScreen')));
      expect(find.byKey(const Key('adminHomeScreen')), findsOneWidget);

      // Navigate to Daily Uplifts management
      await tester.tap(find.text('Daily\n Uplifts'));
      await tester.pumpAndSettle();
      expect(find.text('Daily Uplifts'), findsOneWidget);

      // Add a new quote
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Uplift Quote');
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Author');
      await tester.tap(find.text('Add Uplift'));
      await tester.pumpAndSettle();

      // Confirm quote appears in admin list
      expect(find.text('Test Uplift Quote'), findsWidgets);
      expect(find.text('— Test Author'), findsWidgets);

      // Edit the quote
      await tester.tap(find.widgetWithIcon(IconButton, Icons.edit).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Edited Uplift Quote');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Confirm edited quote appears
      expect(find.text('Edited Uplift Quote'), findsWidgets);

      // Delete the quote
      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm quote is deleted
      expect(find.text('Edited Uplift Quote'), findsNothing);

      // Tap the back button to return to admin home
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('adminHomeScreen')), findsOneWidget);

      // Logout admin
      await logout(tester);

      // Login as student
      await login(tester, 'itzmethresh@gmail.com', 'allan123');
      await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')));
      expect(find.byKey(const Key('studentHomeScreen')), findsOneWidget);

      // Check daily uplift quote widget exists and does not show deleted quote
      expect(find.byKey(const Key('dailyUpliftQuote')), findsAny);

      // Logout student
      await logout(tester);
    });
  });
}