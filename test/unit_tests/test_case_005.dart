// 10-05-25 BB-005: Users enters correct email but wrong password
// Requirement: Login fails with "Invalid credentials" message
// This test simulates the login logic from login_page.dart

import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String email;
	final String id;
	final DateTime? emailConfirmedAt;
	MockUser({required this.email, required this.id, this.emailConfirmedAt});
}

class MockAuthResponse {
	final MockUser? user;
	MockAuthResponse(this.user);
}

Future<MockAuthResponse> mockSignInWithPassword({required String email, required String password}) async {
	// Simulate valid credentials
	if (email == 'student@example.com' && password == 'password123') {
		return MockAuthResponse(MockUser(email: email, id: 'student-id', emailConfirmedAt: DateTime.now()));
	}
	// Simulate invalid credentials
	throw Exception('Invalid login credentials');
}

void main() {
	group('BB-005: Invalid password login', () {
		test('Correct email, wrong password returns invalid credentials error', () async {
			try {
				await mockSignInWithPassword(email: 'student@example.com', password: 'wrongpass');
				fail('Should have thrown invalid credentials');
			} catch (e) {
				expect(e.toString(), contains('Invalid login credentials'));
			}
		});

		test('Correct email and password logs in', () async {
			final response = await mockSignInWithPassword(email: 'student@example.com', password: 'password123');
			expect(response.user, isNotNull);
		});
	});
}
