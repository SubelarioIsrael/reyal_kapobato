// AM-QM-01: A logged-in student's questionnaire displays
// Requirement: Loads all the questionnaire created by the Admin
// This test simulates the questionnaire loading logic for students

import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String email;
	final String id;
	final String userType;
	MockUser({required this.email, required this.id, required this.userType});
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

Future<MockUser> mockAuthenticateStudent() async {
	// Use provided student credentials
	return MockUser(email: 'itzmethresh@gmail.com', id: 'student-123', userType: 'student');
}

Future<MockQuestionnaireVersion?> mockLoadActiveQuestionnaire() async {
  try {
    return _versionDatabase.values.firstWhere((v) => v.isActive);
  } catch (_) {
    return null;
  }
}

Future<List<MockQuestion>> mockLoadQuestions(int versionId) async {
	return _questionDatabase[versionId] ?? [];
}

Future<bool> mockCheckBiWeeklyRestriction(String userId) async {
	return true;
}

void main() {
	group('AM-QM-01: A logged-in student\'s questionnaire displays', () {
		test('Student loads active questionnaire and questions', () async {
			final user = await mockAuthenticateStudent();
			final canTake = await mockCheckBiWeeklyRestriction(user.id);
			expect(canTake, true);

			final activeVersion = await mockLoadActiveQuestionnaire();
			expect(activeVersion, isNotNull);
			expect(activeVersion!.isActive, true);

			final questions = await mockLoadQuestions(activeVersion.versionId);
			expect(questions.length, 3);
			expect(questions[0].category, 'PHQ-9');
			expect(questions[2].category, 'GAD-7');
			expect(questions[0].options.length, 4);
		});
	});
}