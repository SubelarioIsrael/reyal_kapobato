import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../controllers/student_assessment_controller.dart';

class StudentAssessmentHistory extends StatefulWidget {
  const StudentAssessmentHistory({super.key});

  @override
  State<StudentAssessmentHistory> createState() => _StudentAssessmentHistoryState();
}

class _StudentAssessmentHistoryState extends State<StudentAssessmentHistory> {
  final StudentAssessmentController _controller = StudentAssessmentController();
  List<Map<String, dynamic>> _responses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestionnaireHistory();
  }

  Future<void> _loadQuestionnaireHistory() async {
    setState(() => _isLoading = true);

    try {
      final result = await _controller.loadQuestionnaireHistory();

      if (result.success && result.responses != null) {
        setState(() {
          _responses = result.responses!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          _showAlertDialog(
            'Error',
            result.errorMessage ?? 'Failed to load questionnaire history',
            Icons.error_outline,
            Colors.red,
          );
        }
      }
    } catch (e) {
      print('Error loading questionnaire history: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showAlertDialog(
          'Error',
          'An unexpected error occurred while loading your history',
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

  String _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return '#4CAF50'; // Green
      case 'moderate':
        return '#FFC107'; // Yellow
      case 'severe':
        return '#FF9800'; // Orange
      case 'critical':
        return '#F44336'; // Red
      default:
        return '#757575'; // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    const pastelBlue = Color.fromARGB(255, 242, 241, 248);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: pastelBlue,
        body: const Center(child: CircularProgressIndicator()),
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
          "Assessment History",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: const [StudentNotificationButton()],
      ),
      drawer: const StudentDrawer(),
      body: _responses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No assessment history yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete a questionnaire to see your history',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _responses.length,
              itemBuilder: (context, index) {
                final response = _responses[index];
                final summary = response['questionnaire_summaries'] != null &&
                        (response['questionnaire_summaries'] as List).isNotEmpty
                    ? (response['questionnaire_summaries'] as List).first
                    : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        'questionnaire-summary',
                        arguments: {
                          'responseId': response['response_id'],
                          'totalScore': response['total_score'],
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMMM d, y').format(
                                  DateTime.parse(
                                      response['submission_timestamp']),
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              if (summary != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(_getSeverityColor(
                                            summary['severity_level'])
                                        .replaceAll('#', '0xFF'))),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    summary['severity_level']
                                        .toString()
                                        .toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Total Score: ${response['total_score']}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF5D5D72),
                            ),
                          ),
                          if (summary != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Insights:',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary['insights'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF5D5D72),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Tap to view details',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF7C83FD),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
