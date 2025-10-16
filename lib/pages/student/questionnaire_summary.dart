import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../services/api/sentiment_app.dart';

class QuestionnaireSummary extends StatefulWidget {
  final int responseId;
  final int totalScore;

  const QuestionnaireSummary({
    super.key,
    required this.responseId,
    required this.totalScore,
  });

  @override
  State<QuestionnaireSummary> createState() => _QuestionnaireSummaryState();
}

class _QuestionnaireSummaryState extends State<QuestionnaireSummary> {
  bool isLoading = true;
  Map<String, dynamic>? summaryData;
  Map<String, dynamic>? breathingExercise;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      // Get or create summary
      final summary = await _getOrCreateSummary();
      setState(() {
        summaryData = summary;
        isLoading = false;
      });

      // Load breathing exercise details
      if (summary['breathing_exercise_id'] != null) {
        final exercise = await Supabase.instance.client
            .from('breathing_exercises')
            .select()
            .eq('id', summary['breathing_exercise_id'])
            .single();
        setState(() {
          breathingExercise = exercise;
        });
      }
    } catch (e) {
      print('Error loading summary: $e');
      setState(() => isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _getOrCreateSummary() async {
    // Try to get existing summary
    final existingSummary = await Supabase.instance.client
        .from('questionnaire_summaries')
        .select()
        .eq('response_id', widget.responseId)
        .maybeSingle();

    if (existingSummary != null) {
      return existingSummary;
    }

    // Create new summary using sentiment analysis
    final severityLevel = _determineSeverityLevel(widget.totalScore);
    final insights = await _generateInsightsWithSentiment();
    final recommendations = _generateRecommendations(severityLevel);
    final breathingExerciseId = await _selectBreathingExercise(severityLevel);

    final newSummary = await Supabase.instance.client
        .from('questionnaire_summaries')
        .insert({
          'response_id': widget.responseId,
          'severity_level': severityLevel,
          'insights': insights,
          'recommendations': recommendations,
          'breathing_exercise_id': breathingExerciseId,
        })
        .select()
        .single();

    return newSummary;
  }

  String _determineSeverityLevel(int totalScore) {
    // For combined PHQ-9 (0-27) and GAD-7 (0-21) = total max score of 48
    // Using more conservative thresholds for supportive approach
    if (totalScore <= 7) return 'mild'; // 0-15% of max score
    if (totalScore <= 14) return 'moderate'; // 16-30% of max score  
    if (totalScore <= 24) return 'severe'; // 31-50% of max score
    return 'critical'; // >50% of max score
  }

  Future<String> _generateInsightsWithSentiment() async {
    try {
      // Fetch all questions and answers for this response
      final answers = await Supabase.instance.client
          .from('questionnaire_answers')
          .select('question_text_snapshot, chosen_answer')
          .eq('response_id', widget.responseId)
          .order('answer_id');

      if (answers.isEmpty) {
        // If no answers found, use static insights
        return _generateInsights(_determineSeverityLevel(widget.totalScore));
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

      // Analyze sentiment
      final sentimentResult = await analyzeSentiment(combinedText);

      // Debug: Print the API response to understand the structure
      print('Sentiment analysis result: $sentimentResult');

      // Extract the "thought" from the sentiment analysis result
      // Try different possible field names that the API might return
      String? thought = sentimentResult['thought'] as String? ??
          sentimentResult['insight'] as String? ??
          sentimentResult['analysis'] as String? ??
          sentimentResult['summary'] as String? ??
          sentimentResult['result'] as String? ??
          sentimentResult['response'] as String?;

      // If no specific field is found, try to get any string value from the response
      if (thought == null || thought.isEmpty) {
        // Look for any string value in the response
        for (final key in sentimentResult.keys) {
          final value = sentimentResult[key];
          if (value is String && value.isNotEmpty) {
            thought = value;
            break;
          }
        }
      }

      // If AI analysis failed or returned empty, use static insights
      if (thought == null || thought.isEmpty) {
        print('AI analysis failed or returned empty, using static insights');
        return _generateInsights(_determineSeverityLevel(widget.totalScore));
      }

      return thought;
    } catch (e) {
      print('Error generating insights with sentiment analysis: $e');
      // Fallback to static insights based on severity level
      return _generateInsights(_determineSeverityLevel(widget.totalScore));
    }
  }

  String _generateInsights(String severityLevel) {
    switch (severityLevel) {
      case 'minimal':
        return 'Your responses suggest you are experiencing minimal symptoms that are common in daily life. This indicates good emotional well-being. Continue maintaining healthy habits and self-care practices to support your mental health.';
      case 'mild':
        return 'Your responses indicate some symptoms that may occasionally affect your daily life. These experiences are manageable with good self-care strategies. Consider incorporating stress management techniques and maintaining social connections.';
      case 'moderate':
        return 'Your responses suggest you are experiencing symptoms that may be impacting your daily functioning and well-being. These feelings are valid and treatable. Consider reaching out to support services and practicing regular self-care activities.';
      case 'elevated':
        return 'Your responses indicate significant symptoms that may be substantially affecting your daily life and well-being. Please know that you are not alone and that effective help is available. We strongly encourage you to connect with campus counseling services or a mental health professional.';
      default:
        return 'Thank you for completing the assessment. Based on your responses, we recommend continuing to monitor your mental health and practicing self-care.';
    }
  }

  String _generateRecommendations(String severityLevel) {
    switch (severityLevel) {
      case 'minimal':
        return '• Continue your current self-care practices\n• Maintain regular exercise and healthy sleep habits\n• Practice the recommended breathing exercises for stress management\n• Stay connected with friends and family\n• Consider keeping a mood journal to track patterns';
      case 'mild':
        return '• Practice the recommended breathing exercises regularly\n• Maintain a consistent daily routine\n• Engage in physical activity and outdoor time\n• Connect with supportive friends or family members\n• Use campus resources like study groups or recreational activities\n• Consider speaking with a counselor if symptoms persist';
      case 'moderate':
        return '• Practice the recommended breathing exercises daily\n• Consider scheduling a consultation with campus counseling services\n• Reach out to your support network regularly\n• Maintain healthy sleep and eating habits\n• Use the mood tracking features in the app\n• Explore stress reduction techniques like mindfulness or meditation';
      case 'elevated':
        return '• We strongly recommend connecting with campus counseling services\n• Practice the recommended breathing exercises multiple times daily\n• Reach out to trusted friends, family, or mentors for support\n• Use crisis resources if you need immediate support\n• Consider joining a support group\n• Prioritize basic self-care: sleep, nutrition, and gentle movement\n• Remember that seeking help is a sign of strength, not weakness';
      default:
        return '• Practice regular self-care and stress management\n• Maintain healthy lifestyle habits\n• Stay connected with your support network\n• Reach out for help when needed';
    }
  }

  Future<int?> _selectBreathingExercise(String severityLevel) async {
    try {
      // Get all breathing exercises
      final exercises = await Supabase.instance.client
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
        case 'minimal':
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
        case 'elevated':
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

  @override
  Widget build(BuildContext context) {
    const pastelBlue = Color.fromARGB(255, 242, 241, 248);
    const pastelPurple = Color(0xFFE0D4FD);

    if (isLoading) {
      return Scaffold(
        backgroundColor: pastelBlue,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (summaryData == null) {
      return Scaffold(
        backgroundColor: pastelBlue,
        body: Center(
          child: Text(
            'Error loading summary data',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF3A3A50),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(
        backgroundColor: pastelBlue,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF5D5D72)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text(
          "BreatheBetter",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: [
          const StudentNotificationButton(),
        ],
      ),
      drawer: const StudentDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 0),

                // Severity Level
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(summaryData!['severity_level']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getSeverityIcon(summaryData!['severity_level']),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Severity Level: ${summaryData!['severity_level'].toString().toUpperCase()}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Insights
                Text(
                  'Insights',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF7C83FD), width: 1),
                  ),
                  child: Text(
                    summaryData!['insights'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF3A3A50),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Recommendations
                Text(
                  'Recommendations',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF7C83FD), width: 1),
                  ),
                  child: Text(
                    summaryData!['recommendations'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF3A3A50),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Breathing Exercise
                if (breathingExercise != null) ...[
                  Text(
                    'Recommended Breathing Exercise',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      'student-breathing-exercises',
                      arguments: breathingExercise,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: pastelPurple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF7C83FD), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            breathingExercise!['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            breathingExercise!['description'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Action Buttons
                if (summaryData!['severity_level'] == 'elevated') ...[
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C83FD),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, 'student-counselors'),
                      child: Text(
                        'Connect with a Counselor',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Go Back Button
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, 'questionnaire-history'),
                        icon: const Icon(Icons.arrow_back,
                            color: Color(0xFF5D5D72)),
                        label: Text(
                          'Go Back to History',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF5D5D72),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFF5D5D72)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10), // Add some space between buttons

                    // Return to Home Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, 'student-home'),
                        icon: const Icon(Icons.home, color: Colors.white),
                        label: Text(
                          'Return to Home',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C83FD),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severityLevel) {
    switch (severityLevel) {
      case 'minimal':
        return Colors.green;
      case 'mild':
        return Colors.lightGreen;
      case 'moderate':
        return Colors.orange;
      case 'elevated':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severityLevel) {
    switch (severityLevel) {
      case 'minimal':
        return Icons.sentiment_very_satisfied;
      case 'mild':
        return Icons.sentiment_satisfied;
      case 'moderate':
        return Icons.sentiment_neutral;
      case 'elevated':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }
}
