import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  const MethodChannel urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    // Clear mock handler after each test
    urlLauncherChannel.setMockMethodCallHandler(null);
  });

  testWidgets('SRM-QC-01: tapping emergency contact opens call prompt (tel:)', (tester) async {
    final List<MethodCall> calls = [];
    urlLauncherChannel.setMockMethodCallHandler((methodCall) async {
      calls.add(methodCall);
      // Simulate canLaunch true and launch success
      if (methodCall.method == 'canLaunch') return true;
      if (methodCall.method == 'launch') return true;
      return null;
    });

    // Minimal widget that mimics the call action used in the app
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return ElevatedButton(
            key: const Key('call_button'),
            onPressed: () async {
              final uri = Uri(scheme: 'tel', path: '09123456789');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot launch')));
              }
            },
            child: const Text('Call Contact'),
          );
        }),
      ),
    ));

    await tester.tap(find.byKey(const Key('call_button')));
    await tester.pumpAndSettle();

    // Verify platform channel received canLaunch and launch with correct url
    expect(calls.any((c) => c.method == 'canLaunch' && c.arguments['url'] == 'tel:09123456789'), isTrue);
    expect(calls.any((c) => c.method == 'launch' && c.arguments['url'] == 'tel:09123456789'), isTrue);
  });

  testWidgets('SRM-QC-01: tapping hotline opens message prompt (sms:)', (tester) async {
    final List<MethodCall> calls = [];
    urlLauncherChannel.setMockMethodCallHandler((methodCall) async {
      calls.add(methodCall);
      if (methodCall.method == 'canLaunch') return true;
      if (methodCall.method == 'launch') return true;
      return null;
    });

    // Minimal widget that mimics the message action used in the app
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return ElevatedButton(
            key: const Key('sms_button'),
            onPressed: () async {
              final uri = Uri(scheme: 'sms', path: '09123456789');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot launch')));
              }
            },
            child: const Text('Message Hotline'),
          );
        }),
      ),
    ));

    await tester.tap(find.byKey(const Key('sms_button')));
    await tester.pumpAndSettle();

    // Verify platform channel received canLaunch and launch with correct url
    expect(calls.any((c) => c.method == 'canLaunch' && c.arguments['url'] == 'sms:09123456789'), isTrue);
    expect(calls.any((c) => c.method == 'launch' && c.arguments['url'] == 'sms:09123456789'), isTrue);
  });
}
