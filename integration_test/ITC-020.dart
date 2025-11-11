import 'dart:math';

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

Future<void> navigateBackToHome(WidgetTester tester, Key homeKey, {required bool isStudent}) async {
  int attempts = 0;
  while (tester.any(find.byKey(homeKey)) == false && attempts < 10) {
    bool wentBack = false;

    // Try key
    if (tester.any(find.byKey(const Key('backButton')))) {
      await tester.tap(find.byKey(const Key('backButton')));
      wentBack = true;
    }

    // Fallback: try pageBack (Navigator.pop)
    if (!wentBack) {
      await tester.pageBack();
    }

    await tester.pumpAndSettle();
    attempts++;
  }
  await tester.pumpUntilFound(find.byKey(homeKey));
}

Future<void> logout(WidgetTester tester, Key homeKey, {required bool isStudent}) async {
  await navigateBackToHome(tester, homeKey, isStudent: isStudent);
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

  group('ITC-020: Messaging integration between student and counselor dashboard.', () {
    Future<void> login(WidgetTester tester, String email, String password) async {
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('login_email')));
      await tester.enterText(find.byKey(const Key('login_email')), email);
      await tester.enterText(find.byKey(const Key('login_password')), password);
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
    }

    testWidgets('Student sends message, counselor sees it in real-time chat list.', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle();

      // Student logs in
      await login(tester, 'itzmethresh@gmail.com', 'allan123');
      await tester.pumpUntilFound(find.byKey(const Key('studentHomeScreen')));

      // Navigate to student chat list
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('studentChatListScreen')));

      // Open chat with counselor (first chat card)
      await tester.tap(find.byKey(const Key('studentChatCard_0')));
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('chatInputField')));

      // Send a message
      const testMessage = 'Integration test message ITC-020';
      await tester.enterText(find.byKey(const Key('chatInputField')), testMessage);
      await tester.tap(find.byKey(const Key('sendMessageButton')));
      await tester.pumpAndSettle();

      // Logout student
      await logout(tester, const Key('studentHomeScreen'), isStudent: true);

      // Counselor logs in
      await login(tester, 'allanjayv01@gmail.com', 'allan123');
      await tester.pumpUntilFound(find.byKey(const Key('counselorHomeScreen')));

      // Open drawer and tap 'Student Chats' by key
      await tester.tap(find.byKey(const Key('drawer_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('studentChatsDrawerItem')));
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.byKey(const Key('counselorChatListScreen')));

      // Verify the message appears in the chat list (first chat card)
      await tester.pump(const Duration(seconds: 2)); // Wait for realtime update
      expect(find.text(testMessage), findsWidgets);

      // Optionally, open the chat and verify message is present
      await tester.tap(find.byKey(const Key('counselorChatCard_0')));
      await tester.pumpAndSettle();
      expect(find.text(testMessage), findsWidgets);

      // Logout counselor
      await logout(tester, const Key('counselorHomeScreen'), isStudent: false);
    });
  });
}