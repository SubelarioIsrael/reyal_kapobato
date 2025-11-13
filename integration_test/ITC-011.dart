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

  group('ITC-011: Test the integration between breathing exercises and daily mood tracking.', () {
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
    testWidgets('Breathing exercise is completed and system logs activity.', (tester) async {
      await app.testMain(); 
      await tester.pumpAndSettle();

      await login(tester, 'itzmethresh@gmail.com', 'allanjayz');
      await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')));
      expect(find.byKey(const Key('studentHomeScreen')), findsOneWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.self_improvement));
      await tester.pumpAndSettle(); // Wait for navigation to complete

      await tester.pumpUntilFound(find.text('Testing Breathing')); // Wait for the list to appear
      await tester.tap(find.text('Testing Breathing'));
      await tester.pumpAndSettle(); // Wait for dialog

      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle(); // Wait for exercise to start

      await tester.pumpUntilFound(find.text('Exercise Complete!')); // Wait for completion dialog
      expect(find.text('Exercise Complete!'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle(); // Wait for dialog to close
    });
  });
}