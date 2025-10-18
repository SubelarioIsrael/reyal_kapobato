// 10-05-25 BB-007: Users enters an unverified email during login
// Requirement: Login fails with "Your email address has not been verified. Please check your inbox and click the verification link before logging in." error message
// This test simulates the login logic from login_page.dart

import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String email;
	final String id;
	final DateTime? emailConfirmedAt;
	MockUser({required this.email, required this.id, this.emailConfirmedAt});
}

String? checkEmailVerified(MockUser user) {
	if (user.emailConfirmedAt == null) {
		return 'Your email address has not been verified. Please check your inbox and click the verification link before logging in.';
	}
	return null;
}

void main() {
	group('BB-007: Unverified email login', () {
		test('Unverified email returns correct error message', () {
			final user = MockUser(email: 'user@example.com', id: 'user-id', emailConfirmedAt: null);
			final result = checkEmailVerified(user);
			expect(result, 'Your email address has not been verified. Please check your inbox and click the verification link before logging in.');
		});

		test('Verified email returns null', () {
			final user = MockUser(email: 'user@example.com', id: 'user-id', emailConfirmedAt: DateTime.now());
			final result = checkEmailVerified(user);
			expect(result, null);
		});
	});
}
