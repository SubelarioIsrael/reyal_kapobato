// AM-QM-02: Student submits their answer
// Requirement: The NLP will process the answer of the student and give insights and recommendations
// This test simulates the answer submission and NLP processing logic

import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String email;
	final String id;
	final String userType;
	MockUser({required this.email, required this.id, required this.userType});
}

class MockQuestionnaireResponse {
	final String responseId;
	final String userId;
	final int versionId;
	final int totalScore;
	final DateTime submissionTimestamp;
	
	MockQuestionnaireResponse({
		required this.responseId,
		required this.userId,
		required this.versionId,
		required this.totalScore,
		required this.submissionTimestamp,
	});
}

class MockAnswer {
	final String answerId;
	final String responseId;
	final int questionId;
	final int chosenAnswer;
	final String questionTextSnapshot;
	
	MockAnswer({
		required this.answerId,
		required this.responseId,
		required this.questionId,
		required this.chosenAnswer,
		required this.questionTextSnapshot,
	});
}

class MockNLPInsight {
	final String category;
	final String severity;
	final String insight;
	final List<String> recommendations;
	final double confidenceScore;
	
	MockNLPInsight({
		required this.category,
		required this.severity,
		required this.insight,
		required this.recommendations,
		required this.confidenceScore,
	});
}

class MockSubmissionResult {
	final MockQuestionnaireResponse response;
	final List<MockAnswer> answers;
	final MockNLPInsight nlpInsight;
	
	MockSubmissionResult({
		required this.response,
		required this.answers,
		required this.nlpInsight,
	});
}

Future<MockUser> mockAuthenticateStudent() async {
	// Use provided student credentials
	return MockUser(email: 'itzmethresh@gmail.com', id: 'student-123', userType: 'student');
}

Future<MockNLPInsight> mockProcessAnswersWithNLP({
	required List<Map<String, dynamic>> answers,
	required int totalScore,
}) async {
	// Simulate NLP processing based on total score
	String severity;
	String insight;
	List<String> recommendations;
	
	if (totalScore <= 9) {
		severity = 'Minimal';
		insight = 'Your responses indicate minimal symptoms of depression and anxiety. You appear to be managing well overall.';
		recommendations = [
			'Continue maintaining healthy habits',
			'Practice regular self-care activities',
			'Stay connected with supportive friends and family',
		];
	} else if (totalScore <= 19) {
		severity = 'Mild to Moderate';
		insight = 'Your responses suggest mild to moderate symptoms that may benefit from attention and support.';
		recommendations = [
			'Consider speaking with a counselor or therapist',
			'Practice stress management techniques',
			'Maintain regular sleep and exercise routines',
			'Reach out to campus mental health services',
		];
	} else {
		severity = 'Moderate to Severe';
		insight = 'Your responses indicate more significant symptoms that would benefit from professional support.';
		recommendations = [
			'Seek immediate support from campus counseling services',
			'Consider professional therapy or counseling',
			'Reach out to trusted friends, family, or support networks',
			'Contact crisis helplines if you have thoughts of self-harm',
		];
	}
	
	// Simulate confidence based on answer consistency
	double confidence = answers.length >= 16 ? 0.85 : 0.75;
	
	return MockNLPInsight(
		category: 'Depression and Anxiety Assessment',
		severity: severity,
		insight: insight,
		recommendations: recommendations,
		confidenceScore: confidence,
	);
}

Future<MockSubmissionResult> mockSubmitQuestionnaire({
	required String userId,
	required int versionId,
	required List<Map<String, dynamic>> answers,
}) async {
	// Validate answers are not empty
	if (answers.isEmpty) {
		throw Exception('Cannot submit questionnaire with no answers');
	}
	
	// Calculate total score
	final totalScore = answers.fold<int>(
		0,
		(sum, answer) => sum + (answer['chosenAnswer'] as int),
	);
	
	// Create response record
	final response = MockQuestionnaireResponse(
		responseId: 'response-${DateTime.now().millisecondsSinceEpoch}',
		userId: userId,
		versionId: versionId,
		totalScore: totalScore,
		submissionTimestamp: DateTime.now(),
	);
	
	// Create answer records
	final answerRecords = answers.map((answer) => MockAnswer(
		answerId: 'answer-${answer['questionId']}-${DateTime.now().millisecondsSinceEpoch}',
		responseId: response.responseId,
		questionId: answer['questionId'],
		chosenAnswer: answer['chosenAnswer'],
		questionTextSnapshot: answer['questionText'],
	)).toList();
	
	// Process with NLP
	final nlpInsight = await mockProcessAnswersWithNLP(
		answers: answers,
		totalScore: totalScore,
	);
	
	return MockSubmissionResult(
		response: response,
		answers: answerRecords,
		nlpInsight: nlpInsight,
	);
}

