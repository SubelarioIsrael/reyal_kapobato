import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        .select('*, users!students_user_id_fkey(email, registration_date, status)')
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
        activityMap[activityId]!['count'] = (activityMap[activityId]!['count'] as int) + 1;
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
    _activityCounts.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  Future<void> _loadJournalStats() async {
    final response = await Supabase.instance.client
        .from('journal_entries')
        .select('journal_id, title, entry_timestamp, sentiment_score, is_shared_with_counselor')
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
    final response = await Supabase.instance.client
        .from('counseling_session_notes')
        .select('*, counseling_appointments(appointment_date, start_time, end_time)')
        .eq('student_user_id', widget.userId)
        .order('created_at', ascending: false);
    
    _totalSessions = response.length;
    _sessionNotes = List<Map<String, dynamic>>.from(response);
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7C83FD).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Color(0xFF7C83FD),
            ),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
      return _buildEmptyState('No activities completed yet', Icons.fitness_center);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activityCounts.length,
      itemBuilder: (context, index) {
        final activityData = _activityCounts[index];
        final activityInfo = activityData['activity_info'] as Map<String, dynamic>;
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        final sentimentScore = journal['sentiment_score'] as double?;
        
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  if (sentimentScore != null) ...[
                    Icon(
                      _getSentimentIcon(sentimentScore),
                      size: 16,
                      color: _getSentimentColor(sentimentScore),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getSentimentLabel(sentimentScore),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _getSentimentColor(sentimentScore),
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
                    child: const Icon(Icons.quiz, color: Colors.orange, size: 20),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        final appointment = session['counseling_appointments'] as Map<String, dynamic>?;
        
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
                    child: const Icon(Icons.psychology, color: Colors.purple, size: 20),
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
                      ],
                    ),
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
              if (session['topics_discussed']?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  'Topics: ${session['topics_discussed']}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF5D5D72),
                    fontStyle: FontStyle.italic,
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

  IconData _getSentimentIcon(double score) {
    if (score >= 0.1) return Icons.sentiment_very_satisfied;
    if (score >= -0.1) return Icons.sentiment_neutral;
    return Icons.sentiment_very_dissatisfied;
  }

  Color _getSentimentColor(double score) {
    if (score >= 0.1) return Colors.green;
    if (score >= -0.1) return Colors.orange;
    return Colors.red;
  }

  String _getSentimentLabel(double score) {
    if (score >= 0.1) return 'Positive';
    if (score >= -0.1) return 'Neutral';
    return 'Negative';
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
        return activityName.replaceAll('_', ' ').split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}