import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/student_avatar.dart';
import '../../controllers/counselor_student_overview_controller.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CounselorStudentOverview extends StatefulWidget {
  final String userId;
  final String studentName;
  final String studentId;

  const CounselorStudentOverview({
    super.key,
    required this.userId,
    required this.studentName,
    required this.studentId,
  });

  @override
  State<CounselorStudentOverview> createState() => _CounselorStudentOverviewState();
}

class _CounselorStudentOverviewState extends State<CounselorStudentOverview>
    with TickerProviderStateMixin {
  final _controller = CounselorStudentOverviewController();
  bool _isLoading = true;
  String? _errorMessage;

  // Student Profile Data
  Map<String, dynamic>? _studentProfile;

  // Dashboard Statistics
  int _totalJournalEntries = 0;
  int _totalQuestionnaires = 0;
  int _totalSessions = 0;

  // Recent Data
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _recentJournalEntries = [];
  List<Map<String, dynamic>> _recentQuestionnaires = [];
  List<Map<String, dynamic>> _sessionNotes = [];
  List<Map<String, dynamic>> _emergencyContacts = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadStudentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
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
    _studentProfile = await _controller.loadStudentProfile(widget.userId);
  }

  Future<void> _loadActivityStats() async {
    _recentActivities = await _controller.loadActivityStats(widget.userId);
  }

  Future<void> _loadJournalStats() async {
    final result = await _controller.loadJournalStats(widget.userId);
    _totalJournalEntries = result['total'];
    _recentJournalEntries = result['recent'];
  }

  Future<void> _loadQuestionnaireStats() async {
    final result = await _controller.loadQuestionnaireStats(widget.userId);
    _totalQuestionnaires = result['total'];
    _recentQuestionnaires = result['recent'];
  }

  Future<void> _loadSessionStats() async {
    try {
      final result = await _controller.loadSessionStats(widget.userId);
      _totalSessions = result['total'];
      _sessionNotes = result['sessions'];
    } catch (e) {
      print('Error loading session stats: $e');
      _totalSessions = 0;
      _sessionNotes = [];
    }
  }

  Future<void> _loadRecentData() async {
    // Load emergency contacts
    try {
      _emergencyContacts = await _controller.loadEmergencyContacts(widget.userId);
    } catch (e) {
      print('Error loading emergency contacts: $e');
      _emergencyContacts = [];
    }
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
    
    // Abbreviate course name
    String courseDisplay = student['course'] ?? 'No Course';
    if (courseDisplay.length > 10) {
      // Extract abbreviation from course name (e.g., "Bachelor of Science in Information Technology" -> "BSIT")
      courseDisplay = _abbreviateCourse(courseDisplay);
    }
    courseDisplay = '$courseDisplay - ${student['year_level'] ?? 'N/A'}';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    fontSize: 16,
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
                  courseDisplay,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5D5D72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _abbreviateCourse(String courseName) {
    // Common course abbreviations
    final Map<String, String> courseAbbreviations = {
      'Bachelor of Science in Information Technology': 'BSIT',
      'Bachelor of Science in Computer Science': 'BSCS',
      'Bachelor of Science in Accountancy': 'BSA',
      'Bachelor of Science in Business Administration': 'BSBA',
      'Bachelor of Science in Nursing': 'BSN',
      'Bachelor of Science in Civil Engineering': 'BSCE',
      'Bachelor of Science in Mechanical Engineering': 'BSME',
      'Bachelor of Science in Electrical Engineering': 'BSEE',
      'Bachelor of Science in Electronics Engineering': 'BSEcE',
      'Bachelor of Science in Psychology': 'BS Psychology',
      'Bachelor of Science in Education': 'BSEd',
      'Bachelor of Arts in Communication': 'AB Communication',
      'Accountancy': 'ACT',
    };

    // Check if the course has a direct abbreviation
    if (courseAbbreviations.containsKey(courseName)) {
      return courseAbbreviations[courseName]!;
    }

    // Otherwise, try to create abbreviation from first letters
    if (courseName.contains('Bachelor')) {
      final words = courseName.split(' ');
      String abbrev = '';
      for (var word in words) {
        if (word.isNotEmpty && word[0] == word[0].toUpperCase() && word != 'in' && word != 'of') {
          abbrev += word[0];
        }
      }
      return abbrev.isNotEmpty ? abbrev : courseName;
    }

    return courseName;
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
                  'Journal Entries',
                  _totalJournalEntries.toString(),
                  Icons.book,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Assessments',
                  _totalQuestionnaires.toString(),
                  Icons.quiz,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Sessions',
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
            color: Colors.black.withOpacity(0.1),
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
            color: Colors.black.withOpacity(0.1),
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
            tabs: const [
              Tab(key: const Key('activities_tab'), icon: Icon(Icons.view_timeline)),
              Tab(key: const Key('journals_tab'), icon: Icon(Icons.book)),
              Tab(key: const Key('questionnaires_tab'), icon: Icon(Icons.quiz)),
              Tab(key: const Key('sessions_tab'), icon: Icon(Icons.psychology)),
              Tab(key: const Key('emergency_contacts_tab'), icon: Icon(Icons.contact_emergency)),
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
                _buildEmergencyContactsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Recent Activities',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
            ),
          ),
        ),
        Expanded(
          child: _recentActivities.isEmpty
              ? _buildEmptyState('No activities completed yet', Icons.fitness_center)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recentActivities.length,
                  itemBuilder: (context, index) {
                    final activity = _recentActivities[index];
                    final activityType = activity['activity_type'];

                    // Determine if this is an appointment or activity completion
                    if (activityType == 'appointment') {
                      return _buildAppointmentCard(activity);
                    } else {
                      return _buildActivityCompletionCard(activity);
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActivityCompletionCard(Map<String, dynamic> activity) {
    final activityInfo = activity['activities'] as Map<String, dynamic>?;
    final completedAt = activity['completed_at'];
    final completionDate = activity['completion_date'];
    final activityName = activityInfo?['name'] ?? 'unknown';

    // Get color and icon based on activity type
    final activityColor = _getActivityColor(activityName);
    final activityIcon = _getActivityIcon(activityName);

    // Generate description
    final description = _generateActivityDescription(activityName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activityColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: activityIcon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: activityColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(completionDate ?? completedAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: activityColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final appointmentDate = appointment['appointment_date'];
    final startTime = appointment['start_time'];
    final status = appointment['status'];
    final counselor = appointment['counselors'] as Map<String, dynamic>?;
    
    final counselorName = counselor != null && 
                          counselor['first_name'] != null && 
                          counselor['last_name'] != null
        ? '${counselor['first_name']} ${counselor['last_name']}'
        : 'a counselor';

    // Generate description based on status
    String description;
    if (status == 'scheduled' || status == 'confirmed') {
      description = '${widget.studentName} booked an appointment with $counselorName';
    } else if (status == 'completed') {
      description = '${widget.studentName} completed a counseling session with $counselorName';
    } else if (status == 'cancelled') {
      description = '${widget.studentName} cancelled an appointment with $counselorName';
    } else {
      description = '${widget.studentName} scheduled an appointment with $counselorName';
    }

    // Color based on status
    Color appointmentColor;
    IconData appointmentIcon;
    if (status == 'completed') {
      appointmentColor = Colors.teal;
      appointmentIcon = Icons.check_circle;
    } else if (status == 'cancelled') {
      appointmentColor = Colors.red;
      appointmentIcon = Icons.cancel;
    } else {
      appointmentColor = Colors.purple;
      appointmentIcon = Icons.event;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appointmentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appointmentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appointmentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(appointmentIcon, color: appointmentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: appointmentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(appointmentDate)}${startTime != null ? ' • $startTime' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: appointmentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _generateActivityDescription(String activityName) {
    final studentName = widget.studentName;
    
    switch (activityName) {
      case 'daily_checkin':
        return '$studentName completed daily check-in';
      case 'mood_journal':
        return '$studentName completed mood journal entry';
      case 'breathing_exercise':
        return '$studentName performed breathing exercise';
      case 'track_mood':
        return '$studentName tracked their mood';
      case 'mental_health_assessment':
        return '$studentName completed mental health assessment';
      case 'stress_management':
        return '$studentName completed stress management activity';
      case 'relaxation_technique':
        return '$studentName practiced relaxation technique';
      case 'mindfulness_exercise':
        return '$studentName practiced mindfulness exercise';
      default:
        // Convert snake_case to Title Case
        final displayName = activityName
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
        return '$studentName completed $displayName';
    }
  }

  Color _getActivityColor(String activityName) {
    switch (activityName) {
      case 'daily_checkin':
        return Colors.blue;
      case 'mood_journal':
        return Colors.indigo;
      case 'breathing_exercise':
        return Colors.cyan;
      case 'track_mood':
        return Colors.orange;
      case 'mental_health_assessment':
        return Colors.deepOrange;
      case 'stress_management':
        return Colors.amber;
      case 'relaxation_technique':
        return Colors.lightGreen;
      case 'mindfulness_exercise':
        return Colors.teal;
      default:
        return Colors.green;
    }
  }

  Widget _buildJournalsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Journal Entries',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
            ),
          ),
        ),
        Expanded(
          child: _recentJournalEntries.isEmpty
              ? _buildEmptyState('No journal entries yet', Icons.book)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recentJournalEntries.length,
                  itemBuilder: (context, index) {
                    final journal = _recentJournalEntries[index];
                    final sentiment = (journal['sentiment'] as String?)?.toLowerCase();

                    // Add a stable key so integration tests can find journal entries
                    return GestureDetector(
                      onTap: () => _showJournalDetailsModal(journal),
                      child: Container(
                        key: const Key('journal_entry'),
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
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showJournalDetailsModal(Map<String, dynamic> journal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.book,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              journal['title'] ?? 'Untitled Entry',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(journal['entry_timestamp']),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF5D5D72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (journal['sentiment'] != null) ...[
                          Row(
                            children: [
                              Icon(
                                _getSentimentIconLabel(journal['sentiment']),
                                size: 24,
                                color: _getSentimentColorLabel(journal['sentiment']),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mood: ${_getSentimentTextLabel(journal['sentiment'])}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _getSentimentColorLabel(journal['sentiment']),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          'Journal Entry',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            journal['content'] ?? 'No content available',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF3A3A50),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionnairesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Mental Health Assessments',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
            ),
          ),
        ),
        Expanded(
          child: _recentQuestionnaires.isEmpty
              ? _buildEmptyState('No questionnaires completed yet', Icons.quiz)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
    ),
        ),
      ],
    );
  }

  Widget _buildSessionsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Counseling Sessions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
            ),
          ),
        ),
        Expanded(
          child: _sessionNotes.isEmpty
              ? _buildEmptyState('No counseling sessions yet', Icons.psychology)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
    ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContactsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Emergency Contacts',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
            ),
          ),
        ),
        Expanded(
          child: _emergencyContacts.isEmpty
              ? _buildEmptyState('No emergency contacts added yet', Icons.contact_emergency)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _emergencyContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _emergencyContacts[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.contact_emergency, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact['contact_name'] ?? 'Unknown Contact',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.family_restroom,
                          size: 14,
                          color: const Color(0xFF7C83FD),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          contact['relationship'] ?? 'N/A',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF5D5D72),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: const Color(0xFF7C83FD),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          contact['contact_number'] ?? 'N/A',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF5D5D72),
                          ),
                        ),
                      ],
                    ),
                    if (contact['is_notified'] == true) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Notified',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
        ),
      ],
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
    Color iconColor;
    
    switch (activityName) {
      case 'daily_checkin':
        icon = Icons.check_circle;
        iconColor = Colors.blue;
        break;
      case 'mood_journal':
        icon = Icons.book;
        iconColor = Colors.indigo;
        break;
      case 'breathing_exercise':
        icon = Icons.air;
        iconColor = Colors.cyan;
        break;
      case 'track_mood':
        icon = Icons.mood;
        iconColor = Colors.orange;
        break;
      case 'mental_health_assessment':
        icon = Icons.quiz;
        iconColor = Colors.deepOrange;
        break;
      case 'stress_management':
        icon = Icons.spa;
        iconColor = Colors.amber;
        break;
      case 'relaxation_technique':
        icon = Icons.self_improvement;
        iconColor = Colors.lightGreen;
        break;
      case 'mindfulness_exercise':
        icon = Icons.psychology_alt;
        iconColor = Colors.teal;
        break;
      default:
        icon = Icons.fitness_center;
        iconColor = Colors.green;
    }

    return Icon(icon, color: iconColor, size: 20);
  }

  void _showDownloadConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Question Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C83FD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.download_outlined,
                  color: Color(0xFF7C83FD),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Download Report',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                'Do you want to download the complete student report for ${widget.studentName}?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons Row
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _generateStudentReportPdf();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C83FD),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Download',
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
            ],
          ),
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
                          child: _buildPdfStatCard('Journal Entries', _totalJournalEntries.toString(), PdfColors.blue),
                        ),
                        pw.SizedBox(width: 20),
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
              
              // Recent Activity Details Section
              if (_recentActivities.isNotEmpty) ...[
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
                        'Recent Activities',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      ..._recentActivities.take(10).map((activity) {
                        final activityType = activity['activity_type'];
                        String description;
                        String dateStr;
                        
                        if (activityType == 'appointment') {
                          final counselor = activity['counselors'] as Map<String, dynamic>?;
                          final counselorName = counselor != null && 
                                                counselor['first_name'] != null && 
                                                counselor['last_name'] != null
                              ? '${counselor['first_name']} ${counselor['last_name']}'
                              : 'a counselor';
                          description = '${widget.studentName} booked an appointment with $counselorName';
                          dateStr = _formatDate(activity['appointment_date']);
                        } else {
                          final activityInfo = activity['activities'] as Map<String, dynamic>?;
                          final activityName = activityInfo?['name'] ?? 'unknown';
                          description = _generateActivityDescription(activityName);
                          final completedAt = activity['completed_at'];
                          final completionDate = activity['completion_date'];
                          dateStr = _formatDate(completionDate ?? completedAt);
                        }
                        
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 4,
                                height: 4,
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.indigo,
                                  shape: pw.BoxShape.circle,
                                ),
                                margin: const pw.EdgeInsets.only(right: 8, top: 4),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  description,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  dateStr,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey600,
                                  ),
                                  textAlign: pw.TextAlign.right,
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
                    border: pw.Border.all(color: PdfColors.grey500),
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
                      ...(_sessionNotes.take(3).map((session) {
                        final appointment = session['counseling_appointments'] is Map
                            ? session['counseling_appointments'] as Map<String, dynamic>
                            : null;

                        final counselor = session['counselors'] is Map
                            ? session['counselors'] as Map<String, dynamic>
                            : null;

                        final counselorName = (counselor?['first_name'] != null &&
                                counselor?['last_name'] != null)
                            ? '${counselor!['first_name']} ${counselor['last_name']}'
                            : 'Unknown Counselor';

                        final recommendations = session['recommendations'];
                        final hasRecommendations = recommendations is String &&
                            recommendations.trim().isNotEmpty;

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
                                    if (hasRecommendations) ...[
                                      pw.SizedBox(height: 4),
                                      pw.Text(
                                        'Recommendations: $recommendations',
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
                      }).toList()),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),
              ],
              
              // Emergency Contacts Section
              if (_emergencyContacts.isNotEmpty) ...[
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
                        'Emergency Contacts',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      ..._emergencyContacts.map((contact) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(12),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.red50,
                              border: pw.Border.all(color: PdfColors.red200),
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  contact['contact_name'] ?? 'Unknown Contact',
                                  style: pw.TextStyle(
                                    fontSize: 13,
                                    color: PdfColors.grey900,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Row(
                                  children: [
                                    pw.Text(
                                      'Relationship: ',
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        color: PdfColors.grey700,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.Text(
                                      contact['relationship'] ?? 'N/A',
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        color: PdfColors.grey700,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 2),
                                pw.Row(
                                  children: [
                                    pw.Text(
                                      'Contact Number: ',
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        color: PdfColors.grey700,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.Text(
                                      contact['contact_number'] ?? 'N/A',
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        color: PdfColors.grey700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (contact['is_notified'] == true) ...[
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    '✓ Has been notified',
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.green,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
                  // Success Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Success Title
                  Text(
                    'Report Generated',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Success Message
                  Text(
                    'Student report PDF saved successfully!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Location: $savedPath',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Done Button
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
                      onPressed: () {
                        Navigator.pop(ctx); // Close dialog
                      },
                      child: Text(
                        'Done',
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
        } else {
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
                  // Error Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Error Title
                  Text(
                    'Failed to Save',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Error Message
                  Text(
                    'Failed to save PDF to any location. Please check storage permissions.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // OK Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx); // Close dialog
                      },
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
      }
    } catch (e) {
      if (mounted) {
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
                // Error Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                // Error Title
                Text(
                  'Error',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 12),
                // Error Message
                Text(
                  'Error generating PDF: $e',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5D5D72),
                  ),
                ),
                const SizedBox(height: 24),
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx); // Close dialog
                    },
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
