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

  // Initialize Supabase only once before all tests
  setUpAll(() async {
    // Load environment variables
    await dotenv.load(fileName: 'important_stuff.env');

    // Initialize Supabase (mocked/stubbed backend recommended)
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  });

  group('ITC-009: Test integration of journal sharing with counselor access.', () {
    Future<void> login(WidgetTester tester, String email, String password) async {
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('login_email')));
      await tester.enterText(find.byKey(const Key('login_email')), email);
      await tester.enterText(find.byKey(const Key('login_password')), password);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
    }
    testWidgets('Counselor views shared journal entries in student profile', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();

      await login(tester, 'allanjayv01@gmail.com', 'allan123');
      await tester.pumpUntilFound(find.byKey(const Key('counselorHomeScreen')));
      expect(find.byKey(const Key('counselorHomeScreen')), findsOneWidget);
      
      // Scroll repeatedly until 'My Students' card is found
      final myStudentsCard = find.byKey(const Key('my_students_card'));

      await tester.scrollUntilVisible(
        myStudentsCard,
        100.0, // scroll delta
        scrollable: find.byType(Scrollable),
      );

      await tester.tap(myStudentsCard);

      // tap on the first button with the word 'View' in it
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('View').first);
      await tester.pumpAndSettle();

      // tap on the tab named 'Journals'
      await tester.tap(find.byKey(const Key('journals_tab')));
      await tester.pumpAndSettle();

      // Ensure the journal entry is visible (scroll if needed)
      final entryFinder = find.byKey(const Key('journal_entry'));
      await tester.pumpAndSettle();
      if (entryFinder.evaluate().isEmpty) {
        // Try to scroll the journals tab
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      expect(entryFinder, findsWidgets); // findsWidgets for multiple entries
    });
  });
}