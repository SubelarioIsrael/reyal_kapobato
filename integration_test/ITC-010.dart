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

  group('ITC-013: Test admin resource management integration with user interface.', () {
    testWidgets('Push notification reminder is received and displayed.', (tester) async {
      await app.testMain(); 
      await tester.pumpAndSettle();

    });
  });

  testWidgets('ITC-013: Admin adds/updates resource appears in student list', (tester) async {
    final supabase = Supabase.instance.client;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final createdTitle = 'ITC-013 Created $timestamp';
    final updatedTitle = 'ITC-013 Updated $timestamp';
    final mediaUrl = 'https://example.com/itc-013/$timestamp';

    int? resourceId;

    // Simulate admin adding resource via DB (ensures deterministic test)
    try {
      final insertRes = await supabase.from('mental_health_resources').insert({
        'title': createdTitle,
        'description': 'Created by ITC-013 test',
        'resource_type': 'article',
        'media_url': mediaUrl,
        'tags': 'itc,test',
        'publish_date': DateTime.now().toIso8601String(),
      }).select('resource_id').maybeSingle();
      if (insertRes != null && insertRes['resource_id'] != null) {
        resourceId = insertRes['resource_id'] as int;
      }
    } catch (e) {
      print('ITC-013: failed to insert resource: $e');
    }

    // Launch app and login as student to verify created resource is visible
    await app.testMain();
    await tester.pumpAndSettle();
    final studentEmail = dotenv.env['STUDENT_EMAIL'] ?? 'itzmethresh@gmail.com';
    final studentPassword = dotenv.env['STUDENT_PASSWORD'] ?? 'allan123';
    await login(tester, studentEmail, studentPassword);

    // Navigate to student resources page
    await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')), timeout: const Duration(seconds: 15));
    Navigator.of(tester.element(find.byKey(const Key('studentHomeScreen')))).pushNamed('student-mental-health-resources');
    await tester.pumpAndSettle();

    // Verify created resource appears for student
    final createdFinder = find.text(createdTitle);
    await tester.pumpUntilFound(createdFinder, timeout: const Duration(seconds: 15));
    expect(createdFinder, findsOneWidget);

    // Now simulate admin updating the resource title (DB update)
    if (resourceId != null) {
      try {
        await supabase.from('mental_health_resources').update({'title': updatedTitle}).eq('resource_id', resourceId);
      } catch (e) {
        print('ITC-013: failed to update resource: $e');
      }
    }

    // Give the backend a moment to persist the update
    await tester.pump(const Duration(seconds: 2));

    // Force a refresh WITHOUT scrolling: re-push the student resources route from the student home.
    // This avoids gestures and relies on navigator to re-create the resources screen.
    final homeFinder = find.byKey(const Key('studentHomeScreen'));
    if (homeFinder.evaluate().isNotEmpty) {
      Navigator.of(tester.element(homeFinder)).pushNamed('student-mental-health-resources');
      await tester.pumpAndSettle();
    }

    final updatedFinder = find.text(updatedTitle);
    await tester.pumpUntilFound(updatedFinder, timeout: const Duration(seconds: 15));
    expect(updatedFinder, findsOneWidget);

    // Cleanup: delete test resource
    if (resourceId != null) {
      try {
        await supabase.from('mental_health_resources').delete().eq('resource_id', resourceId);
      } catch (_) {}
    }

    // short delay
    await tester.pump(const Duration(milliseconds: 500));
  }, timeout: const Timeout(Duration(seconds: 120)));
}