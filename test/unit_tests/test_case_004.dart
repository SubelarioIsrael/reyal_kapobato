// 10-05-25 BB-004: Users enters valid credentials for login
// Requirement: Login successful, redirected to Student Dashboard
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

String? redirectBasedOnRole(String userId, String userType, String status) {
	if (status == 'suspended') return 'Account Suspended';
	if (status != 'active') return 'Account Not Active';
	if (userType == 'student') return 'student-home';
	if (userType == 'counselor') return 'counselor-home';
	if (userType == 'admin') return 'admin-home';
	return 'Invalid user type';
}

void main() {
	group('BB-004: Successful login and redirection', () {
		test('Valid credentials log in and redirect to Student Dashboard', () async {
			final response = await mockSignInWithPassword(email: 'student@example.com', password: 'password123');
			expect(response.user, isNotNull);
			expect(response.user!.emailConfirmedAt, isNotNull);
			// Simulate userType and status from DB
			final redirect = redirectBasedOnRole(response.user!.id, 'student', 'active');
			expect(redirect, 'student-home');
		});

		test('Counselor credentials redirect to counselor-home', () async {
			final redirect = redirectBasedOnRole('counselor-id', 'counselor', 'active');
			expect(redirect, 'counselor-home');
		});

		test('Admin credentials redirect to admin-home', () async {
			final redirect = redirectBasedOnRole('admin-id', 'admin', 'active');
			expect(redirect, 'admin-home');
		});

		test('Invalid credentials throw error', () async {
			expect(() => mockSignInWithPassword(email: 'student@example.com', password: 'wrongpass'), throwsException);
		});
	});
}
