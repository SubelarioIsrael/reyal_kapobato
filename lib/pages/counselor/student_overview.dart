import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/student_avatar.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class StudentOverview extends StatefulWidget {
  final String userId;
  final String studentName;
  final String studentId;

  const StudentOverview({
    super.key,
    required this.userId,
    required this.studentName,
    required this.studentId,
  });

  @override
  State<StudentOverview> createState() => _StudentOverviewState();
}

class _StudentOverviewState extends State<StudentOverview>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;

  // Student Profile Data
  Map<String, dynamic>? _studentProfile;

  // Dashboard Statistics
  int _totalActivitiesCompleted = 0;
  int _totalJournalEntries = 0;
  int _totalQuestionnaires = 0;
  int _totalSessions = 0;

  // Recent Data
  List<Map<String, dynamic>> _activityCounts = [];
  List<Map<String, dynamic>> _recentJournalEntries = [];
  List<Map<String, dynamic>> _recentQuestionnaires = [];
  List<Map<String, dynamic>> _sessionNotes = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStudentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadStudentProfile(),
        _loadActivityStats(),
        _loadJournalStats(),
        _loadQuestionnaireStats(),
        _loadSessionStats(),
        _loadRecentData(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading student data: $e';
      });
    }
  }

  Future<void> _loadStudentProfile() async {
    final response = await Supabase.instance.client
        .from('students')
        .select(
            '*, users!students_user_id_fkey(email, registration_date, status)')
        .eq('user_id', widget.userId)
        .single();

    _studentProfile = response;
  }

  Future<void> _loadActivityStats() async {
    // Get total activities completed
    final completedResponse = await Supabase.instance.client
        .from('activity_completions')
        .select('completion_id')
        .eq('user_id', widget.userId);

    _totalActivitiesCompleted = completedResponse.length;

    // Get activity counts grouped by activity type
    final activityCountsResponse = await Supabase.instance.client
        .from('activity_completions')
        .select('activity_id, activities(name, description, points)')
        .eq('user_id', widget.userId);

    // Group completions by activity and count them
    Map<int, Map<String, dynamic>> activityMap = {};

    for (var completion in activityCountsResponse) {
      final activityId = completion['activity_id'] as int;
      final activityInfo = completion['activities'] as Map<String, dynamic>;

      if (activityMap.containsKey(activityId)) {
        activityMap[activityId]!['count'] =
            (activityMap[activityId]!['count'] as int) + 1;
      } else {
        activityMap[activityId] = {
          'activity_id': activityId,
          'activity_info': activityInfo,
          'count': 1,
        };
      }
    }

    _activityCounts = activityMap.values.toList();

    // Sort by count (highest first)
    _activityCounts
        .sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  Future<void> _loadJournalStats() async {
    final response = await Supabase.instance.client
        .from('journal_entries')
        .select(
            'journal_id, title, entry_timestamp, sentiment, is_shared_with_counselor')
        .eq('user_id', widget.userId)
        .order('entry_timestamp', ascending: false);

    _totalJournalEntries = response.length;
    _recentJournalEntries = List<Map<String, dynamic>>.from(response.take(5));
  }

  Future<void> _loadQuestionnaireStats() async {
    final response = await Supabase.instance.client
        .from('questionnaire_responses')
        .select('''
          response_id, 
          total_score, 
          submission_timestamp,
          questionnaire_summaries(severity_level, insights, recommendations)
        ''')
        .eq('user_id', widget.userId)
        .order('submission_timestamp', ascending: false);

    _totalQuestionnaires = response.length;
    _recentQuestionnaires = List<Map<String, dynamic>>.from(response.take(5));
  }

  Future<void> _loadSessionStats() async {
    try {
      final response = await Supabase.instance.client
          .from('counseling_session_notes')
          .select('''
            *, 
            counseling_appointments(appointment_date, start_time, end_time),
            counselors(counselor_id, first_name, last_name)
          ''')
          .eq('student_user_id', widget.userId)
          .order('created_at', ascending: false);

      print('Session notes response: $response');
      
      _totalSessions = response.length;
      _sessionNotes = List<Map<String, dynamic>>.from(response);
      
      // Debug print each session's counselor data
      for (var session in _sessionNotes) {
        print('Session counselor data: ${session['counselors']}');
      }
    } catch (e) {
      print('Error loading session stats: $e');
      _totalSessions = 0;
      _sessionNotes = [];
    }
  }

  Future<void> _loadRecentData() async {
    // This method can be used to load any additional recent data if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Student Overview',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showDownloadConfirmation(),
            icon: const Icon(
              Icons.download,
              color: Color(0xFF7C83FD),
              size: 24,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStudentData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStudentData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildStudentHeader(),
                        _buildStatsCards(),
                        _buildTabSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStudentHeader() {
    if (_studentProfile == null) return const SizedBox.shrink();

    final student = _studentProfile!;
    final userInfo = student['users'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          StudentAvatar(
            userId: widget.userId,
            radius: 40,
            fallbackName: widget.studentName,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${student['student_code'] ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5D5D72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student['course'] ?? 'No Course'} • Year ${student['year_level'] ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5D5D72),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userInfo?['email'] ?? 'No Email',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF7C83FD),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              userInfo?['status']?.toString().toUpperCase() ?? 'ACTIVE',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Activities Completed',
                  _totalActivitiesCompleted.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Journal Entries',
                  _totalJournalEntries.toString(),
                  Icons.book,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Questionnaires',
                  _totalQuestionnaires.toString(),
                  Icons.quiz,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Counseling Sessions',
                  _totalSessions.toString(),
                  Icons.psychology,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF5D5D72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF7C83FD),
            unselectedLabelColor: const Color(0xFF5D5D72),
            indicatorColor: const Color(0xFF7C83FD),
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Activities'),
              Tab(text: 'Journals'),
              Tab(text: 'Assessments'),
              Tab(text: 'Sessions'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivitiesTab(),
                _buildJournalsTab(),
                _buildQuestionnairesTab(),
                _buildSessionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab() {
    if (_activityCounts.isEmpty) {
      return _buildEmptyState(
          'No activities completed yet', Icons.fitness_center);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activityCounts.length,
      itemBuilder: (context, index) {
        final activityData = _activityCounts[index];
        final activityInfo =
            activityData['activity_info'] as Map<String, dynamic>;
        final count = activityData['count'] as int;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _getActivityIcon(activityInfo['name']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getActivityDisplayName(activityInfo['name']),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    if (activityInfo['description'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        activityInfo['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF5D5D72),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Completed $count time${count == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF7C83FD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (activityInfo['points'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${activityInfo['points']} pts each',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF5D5D72),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJournalsTab() {
    if (_recentJournalEntries.isEmpty) {
      return _buildEmptyState('No journal entries yet', Icons.book);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentJournalEntries.length,
      itemBuilder: (context, index) {
        final journal = _recentJournalEntries[index];
        final sentiment = (journal['sentiment'] as String?)?.toLowerCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.book, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      journal['title'] ?? 'Untitled Entry',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                  ),
                  if (journal['is_shared_with_counselor'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Shared',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Date: ${_formatDate(journal['entry_timestamp'])}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF7C83FD),
                    ),
                  ),
                  const Spacer(),
                  if (sentiment != null) ...[
                    Icon(
                      _getSentimentIconLabel(sentiment),
                      size: 16,
                      color: _getSentimentColorLabel(sentiment),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getSentimentTextLabel(sentiment),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _getSentimentColorLabel(sentiment),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionnairesTab() {
    if (_recentQuestionnaires.isEmpty) {
      return _buildEmptyState('No questionnaires completed yet', Icons.quiz);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentQuestionnaires.length,
      itemBuilder: (context, index) {
        final questionnaire = _recentQuestionnaires[index];
        final summaries = questionnaire['questionnaire_summaries'] as List?;
        final summary = summaries?.isNotEmpty == true ? summaries!.first : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.quiz, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mental Health Assessment',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        Text(
                          'Score: ${questionnaire['total_score']}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF5D5D72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (summary != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(summary['severity_level']),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        summary['severity_level'].toString().toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Completed: ${_formatDate(questionnaire['submission_timestamp'])}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF7C83FD),
                ),
              ),
              if (summary?['insights'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Insights: ${summary!['insights']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF5D5D72),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionsTab() {
    if (_sessionNotes.isEmpty) {
      return _buildEmptyState('No counseling sessions yet', Icons.psychology);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessionNotes.length,
      itemBuilder: (context, index) {
        final session = _sessionNotes[index];
        final appointment =
            session['counseling_appointments'] as Map<String, dynamic>?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.psychology,
                        color: Colors.purple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Counseling Session',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        if (appointment != null)
                          Text(
                            'Date: ${appointment['appointment_date']} • ${appointment['start_time']} - ${appointment['end_time']}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF7C83FD),
                            ),
                          ),
                        // Add counselor name
                        if (session['counselors'] != null && 
                            session['counselors']['first_name'] != null && 
                            session['counselors']['last_name'] != null)
                          Text(
                            'Counselor: ${session['counselors']['first_name']} ${session['counselors']['last_name']}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF5D5D72),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showSessionDetailsModal(session, appointment),
                    icon: const Icon(
                      Icons.visibility,
                      color: Color(0xFF7C83FD),
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Summary: ${session['summary'] ?? 'No summary available'}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF5D5D72),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (session['recommendations']?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  'Recommendations: ${session['recommendations']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF5D5D72),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showSessionDetailsModal(Map<String, dynamic> session, Map<String, dynamic>? appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Session Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                  ),
                ],
              ),
              if (appointment != null) ...[
                Text(
                  'Date: ${appointment['appointment_date']} • ${appointment['start_time']} - ${appointment['end_time']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF7C83FD),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              // Add counselor name in modal
              if (session['counselors'] != null && 
                  session['counselors']['first_name'] != null && 
                  session['counselors']['last_name'] != null) ...[
                Text(
                  'Counselor: ${session['counselors']['first_name']} ${session['counselors']['last_name']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5D5D72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const Divider(),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // Session Summary
                      Row(
                        children: [
                          Icon(
                            Icons.summarize,
                            size: 18,
                            color: const Color(0xFF7C83FD),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Session Summary',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          session['summary'] ?? 'No summary available',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF3A3A50),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Topics Discussed
                      Row(
                        children: [
                          Icon(
                            Icons.topic,
                            size: 18,
                            color: const Color(0xFF7C83FD),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Topics Discussed',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          session['topics_discussed']?.isNotEmpty == true 
                              ? session['topics_discussed']
                              : 'No topics recorded',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF3A3A50),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Recommendations
                      Row(
                        children: [
                          Icon(
                            Icons.recommend,
                            size: 18,
                            color: const Color(0xFF7C83FD),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recommendations',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          session['recommendations']?.isNotEmpty == true 
                              ? session['recommendations']
                              : 'No recommendations provided',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF3A3A50),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateTime.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  IconData _getSentimentIconLabel(String? label) {
    switch ((label ?? '').toLowerCase()) {
      case 'positive':
        return Icons.sentiment_very_satisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      case 'negative':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  Color _getSentimentColorLabel(String? label) {
    switch ((label ?? '').toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'neutral':
        return Colors.orange;
      case 'negative':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getSentimentTextLabel(String? label) {
    switch ((label ?? '').toLowerCase()) {
      case 'positive':
        return 'Positive';
      case 'neutral':
        return 'Neutral';
      case 'negative':
        return 'Negative';
      default:
        return 'Unknown';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      case 'critical':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  Widget _getActivityIcon(String activityName) {
    IconData icon;
    switch (activityName) {
      case 'daily_checkin':
        icon = Icons.check_circle;
        break;
      case 'mood_journal':
        icon = Icons.book;
        break;
      case 'track_mood':
        icon = Icons.quiz;
        break;
      default:
        icon = Icons.fitness_center;
    }

    return Icon(icon, color: Colors.green, size: 20);
  }

  String _getActivityDisplayName(String activityName) {
    switch (activityName) {
      case 'daily_checkin':
        return 'Daily Check-ins';
      case 'mood_journal':
        return 'Mood Journal Entries';
      case 'track_mood':
        return 'Mental Health Assessments';
      default:
        return activityName
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  void _showDownloadConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Download Student Report',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
            ),
          ),
          content: Text(
            'Do you want to download the complete student report for ${widget.studentName}?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF5D5D72),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5D5D72),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _generateStudentReportPdf();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C83FD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Download',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateStudentReportPdf() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(bottom: 30),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'BREATHE BETTER',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Student Progress Report',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.normal,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on ${DateTime.now().toString().split('.')[0]}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Divider line
              pw.Container(
                height: 2,
                color: PdfColors.indigo,
                margin: const pw.EdgeInsets.only(bottom: 30),
              ),
              
              // Student Information Section
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Student Information',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    _buildPdfDetailRow('Name', widget.studentName),
                    _buildPdfDetailRow('Student ID', _studentProfile?['student_code'] ?? 'N/A'),
                    _buildPdfDetailRow('Course', _studentProfile?['course'] ?? 'N/A'),
                    _buildPdfDetailRow('Year Level', 'Year ${_studentProfile?['year_level'] ?? 'N/A'}'),
                    _buildPdfDetailRow('Email', _studentProfile?['users']?['email'] ?? 'N/A'),
                    _buildPdfDetailRow('Status', _studentProfile?['users']?['status']?.toString().toUpperCase() ?? 'ACTIVE'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Statistics Overview Section
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Activity Overview',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    
                    // Statistics Grid
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPdfStatCard('Activities Completed', _totalActivitiesCompleted.toString(), PdfColors.green),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: _buildPdfStatCard('Journal Entries', _totalJournalEntries.toString(), PdfColors.blue),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 15),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPdfStatCard('Mental Health Assessments', _totalQuestionnaires.toString(), PdfColors.orange),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: _buildPdfStatCard('Counseling Sessions', _totalSessions.toString(), PdfColors.purple),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Activity Details Section
              if (_activityCounts.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Activity Breakdown',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      ..._activityCounts.take(5).map((activity) {
                        final activityInfo = activity['activity_info'] as Map<String, dynamic>;
                        final count = activity['count'] as int;
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 4,
                                height: 4,
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.green,
                                  shape: pw.BoxShape.circle,
                                ),
                                margin: const pw.EdgeInsets.only(right: 8, top: 4),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  _getActivityDisplayName(activityInfo['name']),
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.grey800,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(
                                  '$count times',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
              ],
              
              // Recent Journal Entries Section
              if (_recentJournalEntries.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Recent Journal Entries',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      ..._recentJournalEntries.take(5).map((journal) {
                        final sentiment = (journal['sentiment'] as String?)?.toLowerCase();
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: 4,
                                    height: 4,
                                    decoration: pw.BoxDecoration(
                                      color: PdfColors.blue,
                                      shape: pw.BoxShape.circle,
                                    ),
                                    margin: const pw.EdgeInsets.only(right: 8, top: 4),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      journal['title'] ?? 'Untitled Entry',
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        color: PdfColors.grey800,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  pw.Text(
                                    _formatDate(journal['entry_timestamp']),
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey600,
                                    ),
                                  ),
                                ],
                              ),
                              if (sentiment != null) ...[
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Sentiment: ${_getSentimentTextLabel(sentiment)}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
              ],
              
              // Counseling Sessions Section
              if (_sessionNotes.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Counseling Sessions Summary',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      ..._sessionNotes.take(3).map((session) {
                        final appointment = session['counseling_appointments'] as Map<String, dynamic>?;
                        final counselor = session['counselors'] as Map<String, dynamic>?;
                        final counselorName = counselor != null && 
                                              counselor['first_name'] != null && 
                                              counselor['last_name'] != null
                            ? '${counselor['first_name']} ${counselor['last_name']}'
                            : 'Unknown Counselor';
                            
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 15),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: 4,
                                    height: 4,
                                    decoration: pw.BoxDecoration(
                                      color: PdfColors.purple,
                                      shape: pw.BoxShape.circle,
                                    ),
                                    margin: const pw.EdgeInsets.only(right: 8, top: 4),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      'Counseling Session',
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        color: PdfColors.grey800,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (appointment != null)
                                    pw.Text(
                                      appointment['appointment_date'] ?? '',
                                      style: pw.TextStyle(
                                        fontSize: 10,
                                        color: PdfColors.grey600,
                                      ),
                                    ),
                                ],
                              ),
                              pw.SizedBox(height: 6),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(left: 12),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'Counselor: $counselorName',
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        color: PdfColors.grey700,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(
                                      'Summary: ${session['summary'] ?? 'No summary available'}',
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        color: PdfColors.grey700,
                                      ),
                                    ),
                                    if (session['recommendations']?.isNotEmpty == true) ...[
                                      pw.SizedBox(height: 4),
                                      pw.Text(
                                        'Recommendations: ${session['recommendations']}',
                                        style: pw.TextStyle(
                                          fontSize: 11,
                                          color: PdfColors.grey700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
              ],
              
              // Report Details Section
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Report Details',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    _buildPdfDetailRow('Report Type', 'Comprehensive Student Progress Report'),
                    _buildPdfDetailRow('Student Name', widget.studentName),
                    _buildPdfDetailRow('Student ID', widget.studentId),
                    _buildPdfDetailRow('Generated By', 'Counselor'),
                    _buildPdfDetailRow('Report Status', 'Complete'),
                  ],
                ),
              ),
              
              // Footer
              pw.Spacer(),
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '© 2024 Breathe Better - Confidential Student Report',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF to file - try multiple locations
      String? savedPath;
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final fileName = 'breathe_better_student_report_${widget.studentName.replaceAll(' ', '_')}_$timestamp.pdf';
      
      // Try different locations in order of preference
      final locations = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads', 
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];
      
      // Also try using path_provider
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          locations.add('${extDir.path}/Download');
          locations.add(extDir.path);
        }
      } catch (e) {
        print('Could not get external storage directory: $e');
      }
      
      for (String path in locations) {
        try {
          final directory = Directory(path);
          
          // Try to create directory if it doesn't exist
          if (!await directory.exists()) {
            try {
              await directory.create(recursive: true);
            } catch (e) {
              continue; // Try next location
            }
          }
          
          final file = File('$path/$fileName');
          await file.writeAsBytes(await pdf.save());
          savedPath = file.path;
          break; // Success! Exit the loop
        } catch (e) {
          print('Failed to save to $path: $e');
          continue; // Try next location
        }
      }

      if (mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student report PDF saved successfully!'),
                  SizedBox(height: 4),
                  Text(
                    'Location: $savedPath',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF7C83FD),
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save PDF to any location. Please check storage permissions.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfStatCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
