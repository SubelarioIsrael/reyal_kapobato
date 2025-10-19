// AM-BWQ-06: Admin selects a category and added a question
// Requirement: Question successfully added on the selected version
// This test simulates the question addition logic for selected versions

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
	final DateTime createdAt;
	
	MockQuestion({
		required this.questionId,
		required this.questionText,
		required this.category,
		required this.isActive,
		required this.createdAt,
	});
}

class MockQuestionnaireQuestion {
	final int questionId;
	final int versionId;
	final int questionOrder;
	
	MockQuestionnaireQuestion({
		required this.questionId,
		required this.versionId,
		required this.questionOrder,
	});
}

class MockAddQuestionResult {
	final MockQuestion question;
	final MockQuestionnaireQuestion versionQuestion;
	
	MockAddQuestionResult({
		required this.question,
		required this.versionQuestion,
	});
}

// Mock database
Map<int, MockQuestion> _questionsDatabase = {};
Map<String, MockQuestionnaireQuestion> _versionQuestionsDatabase = {};
int _nextQuestionId = 100;

Future<MockUser> mockAuthenticateAdmin() async {
	return MockUser(email: 'admin@email.com', id: 'admin-123', userType: 'admin');
}

Future<MockAddQuestionResult> mockAddQuestionToVersion({
	required String adminId,
	required int versionId,
	required String questionText,
	required String category,
}) async {
	// Validate inputs
	if (questionText.trim().isEmpty) {
		throw Exception('Question text cannot be empty');
	}
	
	if (!['PHQ-9', 'GAD-7'].contains(category)) {
		throw Exception('Invalid category. Must be PHQ-9 or GAD-7');
	}
	
	// Create the question
	final question = MockQuestion(
		questionId: _nextQuestionId++,
		questionText: questionText.trim(),
		category: category,
		isActive: true,
		createdAt: DateTime.now(),
	);
	
	// Add to questions database
	_questionsDatabase[question.questionId] = question;
	
	// Get current question count for this version to determine order
	final currentQuestions = _versionQuestionsDatabase.values
		.where((vq) => vq.versionId == versionId)
		.length;
	
	// Add to version questions
	final versionQuestion = MockQuestionnaireQuestion(
		questionId: question.questionId,
		versionId: versionId,
		questionOrder: currentQuestions + 1,
	);
	
	_versionQuestionsDatabase['${versionId}_${question.questionId}'] = versionQuestion;
	
	return MockAddQuestionResult(
		question: question,
		versionQuestion: versionQuestion,
	);
}

Future<List<MockQuestion>> mockGetQuestionsForVersion({required int versionId}) async {
	final versionQuestions = _versionQuestionsDatabase.values
		.where((vq) => vq.versionId == versionId)
		.toList()
		..sort((a, b) => a.questionOrder.compareTo(b.questionOrder));
	
	return versionQuestions
		.map((vq) => _questionsDatabase[vq.questionId]!)
		.toList();
}

