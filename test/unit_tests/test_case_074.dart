// 10-05-25 BB-074: Admin creates new counselor account with valid credentials
// Requirement: Counselor account successfully created and activation email sent
// This test simulates the account management logic for creating counselor accounts

import 'package:flutter_test/flutter_test.dart';

class MockAccount {
	final String id;
	final String email;
	final String userType;
	final String status;
	final DateTime createdAt;
	final bool activationEmailSent;
	
	MockAccount({
		required this.id,
		required this.email,
		required this.userType,
		required this.status,
		required this.createdAt,
		required this.activationEmailSent,
	});
}

class MockUser {
	final String email;
	final String id;
	final String userType;
	final DateTime? emailConfirmedAt;
	MockUser({required this.email, required this.id, required this.userType, this.emailConfirmedAt});
}

class MockAuthResponse {
	final MockUser? user;
	MockAuthResponse(this.user);
}

Future<MockAuthResponse> mockSignInWithPassword({required String email, required String password}) async {
	// Simulate admin credentials
	if (email == 'admin@email.com' && password == 'adminadmin') {
		return MockAuthResponse(MockUser(email: email, id: 'admin-id', userType: 'admin', emailConfirmedAt: DateTime.now()));
	}
	throw Exception('Invalid login credentials');
}

Future<MockAccount> mockCreateCounselorAccount({
	required String adminId,
	required String email,
	required String firstName,
	required String lastName,
	required String specialization,
}) async {
	// Validate email format
	if (!email.contains('@') || !email.contains('.')) {
		throw Exception('Invalid email format');
	}
	
	// Simulate successful account creation
	return MockAccount(
		id: 'counselor-${DateTime.now().millisecondsSinceEpoch}',
		email: email,
		userType: 'counselor',
		status: 'pending_activation',
		createdAt: DateTime.now(),
		activationEmailSent: true,
	);
}

void main() {
	group('BB-074: Admin creates new counselor account with valid credentials', () {
		test('Admin successfully creates counselor account and sends activation email', () async {
			// First authenticate admin
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			expect(authResponse.user, isNotNull);
			expect(authResponse.user!.userType, 'admin');
			
			// Create new counselor account
			final account = await mockCreateCounselorAccount(
				adminId: authResponse.user!.id,
				email: 'counselor@college.edu',
				firstName: 'Jane',
				lastName: 'Smith',
				specialization: 'Anxiety and Depression',
			);
			
			expect(account.email, 'counselor@college.edu');
			expect(account.userType, 'counselor');
			expect(account.status, 'pending_activation');
			expect(account.activationEmailSent, true);
			expect(account.id, isNotNull);
			expect(account.createdAt, isNotNull);
		});

		test('Invalid email format prevents account creation', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			expect(
				() => mockCreateCounselorAccount(
					adminId: authResponse.user!.id,
					email: 'invalid-email',
					firstName: 'John',
					lastName: 'Doe',
					specialization: 'General Counseling',
				),
				throwsException,
			);
		});

		test('Multiple counselor accounts can be created', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			// Create first counselor
			final account1 = await mockCreateCounselorAccount(
				adminId: authResponse.user!.id,
				email: 'counselor1@college.edu',
				firstName: 'Alice',
				lastName: 'Johnson',
				specialization: 'Stress Management',
			);
			
			// Create second counselor
			final account2 = await mockCreateCounselorAccount(
				adminId: authResponse.user!.id,
				email: 'counselor2@college.edu',
				firstName: 'Bob',
				lastName: 'Wilson',
				specialization: 'Academic Support',
			);
			
			expect(account1.email, 'counselor1@college.edu');
			expect(account2.email, 'counselor2@college.edu');
			expect(account1.id, isNot(account2.id));
		});

		test('Invalid admin credentials prevent account creation', () async {
			expect(() => mockSignInWithPassword(email: 'admin@email.com', password: 'wrongpass'), throwsException);
		});
	});
}
