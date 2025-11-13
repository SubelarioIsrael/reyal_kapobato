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

  group('ITC-013: Test admin resource management integration with user interface.', () {
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

    testWidgets('ITC-013: Test admin resource management integration with user interface.', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();

      // Admin credentials (from prompt)
      final adminEmail = dotenv.env['ADMIN_EMAIL'] ?? 'admin@email.com';
      final adminPassword = dotenv.env['ADMIN_PASSWORD'] ?? 'adminadmin';

      // Student credentials (from prompt)
      final studentEmail = dotenv.env['STUDENT_EMAIL'] ?? 'itzmethresh@gmail.com';
      final studentPassword = dotenv.env['STUDENT_PASSWORD'] ?? 'allan123';

      // Login as admin
      await login(tester, adminEmail, adminPassword);

      // Wait for admin home screen to load
      await tester.pumpUntilFound(find.byKey(const Key('adminHomeScreen')), timeout: const Duration(seconds: 15));

      // Navigate to admin resources page (opens admin resource management UI)
      Navigator.of(tester.element(find.byKey(const Key('adminHomeScreen')))).pushNamed('admin-resources');
      await tester.pumpAndSettle();

      // Wait for admin resources page to appear
      await tester.pumpUntilFound(find.text('Mental Health Resources'), timeout: const Duration(seconds: 10));

      // Create a unique resource title to add and later verify
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testTitle = 'ITC-013 Test Resource $timestamp';

      // Insert resource via Supabase (simulate admin action at backend)
      int? insertedId;
      try {
        final insertResult = await Supabase.instance.client
            .from('mental_health_resources')
            .insert({
              'title': testTitle,
              'description': 'Integration test resource added by ITC-013',
              'resource_type': 'article',
              'media_url': 'https://example.com/itc-013',
              'tags': 'integration,test',
              'publish_date': DateTime.now().toIso8601String(),
            })
            .select('resource_id')
            .single();
        if (insertResult != null && insertResult['resource_id'] != null) {
          insertedId = insertResult['resource_id'] as int;
        }
      } catch (e) {
        // If insert fails, fail the test explicitly
        fail('Failed to insert test resource via Supabase: $e');
      }

      // Give the app a short moment to sync
      await tester.pump(const Duration(milliseconds: 500));

      // Return to admin home and logout
      // Use pageBack to pop the admin-resources route
      await tester.pageBack();
      await tester.pumpAndSettle();
      await logout(tester);

      // Login as student
      await login(tester, studentEmail, studentPassword);

      // Wait for student home
      await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')), timeout: const Duration(seconds: 15));

      // Navigate to the student mental health resources page
      Navigator.of(tester.element(find.byKey(const Key('studentHomeScreen')))).pushNamed('student-mental-health-resources');
      await tester.pumpAndSettle();

      // Wait for the Articles section to appear
      await tester.pumpUntilFound(find.text('Articles'), timeout: const Duration(seconds: 10));

      // Try to find the inserted resource title in the student UI
      try {
        await tester.pumpUntilFound(find.text(testTitle), timeout: const Duration(seconds: 12));
      } catch (e) {
        // If not found within timeout, fail the test with helpful message
        fail('Inserted resource "$testTitle" not visible in student resources page: $e');
      }

      // short delay then cleanup
      await tester.pump(const Duration(milliseconds: 500));

      // Cleanup: remove inserted resource from DB if we have the id or title
      try {
        if (insertedId != null) {
          await Supabase.instance.client
              .from('mental_health_resources')
              .delete()
              .eq('resource_id', insertedId);
        } else {
          await Supabase.instance.client
              .from('mental_health_resources')
              .delete()
              .eq('title', testTitle);
        }
      } catch (_) {
        // ignore cleanup errors in test
      }
    }, timeout: const Timeout(Duration(seconds: 120)));
  });
}