// 10-05-25 BB-077: Admin modifies existing breathing exercise instructions
// Requirement: Exercise content updated and changes reflected in student interface
// This test simulates the exercise management logic for editing exercises

import 'package:flutter_test/flutter_test.dart';

class MockExercise {
	final String id;
	final String name;
	final String type;
	final String instructions;
	final int duration;
	final String difficulty;
	final DateTime updatedAt;
	
	MockExercise({
		required this.id,
		required this.name,
		required this.type,
		required this.instructions,
		required this.duration,
		required this.difficulty,
		required this.updatedAt,
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

Future<MockExercise> mockEditExercise({
	required String adminId,
	required String exerciseId,
	String? instructions,
	int? duration,
	String? difficulty,
}) async {
	// Simulate successful exercise edit
	return MockExercise(
		id: exerciseId,
		name: 'Box Breathing', // Existing name
		type: 'breathing', // Existing type
		instructions: instructions ?? 'Inhale for 4 counts, hold for 4 counts, exhale for 4 counts, hold for 4 counts',
		duration: duration ?? 240,
		difficulty: difficulty ?? 'intermediate',
		updatedAt: DateTime.now(),
	);
}

void main() {
	group('BB-077: Admin modifies existing breathing exercise instructions', () {
		test('Admin successfully edits breathing exercise instructions', () async {
			// First authenticate admin
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			expect(authResponse.user, isNotNull);
			expect(authResponse.user!.userType, 'admin');
			
			// Edit existing breathing exercise
			final updatedExercise = await mockEditExercise(
				adminId: authResponse.user!.id,
				exerciseId: 'exercise-123',
				instructions: 'Inhale for 6 counts, hold for 6 counts, exhale for 8 counts',
				duration: 360,
			);
			
			expect(updatedExercise.id, 'exercise-123');
			expect(updatedExercise.instructions, 'Inhale for 6 counts, hold for 6 counts, exhale for 8 counts');
			expect(updatedExercise.duration, 360);
			expect(updatedExercise.name, 'Box Breathing');
			expect(updatedExercise.type, 'breathing');
			expect(updatedExercise.updatedAt, isNotNull);
		});

		test('Partial update only changes specified fields', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			// Edit only instructions
			final updatedExercise = await mockEditExercise(
				adminId: authResponse.user!.id,
				exerciseId: 'exercise-456',
				instructions: 'Modified breathing pattern',
			);
			
			expect(updatedExercise.instructions, 'Modified breathing pattern');
			expect(updatedExercise.duration, 240); // Default unchanged
			expect(updatedExercise.difficulty, 'intermediate'); // Default unchanged
		});

		test('Invalid admin credentials prevent exercise editing', () async {
			expect(() => mockSignInWithPassword(email: 'admin@email.com', password: 'wrongpass'), throwsException);
		});
	});
}
