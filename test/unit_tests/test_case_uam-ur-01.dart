// UAM-UR-01: Student attempts to register with existing email address
// Requirement: Student attempts to register with existing email address

import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String email;
	final String id;
	final String userType;
	MockUser({required this.email, required this.id, required this.userType});
}

// Simulated user database
Set<String> _registeredEmails = {'student@college.edu', 'admin@email.com'};

Future<bool> mockRegisterStudent({required String email, required String password}) async {
	// Check if email already exists
	if (_registeredEmails.contains(email.trim().toLowerCase())) {
		throw Exception('Email address already registered');
	}
	// Simulate registration
	_registeredEmails.add(email.trim().toLowerCase());
	return true;
}

void main() {
	group('UAM-UR-01: Student attempts to register with existing email address', () {
		setUp(() {
			// Reset database before each test
			_registeredEmails = {'student@college.edu', 'admin@email.com'};
		});

		test('Registration fails for existing email address', () async {
			expect(
				() => mockRegisterStudent(email: 'student@college.edu', password: 'newpass123'),
				throwsA(predicate((e) => e.toString().contains('Email address already registered'))),
			);
		});

		test('Registration succeeds for new email address', () async {
			final result = await mockRegisterStudent(email: 'newstudent@college.edu', password: 'newpass123');
			expect(result, true);
			expect(_registeredEmails.contains('newstudent@college.edu'), true);
		});

		test('Registration trims whitespace and checks case-insensitive email', () async {
			expect(
				() => mockRegisterStudent(email: '  STUDENT@college.edu  ', password: 'pass'),
				throwsA(predicate((e) => e.toString().contains('Email address already registered'))),
			);
		});
	});
}
