// 10-05-25 BB-078: Admin removes ineffective breathing exercise
// Requirement: Exercise successfully removed from available options
// This test simulates the exercise management logic for deleting exercises

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

// Mock database to track exercises
Map<String, bool> _exerciseDatabase = {
	'exercise-123': true,
	'exercise-456': true,
	'exercise-789': true,
};

Future<MockAuthResponse> mockSignInWithPassword({required String email, required String password}) async {
	// Simulate admin credentials
	if (email == 'admin@email.com' && password == 'adminadmin') {
		return MockAuthResponse(MockUser(email: email, id: 'admin-id', userType: 'admin', emailConfirmedAt: DateTime.now()));
	}
	throw Exception('Invalid login credentials');
}

Future<bool> mockDeleteExercise({
	required String adminId,
	required String exerciseId,
}) async {
	// Check if exercise exists
	if (!_exerciseDatabase.containsKey(exerciseId) || !_exerciseDatabase[exerciseId]!) {
		throw Exception('Exercise not found');
	}
	
	// Simulate successful deletion
	_exerciseDatabase[exerciseId] = false;
	return true;
}

Future<bool> mockCheckExerciseExists(String exerciseId) async {
	return _exerciseDatabase[exerciseId] ?? false;
}

void main() {
	group('BB-078: Admin removes ineffective breathing exercise', () {
		setUp(() {
			// Reset database state before each test
			_exerciseDatabase = {
				'exercise-123': true,
				'exercise-456': true,
				'exercise-789': true,
			};
		});

		test('Admin successfully removes breathing exercise from available options', () async {
			// First authenticate admin
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			expect(authResponse.user, isNotNull);
			expect(authResponse.user!.userType, 'admin');
			
			// Verify exercise exists before deletion
			final existsBefore = await mockCheckExerciseExists('exercise-123');
			expect(existsBefore, true);
			
			// Delete the exercise
			final deleteResult = await mockDeleteExercise(
				adminId: authResponse.user!.id,
				exerciseId: 'exercise-123',
			);
			
			expect(deleteResult, true);
			
			// Verify exercise no longer exists
			final existsAfter = await mockCheckExerciseExists('exercise-123');
			expect(existsAfter, false);
		});

		test('Attempting to delete non-existent exercise throws error', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			expect(
				() => mockDeleteExercise(adminId: authResponse.user!.id, exerciseId: 'non-existent'),
				throwsException,
			);
		});

		test('Multiple exercises can be deleted independently', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			// Delete first exercise
			await mockDeleteExercise(adminId: authResponse.user!.id, exerciseId: 'exercise-123');
			expect(await mockCheckExerciseExists('exercise-123'), false);
			expect(await mockCheckExerciseExists('exercise-456'), true);
			
			// Delete second exercise
			await mockDeleteExercise(adminId: authResponse.user!.id, exerciseId: 'exercise-456');
			expect(await mockCheckExerciseExists('exercise-456'), false);
			expect(await mockCheckExerciseExists('exercise-789'), true);
		});

		test('Invalid admin credentials prevent exercise deletion', () async {
			expect(() => mockSignInWithPassword(email: 'admin@email.com', password: 'wrongpass'), throwsException);
		});
	});
}
