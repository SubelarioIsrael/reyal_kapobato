import 'dart:async';
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

Future<void> login(WidgetTester tester, String email, String password) async {
  await tester.pumpAndSettle();
  await tester.pumpUntilFound(find.byKey(const Key('login_email')));
  await tester.enterText(find.byKey(const Key('login_email')), email);
  await tester.enterText(find.byKey(const Key('login_password')), password);
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();
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

  testWidgets('ITC-012: Student opens resource details.', (tester) async {
    // Launch app
    await app.testMain();
    await tester.pumpAndSettle();

    // Credentials: prefer env, otherwise fallback to ITC-002 student credentials
    final studentEmail = dotenv.env['STUDENT_EMAIL'] ?? 'itzmethresh@gmail.com';
    final studentPassword = dotenv.env['STUDENT_PASSWORD'] ?? 'allan123';

    // Log in
    await login(tester, studentEmail, studentPassword);

    // Wait for student home and navigate to resources
    await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')), timeout: const Duration(seconds: 15));
    Navigator.of(tester.element(find.byKey(const Key('studentHomeScreen')))).pushNamed('student-mental-health-resources');
    await tester.pumpAndSettle();

    // Wait for resource page headers to appear
    await tester.pumpUntilFound(find.text('Articles'), timeout: const Duration(seconds: 15));

    // Heuristic: pick the first visible Text widget that is likely a resource title
    final excludeSet = {
      'Videos',
      'Articles',
      'Wellness Resources',
      'Description',
      'Tags',
      'Published:',
      'No videos available yet',
      'No articles available yet',
      'Check back later for new content',
      'Read Article',
      'Watch Video'
    };

    String? candidate;
    for (final widget in tester.widgetList(find.byType(Text)).cast<Text>()) {
      final data = widget.data?.trim();
      if (data == null || data.isEmpty) continue;
      if (data.length < 3) continue;
      if (excludeSet.contains(data)) continue;
      if (data.startsWith('No ') || data.startsWith('Check ')) continue;
      // Found a plausible resource title
      candidate = data;
      break;
    }

    if (candidate == null) {
      fail('Could not find a resource title to tap on the resources page.');
    }

    // Tap the resource title (this should activate the InkWell that opens details)
    await tester.tap(find.text(candidate));
    await tester.pumpAndSettle();

    // Verify the details bottom sheet/dialog opened: either 'Article' or 'Video Resource' header should appear
    final articleFinder = find.text('Article');
    final videoFinder = find.text('Video Resource');

    try {
      await tester.pumpUntilFound(articleFinder, timeout: const Duration(seconds: 6));
    } catch (_) {
      await tester.pumpUntilFound(videoFinder, timeout: const Duration(seconds: 6));
    }

    // Short delay then end test (do NOT proceed to open external URL)
    await tester.pump(const Duration(milliseconds: 500));
  }, timeout: const Timeout(Duration(seconds: 90)));
}
