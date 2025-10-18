// 10-05-25 BB-075: Admin suspends inactive user account
// Requirement: Account successfully suspended and access removed
// This test simulates the account management logic for suspending accounts

import 'package:flutter_test/flutter_test.dart';

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

class MockAccount {
	final String id;
	final String email;
	final String userType;
	final String status;
	final DateTime? deactivatedAt;
	
	MockAccount({
		required this.id,
		required this.email,
		required this.userType,
		required this.status,
		this.deactivatedAt,
	});
}

// Mock database to track account statuses
Map<String, MockAccount> _accountDatabase = {
	'user-123': MockAccount(id: 'user-123', email: 'inactive@student.edu', userType: 'student', status: 'active'),
	'user-456': MockAccount(id: 'user-456', email: 'old@counselor.edu', userType: 'counselor', status: 'active'),
	'user-789': MockAccount(id: 'user-789', email: 'test@student.edu', userType: 'student', status: 'active'),
};

Future<MockAuthResponse> mockSignInWithPassword({required String email, required String password}) async {
	// Simulate admin credentials
	if (email == 'admin@email.com' && password == 'adminadmin') {
		return MockAuthResponse(MockUser(email: email, id: 'admin-id', userType: 'admin', emailConfirmedAt: DateTime.now()));
	}
	throw Exception('Invalid login credentials');
}

Future<bool> mockSuspendAccount({
	required String adminId,
	required String userId,
}) async {
	// Check if account exists
	if (!_accountDatabase.containsKey(userId)) {
		throw Exception('Account not found');
	}
	
	final account = _accountDatabase[userId]!;
	
	// Check if account is already suspended
	if (account.status == 'suspended') {
		throw Exception('Account already suspended');
	}
	
	// Simulate successful suspension
	_accountDatabase[userId] = MockAccount(
		id: account.id,
		email: account.email,
		userType: account.userType,
		status: 'suspended',
		deactivatedAt: DateTime.now(),
	);
	
	return true;
}

Future<MockAccount?> mockGetAccountStatus(String userId) async {
	return _accountDatabase[userId];
}

Future<bool> mockAttemptLogin(String email, String password) async {
	// Find account by email
	final account = _accountDatabase.values.firstWhere(
		(acc) => acc.email == email,
		orElse: () => throw Exception('Account not found'),
	);
	
	// Check if account is suspended
	if (account.status == 'suspended') {
		throw Exception('Account access removed - Account suspended');
	}
	
	return true;
}

void main() {
	group('BB-075: Admin suspends inactive user account', () {
		setUp(() {
			// Reset database state before each test
			_accountDatabase = {
				'user-123': MockAccount(id: 'user-123', email: 'inactive@student.edu', userType: 'student', status: 'active'),
				'user-456': MockAccount(id: 'user-456', email: 'old@counselor.edu', userType: 'counselor', status: 'active'),
				'user-789': MockAccount(id: 'user-789', email: 'test@student.edu', userType: 'student', status: 'active'),
			};
		});

		test('Admin successfully suspends inactive user account', () async {
			// First authenticate admin
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			expect(authResponse.user, isNotNull);
			expect(authResponse.user!.userType, 'admin');
			
			// Verify account is active before suspension
			final accountBefore = await mockGetAccountStatus('user-123');
			expect(accountBefore!.status, 'active');
			
			// Suspend the account
			final suspendResult = await mockSuspendAccount(
				adminId: authResponse.user!.id,
				userId: 'user-123',
			);
			
			expect(suspendResult, true);
			
			// Verify account is now suspended
			final accountAfter = await mockGetAccountStatus('user-123');
			expect(accountAfter!.status, 'suspended');
			expect(accountAfter.deactivatedAt, isNotNull);
		});

		test('Suspended account cannot login (access removed)', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			// Suspend account
			await mockSuspendAccount(adminId: authResponse.user!.id, userId: 'user-123');
			
			// Attempt login with suspended account should fail
			expect(
				() => mockAttemptLogin('inactive@student.edu', 'anypassword'),
				throwsException,
			);
		});

		test('Attempting to suspend non-existent account throws error', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			expect(
				() => mockSuspendAccount(adminId: authResponse.user!.id, userId: 'non-existent'),
				throwsException,
			);
		});

		test('Attempting to suspend already suspended account throws error', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			// Suspend account first time
			await mockSuspendAccount(adminId: authResponse.user!.id, userId: 'user-123');
			
			// Attempt to suspend again should throw error
			expect(
				() => mockSuspendAccount(adminId: authResponse.user!.id, userId: 'user-123'),
				throwsException,
			);
		});

		test('Multiple accounts can be suspended independently', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			// Suspend first account
			await mockSuspendAccount(adminId: authResponse.user!.id, userId: 'user-123');
			final account1 = await mockGetAccountStatus('user-123');
			expect(account1!.status, 'suspended');
			
			// Second account should still be active
			final account2 = await mockGetAccountStatus('user-456');
			expect(account2!.status, 'active');
			
			// Suspend second account
			await mockSuspendAccount(adminId: authResponse.user!.id, userId: 'user-456');
			final account2After = await mockGetAccountStatus('user-456');
			expect(account2After!.status, 'suspended');
		});

		test('Invalid admin credentials prevent account suspension', () async {
			expect(() => mockSignInWithPassword(email: 'admin@email.com', password: 'wrongpass'), throwsException);
		});
	});
}
