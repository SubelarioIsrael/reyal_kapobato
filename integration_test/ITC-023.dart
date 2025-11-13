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

Future<void> logout(WidgetTester tester, Key homeKey) async {
  // Try to navigate back to the home screen using several strategies,
  // but avoid tester.pageBack() which can assert if the framework
  // doesn't expose a Cupertino back button.
  int attempts = 0;
  while (tester.any(find.byKey(homeKey)) == false && attempts < 10) {
    bool navigated = false;

    // 1) Try a keyed back button if your app sets one
    final keyedBack = find.byKey(const Key('backButton'));
    if (tester.any(keyedBack)) {
      await tester.tap(keyedBack);
      navigated = true;
    }

    // 2) Try IconButton variants commonly used for back actions
    if (!navigated) {
      final backIos = find.widgetWithIcon(IconButton, Icons.arrow_back_ios_new_rounded);
      final backMat = find.widgetWithIcon(IconButton, Icons.arrow_back);
      if (tester.any(backIos)) {
        await tester.tap(backIos.first);
        navigated = true;
      } else if (tester.any(backMat)) {
        await tester.tap(backMat.first);
        navigated = true;
      }
    }

    // 3) Try the BackButton widget
    if (!navigated) {
      final backButtonWidget = find.byType(BackButton);
      if (tester.any(backButtonWidget)) {
        await tester.tap(backButtonWidget.first);
        navigated = true;
      }
    }

    // 4) As a last-resort safe attempt, try to pop the Navigator if possible
    if (!navigated) {
      try {
        // Use a small pump to allow any animations to settle before trying Navigator.pop()
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        if (tester.any(find.byType(Scaffold))) {
          // Attempt a programmatic pop via the tester's element context
          final scaffoldFinder = find.byType(Scaffold).first;
          try {
            Navigator.of(tester.element(scaffoldFinder)).maybePop();
            navigated = true;
          } catch (_) {
            // ignore and continue to drawer fallback
          }
        }
      } catch (_) {
        // ignore and continue
      }
    }

    await tester.pumpAndSettle();
    attempts++;
    if (!navigated) break; // avoid looping when nothing can navigate back
  }

  // If home screen is visible, open drawer and logout; otherwise still try drawer if present
  if (tester.any(find.byKey(const Key('drawer_button')))) {
    await tester.tap(find.byKey(const Key('drawer_button')));
    await tester.pumpAndSettle();
  }

  if (tester.any(find.text('Logout'))) {
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
  } else if (tester.any(find.byKey(const Key('logout_button')))) {
    // alternative keyed logout
    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();
  }

  // Ensure we end up on the login screen (or at least the login_email field)
  await tester.pumpUntilFound(find.byKey(const Key('login_email')));
}

Future<Map<String, dynamic>?> waitForVideoCallRow(SupabaseClient supabase, String callCode,
    {Duration timeout = const Duration(seconds: 10)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    try {
      final row = await supabase.from('video_calls').select().eq('call_code', callCode).maybeSingle();
      if (row != null) return Map<String, dynamic>.from(row);
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 300));
  }
  return null;
}