void main() {
	group('AM-QM-02: Student submits their answer', () {
		test('Student successfully submits answers and receives NLP insights for minimal symptoms', () async {
			final user = await mockAuthenticateStudent();
			
			// Simulate low-score answers (minimal symptoms)
			final answers = [
				{'questionId': 1, 'chosenAnswer': 0, 'questionText': 'Little interest or pleasure in doing things'},
				{'questionId': 2, 'chosenAnswer': 1, 'questionText': 'Feeling down, depressed, or hopeless'},
				{'questionId': 3, 'chosenAnswer': 0, 'questionText': 'Trouble falling or staying asleep'},
				// ...more questions with low scores
			];
			
			final result = await mockSubmitQuestionnaire(
				userId: user.id,
				versionId: 1,
				answers: answers,
			);
			
			expect(result.response.userId, user.id);
			expect(result.response.totalScore, 1); // 0+1+0
			expect(result.answers.length, 3);
			expect(result.nlpInsight.severity, 'Minimal');
			expect(result.nlpInsight.insight, contains('minimal symptoms'));
			expect(result.nlpInsight.recommendations.length, 3);
			expect(result.nlpInsight.confidenceScore, greaterThan(0.7));
		});

		test('Student submits answers with moderate symptoms and receives appropriate NLP recommendations', () async {
			final user = await mockAuthenticateStudent();
			
			// Simulate moderate-score answers (total should be <= 19 for mild to moderate)
			final answers = List.generate(16, (index) => {
				'questionId': index + 1,
				'chosenAnswer': 1, // All answers are 1, total = 16
				'questionText': 'Question ${index + 1} text',
			});
			
			final result = await mockSubmitQuestionnaire(
				userId: user.id,
				versionId: 1,
				answers: answers,
			);
			
			expect(result.response.totalScore, 16); // 16 questions × 1 point each
			expect(result.nlpInsight.severity, 'Mild to Moderate');
			expect(result.nlpInsight.insight, contains('mild to moderate symptoms'));
			expect(result.nlpInsight.recommendations, contains('Consider speaking with a counselor or therapist'));
			expect(result.nlpInsight.confidenceScore, 0.85);
		});

		test('Student submits answers with severe symptoms and receives crisis support recommendations', () async {
			final user = await mockAuthenticateStudent();
			
			// Simulate high-score answers (severe symptoms)
			final answers = List.generate(16, (index) => {
				'questionId': index + 1,
				'chosenAnswer': 3, // Maximum score for each question
				'questionText': 'Question ${index + 1} text',
			});
			
			final result = await mockSubmitQuestionnaire(
				userId: user.id,
				versionId: 1,
				answers: answers,
			);
			
			expect(result.response.totalScore, 48); // 16 questions × 3 points each
			expect(result.nlpInsight.severity, 'Moderate to Severe');
			expect(result.nlpInsight.insight, contains('significant symptoms'));
			expect(result.nlpInsight.recommendations, contains('Seek immediate support from campus counseling services'));
			expect(result.nlpInsight.recommendations, contains('Contact crisis helplines if you have thoughts of self-harm'));
		});

		test('NLP processing maintains data integrity and timestamps', () async {
			final user = await mockAuthenticateStudent();
			final submissionTime = DateTime.now();
			
			final answers = [
				{'questionId': 1, 'chosenAnswer': 2, 'questionText': 'Sample question 1'},
				{'questionId': 2, 'chosenAnswer': 1, 'questionText': 'Sample question 2'},
			];
			
			final result = await mockSubmitQuestionnaire(
				userId: user.id,
				versionId: 1,
				answers: answers,
			);
			
			// Verify response integrity
			expect(result.response.responseId, isNotNull);
			expect(result.response.submissionTimestamp.isAfter(submissionTime.subtract(const Duration(minutes: 1))), true);
			
			// Verify answer integrity
			for (var i = 0; i < result.answers.length; i++) {
				expect(result.answers[i].responseId, result.response.responseId);
				expect(result.answers[i].questionId, answers[i]['questionId']);
				expect(result.answers[i].chosenAnswer, answers[i]['chosenAnswer']);
				expect(result.answers[i].questionTextSnapshot, answers[i]['questionText']);
			}
			
			// Verify NLP insight structure
			expect(result.nlpInsight.category, isNotNull);
			expect(result.nlpInsight.confidenceScore, greaterThan(0.0));
			expect(result.nlpInsight.confidenceScore, lessThanOrEqualTo(1.0));
		});

		test('Empty answer submission fails validation', () async {
			final user = await mockAuthenticateStudent();
			
			expect(
				() => mockSubmitQuestionnaire(
					userId: user.id,
					versionId: 1,
					answers: [],
				),
				throwsA(predicate((e) => e.toString().contains('Cannot submit questionnaire with no answers'))),
			);
		});
	});
}