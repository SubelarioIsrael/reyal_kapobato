import 'dart:core';
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
    if (!wentBack) await tester.pageBack();
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

  testWidgets('ITC-017: Counselor generates a video call code; DB record exists and can be linked to appointment', (tester) async {
    await app.testMain();
    await tester.pumpAndSettle();

    // Prepare: create a test appointment via Supabase (so we can link later)
    final supabase = Supabase.instance.client;
    final studentUser = await supabase.from('users').select('user_id').eq('email', 'itzmethresh@gmail.com').maybeSingle();
    final counselorUser = await supabase.from('users').select('user_id').eq('email', 'allanjayv01@gmail.com').maybeSingle();
    if (studentUser == null || counselorUser == null) throw Exception('Test users missing');
    final counselorRow = await supabase.from('counselors').select('counselor_id').eq('user_id', counselorUser['user_id']).maybeSingle();
    final counselorId = counselorRow != null ? counselorRow['counselor_id'] : null;
    if (counselorId == null) throw Exception('Counselor profile missing');

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final apptDate = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2,'0')}-${tomorrow.day.toString().padLeft(2,'0')}';
    final insertAppt = await supabase.from('counseling_appointments').insert({
      'user_id': studentUser['user_id'],
      'counselor_id': counselorId,
      'appointment_date': apptDate,
      'start_time': '10:00:00',
      'end_time': '11:00:00',
      'status': 'accepted',
      'notes': 'ITC-017 appointment',
    }).select().maybeSingle();
    if (insertAppt == null) throw Exception('Failed to create appointment for ITC-017');
    final appointmentId = insertAppt['appointment_id'];

    // Counselor login
    await login(tester, 'allanjayv01@gmail.com', 'allan123');
    await tester.pumpUntilFound(find.byKey(const Key('counselorHomeScreen')));

    // Open AllAppointments and tap FAB to open video dialog
    Navigator.of(tester.element(find.byKey(const Key('counselorHomeScreen')))).pushNamed('/all-appointments');
    await tester.pumpAndSettle();

    // Tap floating action button (video)
    final fab = find.byTooltip('Start Video Call').first;
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // In the bottom sheet/dialog, tap 'Generate Call Code' button
    final genButton = find.textContaining('Generate Call Code');
    if (tester.any(genButton)) {
      await tester.tap(genButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      // try alternative button label
      final altGen = find.text('Generate Code');
      if (tester.any(altGen)) {
        await tester.tap(altGen);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    }

    // Wait for generated code to appear in UI (pattern xxx-xxx-xxx)
    final codeFinder = find.byWidgetPredicate((w) {
      if (w is Text) {
        final txt = w.data ?? '';
        return RegExp(r'^[a-z]{3}-[a-z]{3}-[a-z]{3}$').hasMatch(txt.trim());
      }
      return false;
    });
    await tester.pump(const Duration(seconds: 2));
    expect(codeFinder, findsWidgets);

    // Capture the generated code text
    final codeWidget = tester.widget<Text>(codeFinder.first);
    final generatedCode = codeWidget.data!.trim();

    // Verify DB has a video_calls row with that call_code
    final videoCallRow = await supabase.from('video_calls').select().eq('call_code', generatedCode).maybeSingle();
    expect(videoCallRow, isNotNull);
    expect(videoCallRow['counselor_id'], equals(counselorId));

    // Link video call to the appointment (simulate share/linking)
    await supabase.from('video_calls').update({
      'appointment_id': appointmentId,
      'student_user_id': studentUser['user_id']
    }).eq('call_code', generatedCode);

    final updatedRow = await supabase.from('video_calls').select().eq('call_code', generatedCode).maybeSingle();
    expect(updatedRow, isNotNull, reason: 'No updated video call record found for code $generatedCode');
    expect(updatedRow!['appointment_id'], equals(appointmentId));

    // Cleanup: remove created appointment and video_call (optional)
    try {
      await supabase.from('counseling_appointments').delete().eq('appointment_id', appointmentId);
      await supabase.from('video_calls').delete().eq('call_code', generatedCode);
    } catch (_) {}

    // Logout counselor
    await logout(tester, const Key('counselorHomeScreen'));
  }, timeout: const Timeout(Duration(minutes: 4)));
}