Future<Map<String, dynamic>?> waitForVideoCallUpdate(SupabaseClient supabase, String callCode,
    {Duration timeout = const Duration(seconds: 15)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    try {
      final row = await supabase.from('video_calls').select().eq('call_code', callCode).maybeSingle();
      if (row != null && row['student_user_id'] != null && row['student_joined_at'] != null) {
        return Map<String, dynamic>.from(row);
      }
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 300));
  }
  return null;
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

  testWidgets('ITC-023: Generate call ID (counselor) and student types it into Join dialog', (tester) async {
    await app.testMain();
    await tester.pumpAndSettle();

    final supabase = Supabase.instance.client;

    // 1) Counselor logs in and generates a call code via AllAppointments UI
    await login(tester, 'allanjayv01@gmail.com', 'allan123');
    await tester.pumpUntilFound(find.byKey(const Key('counselorHomeScreen')));

    // Open All Appointments
    Navigator.of(tester.element(find.byKey(const Key('counselorHomeScreen')))).pushNamed('/all-appointments');
    await tester.pumpAndSettle();

    // Tap FAB to open Video Call dialog
    final fab = find.byTooltip('Start Video Call');
    await tester.pumpUntilFound(fab);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Tap the Generate button (preferred label 'Generate Call Code')
    final genButton = find.textContaining('Generate Call Code');
    if (tester.any(genButton)) {
      await tester.tap(genButton);
    } else if (tester.any(find.text('Generate Code'))) {
      await tester.tap(find.text('Generate Code'));
    } else {
      final genAlt = find.widgetWithText(ElevatedButton, 'Generate Call Code');
      if (tester.any(genAlt)) await tester.tap(genAlt);
    }
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Wait for generated code to appear in UI (pattern abc-def-ghi)
    final codeFinder = find.byWidgetPredicate((w) {
      if (w is Text) {
        final txt = w.data ?? '';
        return RegExp(r'^[a-z]{3}-[a-z]{3}-[a-z]{3}$').hasMatch(txt.trim());
      }
      return false;
    });
    await tester.pump(const Duration(seconds: 1));
    expect(codeFinder, findsWidgets);

    // Capture the generated code (this simulates "copy to clipboard")
    final generatedCode = (tester.widget<Text>(codeFinder.first).data ?? '').trim();

    // Optional: verify DB row was created for the generated code
    final createdRow = await waitForVideoCallRow(supabase, generatedCode);
    expect(createdRow, isNotNull, reason: 'video_calls row not created for $generatedCode');

    // Dismiss the "Call Code Generated" dialog if it's still visible so logout/navigation can proceed.
    // Try common dismissal targets in order: tooltip 'Close Call Code Dialog', "Close" button, dialog close icon, then a generic tap on the dialog.
    await tester.pumpAndSettle();
    final closeTooltipFinder = find.byTooltip('Close Call Code Dialog');
    if (tester.any(closeTooltipFinder)) {
      await tester.tap(closeTooltipFinder.first);
      await tester.pumpAndSettle();
    } else if (tester.any(find.text('Close'))) {
      await tester.tap(find.text('Close').first);
      await tester.pumpAndSettle();
    } else if (tester.any(find.descendant(of: find.byType(AlertDialog), matching: find.byIcon(Icons.close)))) {
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byIcon(Icons.close)).first);
      await tester.pumpAndSettle();
    } else if (tester.any(find.byType(AlertDialog))) {
      // As a last resort try to tap the dialog to dismiss
      await tester.tap(find.byType(AlertDialog).first);
      await tester.pumpAndSettle();
    }

    // Logout counselor
    await logout(tester, const Key('counselorHomeScreen'));
    await tester.pumpAndSettle();

    // 2) Student logs in, navigates to Appointments, opens Join dialog and types the code
    await login(tester, 'itzmethresh@gmail.com', 'allan123');
    await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')));

    // Navigate to Appointments screen
    Navigator.of(tester.element(find.byKey(const Key('studentHomeScreen')))).pushNamed('student-appointments');
    await tester.pumpAndSettle();

    // Open Join Video Call dialog via FAB (tooltip 'Join a video call')
    Finder joinFab = find.byTooltip('Join a video call');
    if (!tester.any(joinFab)) {
      // fallback: tap the FloatingActionButton if tooltip isn't set in this build
      joinFab = find.byType(FloatingActionButton);
    }
    await tester.pumpUntilFound(joinFab);
    await tester.tap(joinFab);
    await tester.pumpAndSettle();

    // Ensure dialog present: look for 'Call Code' label (or input)
    await tester.pumpUntilFound(find.text('Call Code'));

    // Enter the captured code into the first TextField and leave the test there
    final textField = find.byType(TextField).first;
    await tester.enterText(textField, generatedCode);
    await tester.pumpAndSettle();

    // Assert the typed code is present in the UI (visible as text)
    expect(find.text(generatedCode), findsWidgets);
    // add delay
    await tester.pump(const Duration(seconds: 2));
  });
}
