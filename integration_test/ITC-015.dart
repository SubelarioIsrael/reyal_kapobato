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

Future<void> navigateBackToHome(WidgetTester tester, Key homeKey) async {
  int attempts = 0;
  while (tester.any(find.byKey(homeKey)) == false && attempts < 10) {
    bool wentBack = false;
    if (tester.any(find.byKey(const Key('backButton')))) {
      await tester.tap(find.byKey(const Key('backButton')));
      wentBack = true;
    }
    if (!wentBack) {
      await tester.pageBack();
    }
    await tester.pumpAndSettle();
    attempts++;
  }
  await tester.pumpUntilFound(find.byKey(homeKey));
}

Future<void> login(WidgetTester tester, String email, String password) async {
  await tester.pumpAndSettle();
  await tester.pumpUntilFound(find.byKey(const Key('login_email')));
  await tester.enterText(find.byKey(const Key('login_email')), email);
  await tester.enterText(find.byKey(const Key('login_password')), password);
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();
}

Future<void> logout(WidgetTester tester, Key homeKey) async {
  await navigateBackToHome(tester, homeKey);
  await tester.tap(find.byKey(const Key('drawer_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Logout'));
  await tester.pumpAndSettle();
  await tester.pumpUntilFound(find.byKey(const Key('login_email')));
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

  testWidgets('ITC-015: Student selects counselor and schedules appointment; counselor sees pending request', (tester) async {
    await app.testMain();
    await tester.pumpAndSettle();

    // Student login
    await login(tester, 'itzmethresh@gmail.com', 'allan123');
    await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')));

    // Navigate to counselors (robust: try several fallbacks instead of tapping an icon)
    await tester.pumpAndSettle();
    bool navigated = false;

    // 1) Try tapping visible quick action / card text
    final connectTextFinder = find.text('Connect with a Counselor');
    if (tester.any(connectTextFinder)) {
      await tester.tap(connectTextFinder);
      await tester.pumpAndSettle();
      navigated = tester.any(find.text('Counselors'));
    }

    // 2) Try tapping any card labeled "Counselors" or the feature card if present
    if (!navigated) {
      final counselorsTitleFinder = find.text('Counselors');
      if (tester.any(counselorsTitleFinder)) {
        // already on counselors screen
        navigated = true;
      } else {
        // try tapping a feature card that might navigate
        final featureCardFinder = find.text('Connect with a Counselor');
        if (tester.any(featureCardFinder)) {
          await tester.tap(featureCardFinder);
          await tester.pumpAndSettle();
          navigated = tester.any(find.text('Counselors'));
        }
      }
    }

    // 3) Fallback: try named routes (both variants)
    if (!navigated) {
      try {
        Navigator.of(tester.element(find.byKey(const Key('studentHomeScreen')))).pushNamed('/student-counselors');
        await tester.pumpAndSettle();
        navigated = tester.any(find.text('Counselors'));
      } catch (_) {}
    }
    if (!navigated) {
      try {
        Navigator.of(tester.element(find.byKey(const Key('studentHomeScreen')))).pushNamed('student-counselors');
        await tester.pumpAndSettle();
        navigated = tester.any(find.text('Counselors'));
      } catch (_) {}
    }

    // 4) Last resort: open drawer and try to tap "Counselors" if available
    if (!navigated) {
      if (tester.any(find.byKey(const Key('drawer_button')))) {
        await tester.tap(find.byKey(const Key('drawer_button')));
        await tester.pumpAndSettle();
        final drawerCounselors = find.text('Counselors');
        if (tester.any(drawerCounselors)) {
          await tester.tap(drawerCounselors);
          await tester.pumpAndSettle();
          navigated = true;
        }
      }
    }

    if (!navigated) {
      throw Exception('Unable to navigate to Counselors screen in test (tried text tap, feature card, named routes and drawer).');
    }

    // Wait for counselors screen
    await tester.pumpUntilFound(find.text('Counselors'), timeout: const Duration(seconds: 8));

    // Tap first counselor card (use stable key)
    final firstCounselorKey = find.byKey(const Key('counselorCard_0'));
    if (tester.any(firstCounselorKey)) {
      await tester.tap(firstCounselorKey);
    } else {
      // fallback to first InkWell if key not found
      await tester.tap(find.byType(InkWell).first);
    }
    await tester.pumpAndSettle();

    // Booking dialog should appear: pick date and time quickly
    // Tap "Select a date" area (find text)
    if (tester.any(find.text('Select a date'))) {
      await tester.tap(find.text('Select a date'));
      await tester.pumpAndSettle();
      // Pick tomorrow
      await tester.tap(find.bySemanticsLabel('OK')); // accept date picker
      await tester.pumpAndSettle();
    }

    // Pick time (choose start time)
    if (tester.any(find.text('Select time'))) {
      await tester.tap(find.text('Select time'));
      await tester.pumpAndSettle();
      // Accept time picker
      if (tester.any(find.bySemanticsLabel('OK'))) {
        await tester.tap(find.bySemanticsLabel('OK'));
        await tester.pumpAndSettle();
      }
    }

    // Enter a short note
    if (tester.any(find.byType(TextFormField))) {
      await tester.enterText(find.byType(TextFormField).last, 'ITC-015 booking note');
      await tester.pumpAndSettle();
    }

    // Tap Book Appointment
    // target the dialog's Book button specifically
    final bookDialogButton = find.byKey(const Key('bookAppointmentDialogButton'));
    if (tester.any(bookDialogButton)) {
      await tester.tap(bookDialogButton);
      await tester.pumpAndSettle();
    } else if (tester.any(find.byKey(const Key('submitAppointmentButton')))) {
      // last-resort fallback
      await tester.tap(find.byKey(const Key('submitAppointmentButton')));
      await tester.pumpAndSettle();
    }

    // Expect success snackbar or message
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('Appointment booked', findRichText: false), findsWidgets);

    // Logout student
    await logout(tester, const Key('studentHomeScreen'));

    // Counselor login
    await login(tester, 'allanjayv01@gmail.com', 'allan123');
    await tester.pumpUntilFound(find.byKey(const Key('counselorHomeScreen')));

    // Navigate to All Appointments
    await tester.tap(find.text('All Appointments').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Alternatively press quick action card
    if (tester.any(find.text('All Appointments')) == false) {
      final allAppointmentsCard = find.text('All Appointments');
      if (tester.any(allAppointmentsCard)) {
        await tester.tap(allAppointmentsCard);
        await tester.pumpAndSettle();
      } else {
        // try route
        Navigator.of(tester.element(find.byKey(const Key('counselorHomeScreen')))).pushNamed('/all-appointments');
        await tester.pumpAndSettle();
      }
    }

    // Wait and verify at least one PENDING label exists
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('PENDING'), findsWidgets);

    // Logout counselor
    await logout(tester, const Key('counselorHomeScreen'));
  }, timeout: const Timeout(Duration(minutes: 3)));
}