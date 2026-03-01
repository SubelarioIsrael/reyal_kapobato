import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api/sentiment_app.dart';

class StudentAssessmentController {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get or create questionnaire summary
  Future<GetSummaryResult> getOrCreateSummary({
    required int responseId,
    required int totalScore,
  }) async {
    try {
      // Try to get existing summary
      final existingSummary = await _supabase
          .from('questionnaire_summaries')
          .select()
          .eq('response_id', responseId)
          .maybeSingle();

      if (existingSummary != null) {
        return GetSummaryResult(
          success: true,
          summaryData: existingSummary,
        );
      }

      // Create new summary using sentiment analysis
      final severityLevel = _determineSeverityLevel(totalScore);
      final insights = await _generateInsightsWithSentiment(responseId, severityLevel);
      final recommendations = _generateRecommendations(severityLevel);
      final breathingExerciseId = await _selectBreathingExercise(severityLevel);

      final newSummary = await _supabase
          .from('questionnaire_summaries')
          .insert({
            'response_id': responseId,
            'severity_level': severityLevel,
            'insights': insights,
            'recommendations': recommendations,
            'breathing_exercise_id': breathingExerciseId,
          })
          .select()
          .single();

      return GetSummaryResult(
        success: true,
        summaryData: newSummary,
      );
    } catch (e) {
      print('Error getting/creating summary: $e');
      return GetSummaryResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get breathing exercise by ID
  Future<GetBreathingExerciseResult> getBreathingExercise(int exerciseId) async {
    try {
      final exercise = await _supabase
          .from('breathing_exercises')
          .select()
          .eq('id', exerciseId)
          .single();

      return GetBreathingExerciseResult(
        success: true,
        exerciseData: exercise,
      );
    } catch (e) {
      print('Error getting breathing exercise: $e');
      return GetBreathingExerciseResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load questionnaire history for current user
  Future<LoadHistoryResult> loadQuestionnaireHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return LoadHistoryResult(
          success: false,
          errorMessage: 'User not authenticated',
        );
      }

      final data = await _supabase
          .from('questionnaire_responses')
          .select('''
            *,
            questionnaire_summaries (
              severity_level,
              insights,
              recommendations
            )
          ''')
          .eq('user_id', user.id)
          .order('submission_timestamp', ascending: false);

      return LoadHistoryResult(
        success: true,
        responses: List<Map<String, dynamic>>.from(data),
      );
    } catch (e) {
      print('Error loading questionnaire history: $e');
      return LoadHistoryResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  String _determineSeverityLevel(int totalScore) {
    // For combined PHQ-9 (0-27) and GAD-7 (0-21) = total max score of 48
    // Using more conservative thresholds for supportive approach
    if (totalScore <= 7) return 'mild'; // 0-15% of max score
    if (totalScore <= 14) return 'moderate'; // 16-30% of max score  
    if (totalScore <= 24) return 'severe'; // 31-50% of max score
    return 'critical'; // >50% of max score
  }

  Future<String> _generateInsightsWithSentiment(int responseId, String severityLevel) async {
    try {
      // Fetch all questions and answers for this response
      final answers = await _supabase
          .from('questionnaire_answers')
          .select('question_text_snapshot, chosen_answer')
          .eq('response_id', responseId)
          .order('answer_id');

      if (answers.isEmpty) {
        // If no answers found, use static insights
        print('No answers found, using static insights');
        return _generateInsights(severityLevel);
      }

      // Convert answers to text format for sentiment analysis
      final List<String> answerTexts = [];
      const answerOptions = [
        'Not at all',
        'Several days',
        'More than half the days',
        'Nearly every day'
      ];

      for (final answer in answers) {
        final questionText = answer['question_text_snapshot'] as String;
        final chosenAnswer = answer['chosen_answer'] as int;
        final answerText = answerOptions[chosenAnswer];

        answerTexts.add('$questionText - $answerText');
      }

      // Combine all questions and answers into a single text
      final combinedText = answerTexts.join('. ');

      // Try to analyze sentiment with a timeout
      // 30 s: the periodic warmup on home-page init keeps the Render server
      // alive, so cold-boot scenarios are rare; 30 s covers edge cases.
      final sentimentResult = await analyzeSentiment(combinedText).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('Sentiment analysis timed out, using static insights');
          throw TimeoutException('Sentiment API timed out');
        },
      );

      // Debug: Print the API response to understand the structure
      print('Sentiment analysis result: $sentimentResult');

      // Extract the "thought" from the sentiment analysis result
      // Try different possible field names that the API might return
      String? thought = sentimentResult['thought'] as String? ??
          sentimentResult['insight'] as String? ??
          sentimentResult['analysis'] as String? ??
          sentimentResult['summary'] as String? ??
          sentimentResult['result'] as String? ??
          sentimentResult['response'] as String? ??
          sentimentResult['reflection'] as String?;

      // If no specific field is found, try to get any string value from the response
      if (thought == null || thought.isEmpty) {
        // Look for any string value in the response
        for (final key in sentimentResult.keys) {
          final value = sentimentResult[key];
          if (value is String && value.isNotEmpty && !value.contains('Error:') && !value.contains('429')) {
            thought = value;
            break;
          }
        }
      }

      // If AI analysis failed or returned empty, use static insights
      if (thought == null || thought.isEmpty || thought.contains('Error:') || thought.contains('429')) {
        print('AI analysis failed or returned empty/error, using static insights');
        return _generateInsights(severityLevel);
      }

      return thought;
    } catch (e) {
      print('Error generating insights with sentiment analysis: $e');
      // Fallback to static insights based on severity level
      return _generateInsights(severityLevel);
    }
  }

  String _generateInsights(String severityLevel) {
    switch (severityLevel) {
      case 'mild':
        return 'Your responses indicate some symptoms that may occasionally affect your daily life. These experiences are manageable with good self-care strategies. Consider incorporating stress management techniques and maintaining social connections.';
      case 'moderate':
        return 'Your responses suggest you are experiencing symptoms that may be impacting your daily functioning and well-being. These feelings are valid and treatable. Consider reaching out to support services and practicing regular self-care activities.';
      case 'severe':
        return 'Your responses indicate significant symptoms that may be substantially affecting your daily life and well-being. Please know that you are not alone and that effective help is available. We strongly encourage you to connect with campus counseling services or a mental health professional.';
      case 'critical':
        return 'Your responses indicate very significant symptoms. We strongly urge you to seek immediate professional support. Campus counseling services and crisis resources are available to help you. Please know that seeking help is a sign of strength.';
      default:
        return 'Thank you for completing the assessment. Based on your responses, we recommend continuing to monitor your mental health and practicing self-care.';
    }
  }

  String _generateRecommendations(String severityLevel) {
    switch (severityLevel) {
      case 'mild':
        return '• Practice the recommended breathing exercises regularly\n• Maintain a consistent daily routine\n• Engage in physical activity and outdoor time\n• Connect with supportive friends or family members\n• Use campus resources like study groups or recreational activities\n• Consider speaking with a counselor if symptoms persist';
      case 'moderate':
        return '• Practice the recommended breathing exercises daily\n• Consider scheduling a consultation with campus counseling services\n• Reach out to your support network regularly\n• Maintain healthy sleep and eating habits\n• Use the mood tracking features in the app\n• Explore stress reduction techniques like mindfulness or meditation';
      case 'severe':
        return '• We strongly recommend connecting with campus counseling services\n• Practice the recommended breathing exercises multiple times daily\n• Reach out to trusted friends, family, or mentors for support\n• Use crisis resources if you need immediate support\n• Consider joining a support group\n• Prioritize basic self-care: sleep, nutrition, and gentle movement\n• Remember that seeking help is a sign of strength, not weakness';
      case 'critical':
        return '• URGENT: Please connect with campus counseling services or crisis resources immediately\n• National Suicide Prevention Lifeline: 988\n• Crisis Text Line: Text HOME to 741741\n• Reach out to trusted individuals for immediate support\n• Practice breathing exercises to help manage acute distress\n• Remember: You are not alone, and help is available 24/7';
      default:
        return '• Practice regular self-care and stress management\n• Maintain healthy lifestyle habits\n• Stay connected with your support network\n• Reach out for help when needed';
    }
  }

  Future<int?> _selectBreathingExercise(String severityLevel) async {
    try {
      // Get all breathing exercises
      final exercises = await _supabase
          .from('breathing_exercises')
          .select()
          .inFilter(
              'name', ['4-7-8 Breathing', 'Box Breathing', 'Deep Breathing']);

      if (exercises.isEmpty) {
        print('No breathing exercises found');
        return null;
      }

      // Select appropriate exercise based on severity
      switch (severityLevel) {
        case 'mild':
          return exercises.firstWhere(
            (e) => e['name'] == 'Deep Breathing',
            orElse: () => exercises.first,
          )['id'];
        case 'moderate':
          return exercises.firstWhere(
            (e) => e['name'] == 'Box Breathing',
            orElse: () => exercises.first,
          )['id'];
        case 'severe':
        case 'critical':
          return exercises.firstWhere(
            (e) => e['name'] == '4-7-8 Breathing',
            orElse: () => exercises.first,
          )['id'];
        default:
          return exercises.first['id'];
      }
    } catch (e) {
      print('Error selecting breathing exercise: $e');
      return null;
    }
  }
}

class GetSummaryResult {
  final bool success;
  final Map<String, dynamic>? summaryData;
  final String? errorMessage;

  GetSummaryResult({
    required this.success,
    this.summaryData,
    this.errorMessage,
  });
}

class GetBreathingExerciseResult {
  final bool success;
  final Map<String, dynamic>? exerciseData;
  final String? errorMessage;

  GetBreathingExerciseResult({
    required this.success,
    this.exerciseData,
    this.errorMessage,
  });
}

class LoadHistoryResult {
  final bool success;
  final List<Map<String, dynamic>>? responses;
  final String? errorMessage;

  LoadHistoryResult({
    required this.success,
    this.responses,
    this.errorMessage,
  });
}
