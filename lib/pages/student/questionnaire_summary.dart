import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    // Create new summary based on score
    final severityLevel = _determineSeverityLevel(widget.totalScore);
    final insights = _generateInsights(severityLevel);
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
    // For a 10-question questionnaire with 0-4 scale (max score = 40)
    if (totalScore <= 10) return 'mild'; // 0-25% of max score
    if (totalScore <= 20) return 'moderate'; // 26-50% of max score
    if (totalScore <= 30) return 'severe'; // 51-75% of max score
    return 'critical'; // 76-100% of max score
  }

  String _generateInsights(String severityLevel) {
    switch (severityLevel) {
      case 'mild':
        return 'Your responses indicate that you are experiencing minimal symptoms of anxiety and depression. This is a good sign, but it\'s still important to maintain healthy coping strategies and monitor your mental well-being regularly.';
      case 'moderate':
        return 'Your responses suggest you are experiencing some symptoms of anxiety and depression. While these symptoms are not severe, they may be affecting your daily life. Regular self-care and stress management techniques can be helpful.';
      case 'severe':
        return 'Your responses indicate significant symptoms of anxiety and depression. These symptoms are likely impacting your daily functioning and well-being. Professional support and regular self-care practices are recommended.';
      case 'critical':
        return 'Your responses show severe symptoms of anxiety and depression. These symptoms are significantly affecting your daily life and may require immediate professional support. Please consider reaching out to a counselor or mental health professional.';
      default:
        return 'Based on your responses, we recommend monitoring your mental health and practicing self-care.';
    }
  }

  String _generateRecommendations(String severityLevel) {
    switch (severityLevel) {
      case 'mild':
        return '• Continue practicing self-care and stress management techniques\n• Maintain regular exercise and healthy sleep habits\n• Consider journaling to track your mood\n• Practice the recommended breathing exercises when feeling stressed';
      case 'moderate':
        return '• Practice the recommended breathing exercises regularly\n• Consider talking to a trusted friend or family member\n• Try to maintain a regular routine and healthy habits\n• Use the mood journal feature to track patterns\n• Consider speaking with a counselor if symptoms persist';
      case 'severe':
        return '• Practice the recommended breathing exercises daily\n• Consider speaking with a counselor\n• Reach out to your support network\n• Maintain a regular sleep schedule\n• Use the chatbot for immediate support when needed\n• Consider booking a counseling appointment';
      case 'critical':
        return '• Practice the recommended breathing exercises multiple times daily\n• We strongly recommend speaking with a counselor\n• Reach out to your support network\n• Use the chatbot for immediate support\n• Book a counseling appointment as soon as possible\n• Consider reaching out to emergency services if having thoughts of self-harm';
      default:
        return '• Practice regular self-care\n• Maintain healthy habits\n• Reach out for support when needed';
    }
  }

  Future<int?> _selectBreathingExercise(String severityLevel) async {
    // Get all breathing exercises
    final exercises = await Supabase.instance.client
        .from('breathing_exercises')
        .select()
        .inFilter(
            'name', ['4-7-8 Breathing', 'Box Breathing', 'Deep Breathing']);

    // Select appropriate exercise based on severity
    switch (severityLevel) {
      case 'mild':
        return exercises.firstWhere((e) => e['name'] == 'Deep Breathing')['id'];
      case 'moderate':
        return exercises.firstWhere((e) => e['name'] == 'Box Breathing')['id'];
      case 'severe':
      case 'critical':
        return exercises
            .firstWhere((e) => e['name'] == '4-7-8 Breathing')['id'];
      default:
        return exercises.first['id'];
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

    return Scaffold(
      backgroundColor: pastelBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, 'student-home'),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF3A3A50),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Your Assessment Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 24),

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
                if (summaryData!['severity_level'] == 'critical') ...[
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
                        'Book a Counselor',
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
                        Navigator.pushNamed(context, 'student-chatbot'),
                    child: Text(
                      'Talk to Chatbot',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severityLevel) {
    switch (severityLevel) {
      case 'mild':
        return Icons.sentiment_satisfied;
      case 'moderate':
        return Icons.sentiment_neutral;
      case 'severe':
        return Icons.sentiment_dissatisfied;
      case 'critical':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }
}
