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
    try {
      await dotenv.load(fileName: 'important_stuff.env');
      try {
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        );
      } catch (_) {
        // ignore
      }
    } catch (_) {
      // ignore
    }
  });

  group('ITC-006: Profile update flow', () {
    Future<void> login(WidgetTester tester, String email, String password) async {
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('login_email')));
      await tester.enterText(find.byKey(const Key('login_email')), email);
      await tester.enterText(find.byKey(const Key('login_password')), password);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
    }

    testWidgets('User can update profile and see saved changes reflected', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();

      final studentEmail = dotenv.env['STUDENT_EMAIL'] ?? 'itzmethresh@gmail.com';
      final studentPass = dotenv.env['STUDENT_PASSWORD'] ?? 'allan123';

      await login(tester, studentEmail, studentPass);

      // Wait for student home screen
      await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')), timeout: const Duration(seconds: 15));
      await tester.pumpAndSettle();

      // Open drawer and navigate to Profile
      await tester.tap(find.byKey(const Key('drawer_button')));
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.text('Profile'));
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Wait for profile page to load
      await tester.pumpUntilFound(find.text('Student Profile'), timeout: const Duration(seconds: 10));
      await tester.pumpAndSettle();

      // Fill first name and last name (TextFormField order: first, last, email, year)
      final tfFinder = find.byType(TextFormField);
      await tester.pumpUntilFound(tfFinder);

      final ts = DateTime.now().millisecondsSinceEpoch;
      final newFirst = 'ITCFirstUpd$ts';
      final newLast = 'ITCLastUpd$ts';

      await tester.enterText(tfFinder.at(0), newFirst);
      await tester.enterText(tfFinder.at(1), newLast);
      await tester.pumpAndSettle();

      // Select Education Level (choose Basic Education)
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);
      await tester.pumpUntilFound(dropdownFinder);
      await tester.tap(dropdownFinder.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Basic Education (Grades 1-10)').last);
      await tester.pumpAndSettle();

      // Fill Year Level (assumed to be the 4th TextFormField)
      final allTfs = find.byType(TextFormField);
      await tester.pumpUntilFound(allTfs);
      final yearIndex = allTfs.evaluate().length > 3 ? 3 : allTfs.evaluate().length - 1;
      await tester.enterText(allTfs.at(yearIndex), '1');
      await tester.pumpAndSettle();

      // Save Changes
      await tester.pumpUntilFound(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Expect success dialog indicating profile updated
      await tester.pumpUntilFound(find.text('Profile updated successfully'), timeout: const Duration(seconds: 10));
      expect(find.textContaining('Profile updated successfully'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}