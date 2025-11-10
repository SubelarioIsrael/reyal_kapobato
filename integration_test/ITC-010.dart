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

  late SupabaseClient client; // Fix type and use 'late'

  // Initialize Supabase only once before all tests
  setUpAll(() async {
    // Load environment variables
    await dotenv.load(fileName: 'important_stuff.env');

    // Initialize Supabase (mocked/stubbed backend recommended)
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    client = Supabase.instance.client;
  });

  

  group('ITC-010: Test integration of journal entries with NLP insights in assessment module.', () {
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
      // Wait for login screen to reappear
      await tester.pumpUntilFound(find.byKey(const Key('login_email')));
    }
    testWidgets('Student submits reflective journal.', (tester) async {
      await app.testMain(); 
      await tester.pumpAndSettle();

      await login(tester, 'itzmethresh@gmail.com', 'allan123');
      await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')));
      expect(find.byKey(const Key('studentHomeScreen')), findsOneWidget);
      await tester.pumpAndSettle();

      // Ensure the journal entry is visible (scroll if needed)
      final journalFinder = find.text('My Mood Journal'); // Remove extra parentheses
      await tester.pumpAndSettle();
      if (journalFinder.evaluate().isEmpty) {
        // Try to scroll the dashboard
        await tester.drag(find.byType(GridView), const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      if (journalFinder.evaluate().isNotEmpty) {
        await tester.tap(journalFinder); // Tap directly on the text
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const Key('write_journal_entry_fab')));
      await tester.pumpAndSettle();

      // Find title field and enter text
      final titleField = find.byKey(const Key('journal_title_field'));
      await tester.enterText(titleField, 'My day was okay');
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 5));

      // Find content field and enter text
      final contentField = find.byKey(const Key('journal_content_field'));
      await tester.enterText(contentField, 'I felt fine most of the day but tired.');
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 5));

      // Optionally toggle “Share with counselor”
      final switchTile = find.byType(SwitchListTile);
      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.byKey(const Key('save_journal_entry_button')));
      await tester.pumpAndSettle();

      // Get the latest journal for the logged-in test user
      final response = await client
          .from('journal_entries')
          .select('title, content, sentiment, insight')
          .order('entry_timestamp', ascending: false)
          .limit(1)
          .maybeSingle(); // Use .maybeSingle() for Supabase query

      final entries = response != null ? [response] : [];

      expect(entries, isNotEmpty);
      expect(entries.first['title'], equals('My day was okay')); // Match the title entered above
      expect(entries.first['content'], equals('I felt fine most of the day but tired.')); // Match the content entered above
      expect(entries.first['sentiment'], isNotNull);
      expect(entries.first['insight'], isNotNull);

      });
  });
}
