import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/question.dart';

class StudentQuestionnaireController {
  final ValueNotifier<List<Question>> questions = ValueNotifier([]);
  final ValueNotifier<int> currentQuestionIndex = ValueNotifier(0);
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<bool> isSubmitting = ValueNotifier(false);
  final ValueNotifier<bool> hasSubmitted = ValueNotifier(false);
  final ValueNotifier<int?> currentVersionId = ValueNotifier(null);

  final ValueNotifier<List<Question>> phq9Questions = ValueNotifier([]);
  final ValueNotifier<List<Question>> gad7Questions = ValueNotifier([]);
  final ValueNotifier<String> currentSection = ValueNotifier('');

  final ValueNotifier<bool> canTakeQuestionnaire = ValueNotifier(true);
  final ValueNotifier<DateTime?> lastSubmissionDate = ValueNotifier(null);
  final ValueNotifier<DateTime?> nextAvailableDate = ValueNotifier(null);

  void init() {
    checkBiWeeklyRestriction();
  }

  void dispose() {
    // Clean up notifiers if needed
  }

  Future<void> checkBiWeeklyRestriction() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        isLoading.value = false;
        canTakeQuestionnaire.value = false;
        return;
      }

      final lastResponse = await Supabase.instance.client
          .from('questionnaire_responses')
          .select('submission_timestamp')
          .eq('user_id', user.id)
          .order('submission_timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      if (lastResponse != null) {
        final lastSubmissionStr = lastResponse['submission_timestamp'] as String;
        lastSubmissionDate.value = DateTime.parse(lastSubmissionStr);

        final daysSinceLastSubmission =
            DateTime.now().difference(lastSubmissionDate.value!).inDays;
        final canTake = daysSinceLastSubmission >= 14;

        if (!canTake) {
          nextAvailableDate.value = lastSubmissionDate.value!.add(const Duration(days: 14));
        }

        canTakeQuestionnaire.value = canTake;
      } else {
        canTakeQuestionnaire.value = true;
      }

      if (canTakeQuestionnaire.value) {
        await loadActiveQuestionnaire();
      } else {
        isLoading.value = false;
      }
    } catch (e) {
      print('Error checking bi-weekly restriction: $e');
      isLoading.value = false;
      canTakeQuestionnaire.value = false;
    }
  }

  Future<void> loadActiveQuestionnaire() async {
    try {
      final versionData = await Supabase.instance.client
          .from('questionnaire_versions')
          .select()
          .eq('is_active', true)
          .single();

      currentVersionId.value = versionData['version_id'];

      final questionsData = await Supabase.instance.client
          .from('questionnaire_questions')
          .select('''
            question_id,
            question_order,
            questions (
              question_id,
              question_text,
              is_active,
              created_at,
              updated_at
            )
          ''')
          .eq('version_id', currentVersionId.value!)
          .order('question_order');

      final List<Question> fetchedQuestions = (questionsData as List)
          .map((data) => Question.fromMap({
                ...data['questions'],
                'options': [
                  'Not at all',
                  'Several days',
                  'More than half the days',
                  'Nearly every day'
                ],
              }))
          .toList();

      phq9Questions.value = fetchedQuestions.take(9).toList();
      gad7Questions.value = fetchedQuestions.skip(9).take(7).toList();

      questions.value = [...phq9Questions.value, ...gad7Questions.value];
      isLoading.value = false;
      updateProgress();
      updateCurrentSection();
    } catch (e) {
      print('Error loading questionnaire: $e');
      isLoading.value = false;
    }
  }

  String getCurrentSection() {
    if (currentQuestionIndex.value < phq9Questions.value.length) {
      return 'PHQ-9: Depression Screening';
    } else {
      return 'GAD-7: Anxiety Screening';
    }
  }

  void updateProgress() {
    progress.value = (currentQuestionIndex.value + 1) / questions.value.length;
  }

  void updateCurrentSection() {
    currentSection.value = getCurrentSection();
  }

  void selectAnswer(int selectedIndex) {
    questions.value[currentQuestionIndex.value].selectedOption = selectedIndex;
  }

  void nextQuestion() {
    if (currentQuestionIndex.value < questions.value.length - 1) {
      currentQuestionIndex.value++;
      updateProgress();
      updateCurrentSection();
    }
  }

  Future<Map<String, dynamic>> submitAnswers() async {
    if (isSubmitting.value || hasSubmitted.value) {
      return {'success': false, 'error': 'Submission already completed or in progress'};
    }

    isSubmitting.value = true;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not logged in'};
      }

      final totalScore = questions.value.fold<int>(
        0,
        (sum, question) => sum + (question.selectedOption ?? 0),
      );

      final responseData = await Supabase.instance.client
          .from('questionnaire_responses')
          .insert({
            'user_id': user.id,
            'version_id': currentVersionId.value,
            'total_score': totalScore,
          })
          .select()
          .single();

      final responseId = responseData['response_id'];

      for (final question in questions.value) {
        if (question.selectedOption != null) {
          await Supabase.instance.client.from('questionnaire_answers').insert({
            'response_id': responseId,
            'question_id': question.questionId,
            'chosen_answer': question.selectedOption,
            'question_text_snapshot': question.questionText,
          });
        }
      }

      hasSubmitted.value = true;
      return {
        'success': true,
        'responseId': responseId,
        'totalScore': totalScore,
      };
    } catch (e) {
      print('Error submitting answers: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      isSubmitting.value = false;
    }
  }
}
