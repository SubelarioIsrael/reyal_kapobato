// AM-QM-01: A logged-in student's questionnaire displays
// Requirement: Loads all the questionnaire created by the Admin
// This test simulates the questionnaire loading logic for students

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

class MockQuestion {
	final int questionId;
	final String questionText;
	final String category;
	final bool isActive;
	final List<String> options;
	
	MockQuestion({
		required this.questionId,
		required this.questionText,
		required this.category,
		required this.isActive,
		required this.options,
	});
}

class MockQuestionnaireVersion {
	final int versionId;
	final String versionName;
	final bool isActive;
	final DateTime createdAt;
	
	MockQuestionnaireVersion({
		required this.versionId,
		required this.versionName,
		required this.isActive,
		required this.createdAt,
	});
}

// Mock database
Map<int, MockQuestionnaireVersion> _versionDatabase = {
	1: MockQuestionnaireVersion(
		versionId: 1,
		versionName: 'Student Mental Health Questionnaire v1',
		isActive: true,
		createdAt: DateTime.now().subtract(const Duration(days: 30)),
	),
	2: MockQuestionnaireVersion(
		versionId: 2,
		versionName: 'Student Mental Health Questionnaire v2',
		isActive: false,
		createdAt: DateTime.now().subtract(const Duration(days: 15)),
	),
};

Map<int, List<MockQuestion>> _questionDatabase = {
	1: [
		MockQuestion(
			questionId: 1,
			questionText: 'Little interest or pleasure in doing things',
			category: 'PHQ-9',
			isActive: true,
			options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
		),
		MockQuestion(
			questionId: 2,
			questionText: 'Feeling down, depressed, or hopeless',
			category: 'PHQ-9',
			isActive: true,
			options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
		),
		MockQuestion(
			questionId: 10,
			questionText: 'Feeling nervous, anxious, or on edge',
			category: 'GAD-7',
			isActive: true,
			options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
		),
	],
};

Future<MockAuthResponse> mockSignInWithPassword({required String email, required String password}) async {
	// Simulate student credentials
	if (email == 'student@college.edu' && password == 'studentpass') {
		return MockAuthResponse(MockUser(email: email, id: 'student-id', userType: 'student', emailConfirmedAt: DateTime.now()));
	}
	throw Exception('Invalid login credentials');
}

Future<MockQuestionnaireVersion?> mockLoadActiveQuestionnaire({required String userId}) async {
	// Find active version
	for (var version in _versionDatabase.values) {
		if (version.isActive) {
			return version;
		}
	}
	return null;
}

Future<List<MockQuestion>> mockLoadQuestions({required int versionId}) async {
	return _questionDatabase[versionId] ?? [];
}

Future<bool> mockCheckBiWeeklyRestriction({required String userId}) async {
	// Simulate that student can take questionnaire (no recent submission)
	return true;
}

void main() {
	group('AM-QM-01: A logged-in student\'s questionnaire displays', () {
		test('Student successfully loads active questionnaire created by admin', () async {
			// First authenticate student
			final authResponse = await mockSignInWithPassword(
				email: 'student@college.edu', 
				password: 'studentpass'
			);
			expect(authResponse.user, isNotNull);
			expect(authResponse.user!.userType, 'student');
			
			// Check bi-weekly restriction
			final canTakeQuestionnaire = await mockCheckBiWeeklyRestriction(
				userId: authResponse.user!.id
			);
			expect(canTakeQuestionnaire, true);
			
			// Load active questionnaire version
			final activeVersion = await mockLoadActiveQuestionnaire(
				userId: authResponse.user!.id
			);
			expect(activeVersion, isNotNull);
			expect(activeVersion!.isActive, true);
			expect(activeVersion.versionName, 'Student Mental Health Questionnaire v1');
			
			// Load questions for active version
			final questions = await mockLoadQuestions(versionId: activeVersion.versionId);
			expect(questions.length, 3);
			expect(questions[0].category, 'PHQ-9');
			expect(questions[1].category, 'PHQ-9');
			expect(questions[2].category, 'GAD-7');
			expect(questions[0].options.length, 4);
		});

		test('Student questionnaire loads PHQ-9 and GAD-7 questions in correct order', () async {
			final authResponse = await mockSignInWithPassword(
				email: 'student@college.edu', 
				password: 'studentpass'
			);
			
			final activeVersion = await mockLoadActiveQuestionnaire(
				userId: authResponse.user!.id
			);
			final questions = await mockLoadQuestions(versionId: activeVersion!.versionId);
			
			// Verify PHQ-9 questions come first
			final phq9Questions = questions.where((q) => q.category == 'PHQ-9').toList();
			final gad7Questions = questions.where((q) => q.category == 'GAD-7').toList();
			
			expect(phq9Questions.length, 2);
			expect(gad7Questions.length, 1);
			expect(phq9Questions[0].questionText, contains('interest or pleasure'));
			expect(phq9Questions[1].questionText, contains('down, depressed'));
			expect(gad7Questions[0].questionText, contains('nervous, anxious'));
		});

		test('No active questionnaire returns null', () async {
			// Temporarily deactivate all versions by creating new map
			final originalDatabase = Map<int, MockQuestionnaireVersion>.from(_versionDatabase);
			_versionDatabase.clear();
			_versionDatabase[1] = MockQuestionnaireVersion(
				versionId: 1,
				versionName: 'Student Mental Health Questionnaire v1',
				isActive: false,
				createdAt: DateTime.now().subtract(const Duration(days: 30)),
			);
			
			final authResponse = await mockSignInWithPassword(
				email: 'student@college.edu', 
				password: 'studentpass'
			);
			
			final activeVersion = await mockLoadActiveQuestionnaire(
				userId: authResponse.user!.id
			);
			expect(activeVersion, isNull);
			
			// Restore original database
			_versionDatabase = originalDatabase;
		});

		test('All questions have required response options', () async {
			final authResponse = await mockSignInWithPassword(
				email: 'student@college.edu', 
				password: 'studentpass'
			);
			
			final activeVersion = await mockLoadActiveQuestionnaire(
				userId: authResponse.user!.id
			);
			
			// Add null check to prevent error
			if (activeVersion != null) {
				final questions = await mockLoadQuestions(versionId: activeVersion.versionId);
				
				for (var question in questions) {
					expect(question.options.length, 4);
					expect(question.options[0], 'Not at all');
					expect(question.options[1], 'Several days');
					expect(question.options[2], 'More than half the days');
					expect(question.options[3], 'Nearly every day');
					expect(question.isActive, true);
				}
			} else {
				// If no active version, skip this test part
				expect(activeVersion, isNotNull, reason: 'Active version should exist for this test');
			}
		});

		test('Invalid student credentials prevent questionnaire loading', () async {
			expect(
				() => mockSignInWithPassword(email: 'student@college.edu', password: 'wrongpass'),
				throwsException,
			);
		});
	});
}