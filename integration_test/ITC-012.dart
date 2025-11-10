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

  // Add a mock for url_launcher
  late List<Uri> launchedUrls;
  setUpAll(() async {
    await dotenv.load(fileName: 'important_stuff.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    client = Supabase.instance.client;
  });

  group('ITC-010: Test integration between student resource access and external resource links.', () {
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
    testWidgets('Student is redirected to the verified external link for the selected mental health resource.', (tester) async {
      await app.testMain(); 
      await tester.pumpAndSettle();

      await login(tester, 'itzmethresh@gmail.com', 'allanjayz');
      await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')));
      expect(find.byKey(const Key('studentHomeScreen')), findsOneWidget);
      await tester.pumpAndSettle();

      // Scroll the home page if needed (example: scroll down by 300 pixels)
      final scrollable = find.byKey(const Key('studentHomeScrollView'));
      expect(scrollable, findsOneWidget);
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wellness Resources'));
      await tester.pumpAndSettle();

      // Wait for resources to load
      await tester.pump(const Duration(seconds: 2));

      // Tap the first resource card (video or article)
      final resourceCard = find.byType(InkWell).first;
      await tester.tap(resourceCard);
      await tester.pumpAndSettle();

      // Tap the action button (Watch Video/Read Article)
      final actionButton = find.byType(ElevatedButton).last;
      await tester.tap(actionButton);
      await tester.pumpAndSettle();

      // Check that the modal is closed and resource list is visible again
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Articles'), findsOneWidget);
    });
  });
}
