import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';

class QuestionnaireHistory extends StatefulWidget {
  const QuestionnaireHistory({super.key});

  @override
  State<QuestionnaireHistory> createState() => _QuestionnaireHistoryState();
}

class _QuestionnaireHistoryState extends State<QuestionnaireHistory> {
  List<Map<String, dynamic>> responses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestionnaireHistory();
  }

  Future<void> _loadQuestionnaireHistory() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
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

      setState(() {
        responses = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading questionnaire history: $e');
      setState(() => isLoading = false);
    }
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

    if (isLoading) {
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Questionnaire History",
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
      body: responses.isEmpty
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
                    'No questionnaire history yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: responses.length,
              itemBuilder: (context, index) {
                final response = responses[index];
                final summary = response['questionnaire_summaries'] != null &&
                        (response['questionnaire_summaries'] as List).isNotEmpty
                    ? (response['questionnaire_summaries'] as List).first
                    : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
