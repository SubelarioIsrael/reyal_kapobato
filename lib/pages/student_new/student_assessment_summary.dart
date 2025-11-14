import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../controllers/student_assessment_controller.dart';

class StudentAssessmentSummary extends StatefulWidget {
  final int responseId;
  final int totalScore;

  const StudentAssessmentSummary({
    super.key,
    required this.responseId,
    required this.totalScore,
  });

  @override
  State<StudentAssessmentSummary> createState() => _StudentAssessmentSummaryState();
}

class _StudentAssessmentSummaryState extends State<StudentAssessmentSummary> {
  final StudentAssessmentController _controller = StudentAssessmentController();
  bool _isLoading = true;
  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? _breathingExercise;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);

    try {
      // Get or create summary using controller
      final result = await _controller.getOrCreateSummary(
        responseId: widget.responseId,
        totalScore: widget.totalScore,
      );

      if (result.success && result.summaryData != null) {
        setState(() {
          _summaryData = result.summaryData;
          _isLoading = false;
        });

        // Load breathing exercise details if available
        if (result.summaryData!['breathing_exercise_id'] != null) {
          final exerciseResult = await _controller.getBreathingExercise(
            result.summaryData!['breathing_exercise_id'] as int,
          );

          if (exerciseResult.success && exerciseResult.exerciseData != null) {
            setState(() {
              _breathingExercise = exerciseResult.exerciseData;
            });
          }
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          _showAlertDialog(
            'Error',
            result.errorMessage ?? 'Failed to load assessment summary',
            Icons.error_outline,
            Colors.red,
          );
        }
      }
    } catch (e) {
      print('Error loading summary: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showAlertDialog(
          'Error',
          'An unexpected error occurred while loading the summary',
          Icons.error_outline,
          Colors.red,
        );
      }
    }
  }

  void _showAlertDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pastelBlue = Color.fromARGB(255, 242, 241, 248);
    const pastelPurple = Color(0xFFE0D4FD);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: pastelBlue,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_summaryData == null) {
      return Scaffold(
        backgroundColor: pastelBlue,
        appBar: AppBar(
          backgroundColor: pastelBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF5D5D72)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF5D5D72),
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading summary data',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(
        backgroundColor: pastelBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF5D5D72)),
          onPressed: () async {
            await Navigator.of(context).maybePop();
          },
        ),
        title: Text(
          "Assessment Summary",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: const [
          StudentNotificationButton(),
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
                    color: _getSeverityColor(_summaryData!['severity_level']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getSeverityIcon(_summaryData!['severity_level']),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Severity Level: ${_summaryData!['severity_level'].toString().toUpperCase()}',
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
                    _summaryData!['insights'],
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
                    _summaryData!['recommendations'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF3A3A50),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Breathing Exercise
                if (_breathingExercise != null) ...[
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
                      arguments: _breathingExercise,
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
                            _breathingExercise!['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _breathingExercise!['description'],
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
                if (_summaryData!['severity_level'] == 'severe' || _summaryData!['severity_level'] == 'critical') ...[
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

                    const SizedBox(width: 10),

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
      case 'mild':
        return Colors.lightGreen;
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
