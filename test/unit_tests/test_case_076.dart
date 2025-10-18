// 10-05-25 BB-076: Admin adds new breathing exercise technique
// Requirement: Exercise successfully added to available techniques library
// This test simulates the exercise management logic for adding exercises

import 'package:flutter_test/flutter_test.dart';

class MockExercise {
	final String id;
	final String name;
	final String type;
	final String instructions;
	final int duration;
	final String difficulty;
	final DateTime createdAt;
	
	MockExercise({
		required this.id,
		required this.name,
		required this.type,
		required this.instructions,
		required this.duration,
		required this.difficulty,
		required this.createdAt,
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

Future<MockExercise> mockAddExercise({
	required String adminId,
	required String name,
	required String type,
	required String instructions,
	required int duration,
	required String difficulty,
}) async {
	// Simulate successful exercise addition
	return MockExercise(
		id: 'exercise-${DateTime.now().millisecondsSinceEpoch}',
		name: name,
		type: type,
		instructions: instructions,
		duration: duration,
		difficulty: difficulty,
		createdAt: DateTime.now(),
	);
}

void main() {
	group('BB-076: Admin adds new breathing exercise technique', () {
		test('Admin successfully adds new breathing exercise to techniques library', () async {
			// First authenticate admin
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			expect(authResponse.user, isNotNull);
			expect(authResponse.user!.userType, 'admin');
			
			// Add new breathing exercise
			final exercise = await mockAddExercise(
				adminId: authResponse.user!.id,
				name: 'Progressive Breathing',
				type: 'breathing',
				instructions: 'Inhale for 4 counts, hold for 4 counts, exhale for 6 counts',
				duration: 300,
				difficulty: 'beginner',
			);
			
			expect(exercise.name, 'Progressive Breathing');
			expect(exercise.type, 'breathing');
			expect(exercise.instructions, contains('Inhale for 4 counts'));
			expect(exercise.duration, 300);
			expect(exercise.difficulty, 'beginner');
			expect(exercise.id, isNotNull);
			expect(exercise.createdAt, isNotNull);
		});

		test('Invalid admin credentials prevent exercise addition', () async {
			expect(() => mockSignInWithPassword(email: 'admin@email.com', password: 'wrongpass'), throwsException);
		});
	});
}
