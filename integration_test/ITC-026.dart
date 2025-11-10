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

  group('ITC-026: Hotline Update Integration', () {
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

    testWidgets('Admin edits hotline, student sees update immediately', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();
      await login(tester, 'admin@email.com', 'adminadmin');
      await tester.pumpUntilFound(find.byKey(const Key('adminHomeScreen')));
      // Navigate to Manage Hotlines via quick action card
      await tester.tap(find.text('Manage Hotlines'));
      await tester.pumpAndSettle();

      // Step 1: Add a new test hotline
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('addHotlineDialog')));

      const testHotlineName = 'Test Hotline ITC-026';
      const testHotlineNumber = '1800-TEST-026';

      // Fill hotline form using keys
      await tester.enterText(find.byKey(const Key('addHotline_name')), testHotlineName);
      await tester.enterText(find.byKey(const Key('addHotline_phone')), testHotlineNumber);

      // Tap the "Add Hotline" button using key
      await tester.tap(find.byKey(const Key('addHotline_submit')));
      await tester.pumpAndSettle();

      // Wait for success snackbar
      expect(find.textContaining('Hotline added successfully'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1)); // Allow snackbar to disappear

      // Step 2: Find and edit the test hotline
      final hotlineNameFinder = find.text(testHotlineName);
      await tester.pumpUntilFound(hotlineNameFinder);

      final hotlineTileFinder = find.ancestor(
        of: hotlineNameFinder,
        matching: find.byType(ListTile),
      );
      final editButton = find.descendant(
        of: hotlineTileFinder,
        matching: find.byIcon(Icons.edit),
      );
      await tester.tap(editButton);
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('editHotlineDialog')));

      // Update hotline details using key
    const updatedNumber = '1800-NEW-HELP';
      await tester.enterText(find.byKey(const Key('editHotline_phone')), updatedNumber);
      await tester.pumpAndSettle();

      // Tap the "Save Changes" button using key
      await tester.tap(find.byKey(const Key('editHotline_submit')));
      await tester.pumpAndSettle();

      // Confirm update success
      expect(find.text('Hotline updated successfully'), findsOneWidget);

      // Go back until admin home page is found before logging out
      while (find.byKey(const Key('adminHomeScreen')).evaluate().isEmpty) {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.pumpUntilFound(find.byKey(const Key('adminHomeScreen')));

      await logout(tester);

      await tester.pumpAndSettle();

      // Step 3: Student logs in and checks hotline list
      await login(tester, 'itzmethresh@gmail.com', 'allanjayz');
      await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')));
      await tester.tap(find.text('Support Contacts'));
      await tester.pumpAndSettle();

      // Verify updated hotline is present in hotlines section
      expect(find.text(updatedNumber), findsOneWidget);
    });
  });
}
