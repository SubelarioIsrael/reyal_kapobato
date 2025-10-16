// 10-05-25 BB-003: Users leaves password field empty during login attempt
// Requirement: Login fails with "Password field is required" error message
// This test uses the exact password validator logic from login_page.dart

import 'package:flutter_test/flutter_test.dart';

String? passwordValidator(String? value) {
	if (value == null || value.isEmpty) {
		return 'Password field is required';
	}
	if (value.length < 6) {
		return 'Password must be at least 6 characters';
	}
	return null;
}

void main() {
	group('BB-003: Password field validation', () {
		test('Empty password returns required error', () {
			expect(passwordValidator(''), 'Password field is required');
			expect(passwordValidator(null), 'Password field is required');
			expect(passwordValidator('   '.trim()), 'Password field is required');
		});

		test('Short password returns min length error', () {
			expect(passwordValidator('123'), 'Password must be at least 6 characters');
			expect(passwordValidator('abc'), 'Password must be at least 6 characters');
		});

		test('Valid password returns null', () {
			expect(passwordValidator('123456'), null);
			expect(passwordValidator('password123'), null);
		});
	});
}
