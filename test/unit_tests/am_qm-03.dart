// AM-QM-03: Admin selects a questionnaire version
// Requirement: Loads all the questions in the selected version
// This test simulates the version selection and question loading logic

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
	final int questionOrder;
	final DateTime createdAt;
	
	MockQuestion({
		required this.questionId,
		required this.questionText,
		required this.category,
		required this.isActive,
		required this.questionOrder,
		required this.createdAt,
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

// Mock database with versions and their questions
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

Map<int, List<MockQuestion>> _versionQuestionsDatabase = {
	1: [
		MockQuestion(
			questionId: 1,
			questionText: 'Little interest or pleasure in doing things',
			category: 'PHQ-9',
			isActive: true,
			createdAt: DateTime.now().subtract(const Duration(days: 30)),
			questionOrder: 1,
		),
		MockQuestion(
			questionId: 2,
			questionText: 'Feeling down, depressed, or hopeless',
			category: 'PHQ-9',
			isActive: true,
			createdAt: DateTime.now().subtract(const Duration(days: 30)),
			questionOrder: 2,
		),
		MockQuestion(
			questionId: 10,
			questionText: 'Feeling nervous, anxious, or on edge',
			category: 'GAD-7',
			isActive: true,
			createdAt: DateTime.now().subtract(const Duration(days: 30)),
			questionOrder: 10,
		),
	],
	2: [
		MockQuestion(
			questionId: 3,
			questionText: 'Over the last 2 weeks, how often have you had little interest in doing things?',
			category: 'PHQ-9',
			isActive: true,
			createdAt: DateTime.now().subtract(const Duration(days: 15)),
			questionOrder: 1,
		),
		MockQuestion(
			questionId: 4,
			questionText: 'Feeling nervous, anxious or on edge',
			category: 'GAD-7',
			isActive: true,
			createdAt: DateTime.now().subtract(const Duration(days: 15)),
			questionOrder: 2,
		),
	],
};

Future<MockUser> mockAuthenticateAdmin() async {
	// Use provided admin credentials
	return MockUser(email: 'admin@email.com', id: 'admin-123', userType: 'admin');
}

Future<List<MockQuestionnaireVersion>> mockLoadAllVersions({required String adminId}) async {
	return _versionDatabase.values.toList()
		..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
}

Future<List<MockQuestion>> mockLoadQuestionsForVersion({
	required String adminId,
	required int versionId,
}) async {
	final questions = _versionQuestionsDatabase[versionId] ?? [];
	// Sort by question order
	questions.sort((a, b) => a.questionOrder.compareTo(b.questionOrder));
	return questions;
}

Future<MockQuestionnaireVersion?> mockGetVersionDetails({
	required String adminId,
	required int versionId,
}) async {
	return _versionDatabase[versionId];
}

void main() {
	group('AM-QM-03: Admin selects a questionnaire version', () {
		test('Admin successfully selects version and loads all questions', () async {
			final admin = await mockAuthenticateAdmin();
			
			// Load available versions
			final versions = await mockLoadAllVersions(adminId: admin.id);
			expect(versions.length, 2);
			
			// Select version 1
			final selectedVersionId = versions[1].versionId; // v1 (older but active)
			final questions = await mockLoadQuestionsForVersion(
				adminId: admin.id,
				versionId: selectedVersionId,
			);
			
			expect(questions.length, 3);
			expect(questions[0].questionOrder, 1);
			expect(questions[1].questionOrder, 2);
			expect(questions[2].questionOrder, 10);
			expect(questions[0].category, 'PHQ-9');
			expect(questions[1].category, 'PHQ-9');
			expect(questions[2].category, 'GAD-7');
		});

		test('Admin selects different version and gets different questions', () async {
			final admin = await mockAuthenticateAdmin();
			
			// Select version 2
			final questions = await mockLoadQuestionsForVersion(
				adminId: admin.id,
				versionId: 2,
			);
			
			expect(questions.length, 2);
			expect(questions[0].questionId, 3);
			expect(questions[1].questionId, 4);
			expect(questions[0].questionText, contains('Over the last 2 weeks'));
			expect(questions[1].category, 'GAD-7');
		});

		test('Questions are loaded in correct order by question_order', () async {
			final admin = await mockAuthenticateAdmin();
			
			final questions = await mockLoadQuestionsForVersion(
				adminId: admin.id,
				versionId: 1,
			);
			
			// Verify ordering
			for (int i = 0; i < questions.length - 1; i++) {
				expect(
					questions[i].questionOrder,
					lessThanOrEqualTo(questions[i + 1].questionOrder),
				);
			}
		});

		test('Admin can view version details along with questions', () async {
			final admin = await mockAuthenticateAdmin();
			
			final versionDetails = await mockGetVersionDetails(
				adminId: admin.id,
				versionId: 1,
			);
			final questions = await mockLoadQuestionsForVersion(
				adminId: admin.id,
				versionId: 1,
			);
			
			expect(versionDetails, isNotNull);
			expect(versionDetails!.versionName, 'Student Mental Health Questionnaire v1');
			expect(versionDetails.isActive, true);
			expect(questions.length, 3);
		});

		test('Non-existent version returns empty question list', () async {
			final admin = await mockAuthenticateAdmin();
			
			final questions = await mockLoadQuestionsForVersion(
				adminId: admin.id,
				versionId: 999, // Non-existent version
			);
			
			expect(questions.length, 0);
		});

		test('Questions maintain their metadata when loaded', () async {
			final admin = await mockAuthenticateAdmin();
			
			final questions = await mockLoadQuestionsForVersion(
				adminId: admin.id,
				versionId: 1,
			);
			
			for (var question in questions) {
				expect(question.questionId, isNotNull);
				expect(question.questionText, isNotEmpty);
				expect(question.category, isIn(['PHQ-9', 'GAD-7']));
				expect(question.isActive, true);
				expect(question.createdAt, isNotNull);
				expect(question.questionOrder, greaterThan(0));
			}
		});

		test('Admin can switch between versions and load different question sets', () async {
			final admin = await mockAuthenticateAdmin();
			
			// Load questions from version 1
			final questionsV1 = await mockLoadQuestionsForVersion(
				adminId: admin.id,
				versionId: 1,
			);
			
			// Load questions from version 2
			final questionsV2 = await mockLoadQuestionsForVersion(
				adminId: admin.id,
				versionId: 2,
			);
			
			// Verify different question sets
			expect(questionsV1.length, 3);
			expect(questionsV2.length, 2);
			expect(questionsV1[0].questionId, isNot(questionsV2[0].questionId));
		});

		test('Both PHQ-9 and GAD-7 categories are represented in questions', () async {
			final admin = await mockAuthenticateAdmin();
			
			final questions = await mockLoadQuestionsForVersion(
				adminId: admin.id,
				versionId: 1,
			);
			
			final phq9Questions = questions.where((q) => q.category == 'PHQ-9').toList();
			final gad7Questions = questions.where((q) => q.category == 'GAD-7').toList();
			
			expect(phq9Questions.length, 2);
			expect(gad7Questions.length, 1);
		});
	});
}