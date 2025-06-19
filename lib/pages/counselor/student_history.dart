import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class StudentHistory extends StatefulWidget {
  final String userId;
  final String username;
  final String studentId;

  const StudentHistory({
    super.key,
    required this.userId,
    required this.username,
    required this.studentId,
  });

  @override
  State<StudentHistory> createState() => _StudentHistoryState();
}

class _StudentHistoryState extends State<StudentHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _journalEntries = [];
  List<Map<String, dynamic>> _questionnaireSummaries = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ensure user ID is in UUID format
      final userId = widget.userId.trim();
      print('Loading data for user: $userId'); // Debug print

      // Load journal entries
      try {
        final journalResponse = await Supabase.instance.client
            .from('journal_entries')
            .select()
            .eq('user_id', userId)
            .eq('is_shared_with_counselor', true)
            .order('entry_timestamp', ascending: false);

        print('Journal Response: $journalResponse'); // Debug print
        _journalEntries = List<Map<String, dynamic>>.from(journalResponse);
      } catch (e) {
        print('Error loading journal entries: $e'); // Debug print
        _journalEntries = [];
      }

      // Load questionnaire summaries
      try {
        final questionnaireResponse = await Supabase.instance.client
            .from('questionnaire_responses')
            .select('''
              response_id,
              user_id,
              version_id,
              total_score,
              submission_timestamp,
              questionnaire_summaries!inner(
                summary_id,
                severity_level,
                insights,
                recommendations,
                breathing_exercise_id,
                created_at
              )
            ''')
            .eq('user_id', userId)
            .order('submission_timestamp', ascending: false);

        print('Questionnaire Response: $questionnaireResponse'); // Debug print
        _questionnaireSummaries =
            List<Map<String, dynamic>>.from(questionnaireResponse);
      } catch (e) {
        print('Error loading questionnaire summaries: $e'); // Debug print
        _questionnaireSummaries = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('General error in _loadData: $e'); // Debug print
      setState(() {
        _errorMessage = 'Error loading student history: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateReportPdf() async {
    // Create a PDF document
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
              level: 0,
              text:
                  'Student Report: ${widget.username} (ID: ${widget.studentId})'),
          pw.Header(level: 1, text: 'Journal Entries'),
          if (_journalEntries.isEmpty)
            pw.Text('No shared journal entries.')
          else
            ..._journalEntries.map((entry) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      entry['title'] ?? 'No Title',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(entry['content'] ?? 'No Content'),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Date: ${DateTime.parse(entry['entry_timestamp']).toString().split('.')[0]}',
                      style: const pw.TextStyle(
                          color: PdfColors.grey600, fontSize: 10),
                    ),
                    if (entry['sentiment_score'] != null)
                      pw.Text(
                        'Sentiment Score: ${entry['sentiment_score']}',
                        style: const pw.TextStyle(
                            color: PdfColors.grey600, fontSize: 10),
                      ),
                  ],
                ),
              );
            }).toList(),
          pw.Header(level: 1, text: 'Questionnaire Summaries'),
          if (_questionnaireSummaries.isEmpty)
            pw.Text('No questionnaire summaries.')
          else
            ..._questionnaireSummaries.map((summary) {
              final summaryData = summary['questionnaire_summaries'] as List?;
              if (summaryData == null || summaryData.isEmpty) {
                return pw.SizedBox.shrink();
              }
              final summaryItem = summaryData[0];
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Questionnaire Summary',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                        'Severity Level: ${summaryItem['severity_level'] ?? 'N/A'}'),
                    pw.Text('Insights: ${summaryItem['insights'] ?? 'N/A'}'),
                    pw.Text(
                        'Recommendations: ${summaryItem['recommendations'] ?? 'N/A'}'),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Date: ${DateTime.parse(summaryItem['created_at']).toString().split('.')[0]}',
                      style: const pw.TextStyle(
                          color: PdfColors.grey600, fontSize: 10),
                    ),
                    pw.Text(
                      'Total Score: ${summary['total_score']}',
                      style: const pw.TextStyle(
                          color: PdfColors.grey600, fontSize: 10),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );

    try {
      final directory =
          await getExternalStorageDirectory(); // This typically points to .../Android/data/com.example.breathe_better/files
      if (directory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access external storage.')),
          );
        }
        print('Error: Could not access external storage.');
        return;
      }

      final customDownloadsPath = '${directory.path}/downloads';
      final customDownloadsDir = Directory(customDownloadsPath);

      if (!await customDownloadsDir.exists()) {
        await customDownloadsDir.create(recursive: true);
      }

      final file = File(
          '$customDownloadsPath/student_report_${widget.username.replaceAll(' ', '_')}.pdf');

      // Write the PDF bytes to the file
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to: ${file.path}')),
        );
      }
      print('Report saved to: ${file.path}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
      print('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.username}\'s History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showDownloadConfirmation(
                'Student Report',
                'Do you want to download the report for ${widget.username}?',
                _generateReportPdf),
            tooltip: 'Download Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Journal Entries'),
            Tab(text: 'Questionnaire Summaries'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Journal Entries Tab
                    _journalEntries.isEmpty
                        ? const Center(child: Text('No shared journal entries'))
                        : ListView.builder(
                            itemCount: _journalEntries.length,
                            itemBuilder: (context, index) {
                              final entry = _journalEntries[index];
                              return Card(
                                margin: const EdgeInsets.all(8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry['title'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(entry['content']),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Date: ${DateTime.parse(entry['entry_timestamp']).toString().split('.')[0]}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (entry['sentiment_score'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Sentiment Score: ${entry['sentiment_score']}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    // Questionnaire Summaries Tab
                    _questionnaireSummaries.isEmpty
                        ? const Center(
                            child: Text('No questionnaire summaries'))
                        : ListView.builder(
                            itemCount: _questionnaireSummaries.length,
                            itemBuilder: (context, index) {
                              final summary = _questionnaireSummaries[index];
                              final summaryData =
                                  summary['questionnaire_summaries'] as List;
                              if (summaryData.isEmpty)
                                return const SizedBox.shrink();
                              final summaryItem = summaryData[0];
                              return Card(
                                margin: const EdgeInsets.all(8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Questionnaire Summary',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Severity Level: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              summaryItem['severity_level'] ??
                                                  'N/A',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Insights: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              summaryItem['insights'] ?? 'N/A',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Recommendations: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              summaryItem['recommendations'] ??
                                                  'N/A',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          const Text(
                                            'Date: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            DateTime.parse(
                                                    summaryItem['created_at'])
                                                .toString()
                                                .split('.')[0],
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Text(
                                            'Total Score: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${summary['total_score']}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
    );
  }

  void _showDownloadConfirmation(
      String title, String message, Function onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Dismiss dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dismiss dialog
              onConfirm(); // Proceed with download
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}
