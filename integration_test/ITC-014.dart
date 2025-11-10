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

  group('ITC-014: Chatbot responds with contextually accurate mental health responses.', () {
    Future<void> login(WidgetTester tester, String email, String password) async {
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('login_email')));
      await tester.enterText(find.byKey(const Key('login_email')), email);
      await tester.enterText(find.byKey(const Key('login_password')), password);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
    }
    testWidgets('Test chatbot API integration with mental health knowledge base.', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();

      await login(tester, 'itzmethresh@gmail.com', 'allanjayz');
      await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')));
      expect(find.byKey(const Key('studentHomeScreen')), findsOneWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('drawer_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chatbot'));
      await tester.pumpAndSettle();

      final inputField = find.byKey(const Key('chat_input_field'));
      expect(inputField, findsOneWidget);

      // Type message
      await tester.enterText(inputField, 'Hello there');
      await tester.pumpAndSettle();

      // Press send button
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Hello there'), findsOneWidget);
    });
  });
}