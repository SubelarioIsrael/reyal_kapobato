import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:breathe_better/routes.dart';
import 'package:breathe_better/pages/login_page.dart';
import 'package:breathe_better/pages/signup_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Prevent real HttpClient creation and fail fast on accidental network use
    HttpOverrides.global = _NoNetworkHttpOverrides();
    // Minimal Supabase init so widgets that reference Supabase can construct
    try {
      await Supabase.initialize(
          url: 'https://example.supabase.co', anonKey: 'test-anon-key');
    } catch (_) {
      // If already initialized across test runs, ignore
    }
  });

  testWidgets('renders LoginPage on startup', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: appRoutes,
        initialRoute: '/login',
      ),
    );

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('BreatheBetter'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text("Don't have an account? Sign up"), findsOneWidget);
  });

  testWidgets('navigates from LoginPage to SignUpPage',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: appRoutes,
        initialRoute: '/login',
      ),
    );

    await tester.tap(find.text("Don't have an account? Sign up"));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpPage), findsOneWidget);
  });
}

class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Network calls are disabled in tests: '
          '${invocation.memberName}');
}