void main() {
	group('AM-BWQ-06: Admin selects a category and added a question', () {
		setUp(() {
			// Reset database before each test
			_questionsDatabase.clear();
			_versionQuestionsDatabase.clear();
			_nextQuestionId = 100;
		});

		test('Admin successfully adds PHQ-9 question to selected version', () async {
			final admin = await mockAuthenticateAdmin();
			
			final result = await mockAddQuestionToVersion(
				adminId: admin.id,
				versionId: 1,
				questionText: 'Trouble falling or staying asleep, or sleeping too much',
				category: 'PHQ-9',
			);
			
			expect(result.question.questionText, 'Trouble falling or staying asleep, or sleeping too much');
			expect(result.question.category, 'PHQ-9');
			expect(result.question.isActive, true);
			expect(result.question.questionId, 100);
			expect(result.versionQuestion.versionId, 1);
			expect(result.versionQuestion.questionOrder, 1);
		});

		test('Admin successfully adds GAD-7 question to selected version', () async {
			final admin = await mockAuthenticateAdmin();
			
			final result = await mockAddQuestionToVersion(
				adminId: admin.id,
				versionId: 2,
				questionText: 'Not being able to stop or control worrying',
				category: 'GAD-7',
			);
			
			expect(result.question.questionText, 'Not being able to stop or control worrying');
			expect(result.question.category, 'GAD-7');
			expect(result.question.isActive, true);
			expect(result.versionQuestion.versionId, 2);
		});

		test('Questions are added in correct order within version', () async {
			final admin = await mockAuthenticateAdmin();
			
			// Add first question
			final result1 = await mockAddQuestionToVersion(
				adminId: admin.id,
				versionId: 1,
				questionText: 'First question',
				category: 'PHQ-9',
			);
			
			// Add second question
			final result2 = await mockAddQuestionToVersion(
				adminId: admin.id,
				versionId: 1,
				questionText: 'Second question',
				category: 'GAD-7',
			);
			
			expect(result1.versionQuestion.questionOrder, 1);
			expect(result2.versionQuestion.questionOrder, 2);
			
			// Verify questions can be retrieved in order
			final questions = await mockGetQuestionsForVersion(versionId: 1);
			expect(questions.length, 2);
			expect(questions[0].questionText, 'First question');
			expect(questions[1].questionText, 'Second question');
		});

		test('Multiple categories can be added to same version', () async {
			final admin = await mockAuthenticateAdmin();
			
			// Add PHQ-9 question
			await mockAddQuestionToVersion(
				adminId: admin.id,
				versionId: 1,
				questionText: 'PHQ-9 question',
				category: 'PHQ-9',
			);
			
			// Add GAD-7 question
			await mockAddQuestionToVersion(
				adminId: admin.id,
				versionId: 1,
				questionText: 'GAD-7 question',
				category: 'GAD-7',
			);
			
			final questions = await mockGetQuestionsForVersion(versionId: 1);
			expect(questions.length, 2);
			
			final phq9Questions = questions.where((q) => q.category == 'PHQ-9').toList();
			final gad7Questions = questions.where((q) => q.category == 'GAD-7').toList();
			
			expect(phq9Questions.length, 1);
			expect(gad7Questions.length, 1);
		});

		test('Questions added to different versions are independent', () async {
			final admin = await mockAuthenticateAdmin();
			
			// Add question to version 1
			await mockAddQuestionToVersion(
				adminId: admin.id,
				versionId: 1,
				questionText: 'Version 1 question',
				category: 'PHQ-9',
			);
			
			// Add question to version 2
			await mockAddQuestionToVersion(
				adminId: admin.id,
				versionId: 2,
				questionText: 'Version 2 question',
				category: 'GAD-7',
			);
			
			final version1Questions = await mockGetQuestionsForVersion(versionId: 1);
			final version2Questions = await mockGetQuestionsForVersion(versionId: 2);
			
			expect(version1Questions.length, 1);
			expect(version2Questions.length, 1);
			expect(version1Questions[0].questionText, 'Version 1 question');
			expect(version2Questions[0].questionText, 'Version 2 question');
		});

		test('Empty question text fails validation', () async {
			final admin = await mockAuthenticateAdmin();
			
			expect(
				() => mockAddQuestionToVersion(
					adminId: admin.id,
					versionId: 1,
					questionText: '',
					category: 'PHQ-9',
				),
				throwsA(predicate((e) => e.toString().contains('Question text cannot be empty'))),
			);
		});

		test('Whitespace-only question text fails validation', () async {
			final admin = await mockAuthenticateAdmin();
			
			expect(
				() => mockAddQuestionToVersion(
					adminId: admin.id,
					versionId: 1,
					questionText: '   \t   ',
					category: 'PHQ-9',
				),
				throwsA(predicate((e) => e.toString().contains('Question text cannot be empty'))),
			);
		});

		test('Invalid category fails validation', () async {
			final admin = await mockAuthenticateAdmin();
			
			expect(
				() => mockAddQuestionToVersion(
					adminId: admin.id,
					versionId: 1,
					questionText: 'Valid question text',
					category: 'INVALID-CATEGORY',
				),
				throwsA(predicate((e) => e.toString().contains('Invalid category'))),
			);
		});

		test('Question text is trimmed when added', () async {
			final admin = await mockAuthenticateAdmin();
			
			final result = await mockAddQuestionToVersion(
				adminId: admin.id,
				versionId: 1,
				questionText: '  Question with spaces  ',
				category: 'PHQ-9',
			);
			
			expect(result.question.questionText, 'Question with spaces');
		});
	});
}
