import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/student_avatar.dart';
import '../../controllers/counselor_student_overview_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  List<Map<String, dynamic>> _riskAlerts = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
        _loadRiskAlerts(),
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

  Future<void> _loadRiskAlerts() async {
    try {
      final result = await Supabase.instance.client
          .from('risk_alerts')
          .select()
          .eq('user_id', widget.userId)
          .order('trigger_timestamp', ascending: false)
          .limit(20);
      _riskAlerts = List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error loading risk alerts: $e');
      _riskAlerts = [];
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDownloadConfirmation(),
        backgroundColor: const Color(0xFF7C83FD),
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Export PDF',
        child: const Icon(Icons.download_rounded),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStudentHeader(),
                        _buildStatsCards(),
                        const SizedBox(height: 4),
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
    String courseDisplay = student['course'] ?? 'No Course';
    if (courseDisplay.length > 10) courseDisplay = _abbreviateCourse(courseDisplay);
    final yearLevel = student['year_level'] ?? 'N/A';
    final openAlerts = _riskAlerts.where((a) => !(a['is_resolved'] ?? false)).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C83FD).withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient accent bar at the top
          Container(
            height: 8,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [Color(0xFF7C83FD), Color(0xFFB39DDB)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                // Avatar with a subtle purple ring
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C83FD).withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: StudentAvatar(
                    userId: widget.userId,
                    radius: 36,
                    fallbackName: widget.studentName,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.studentName,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3A3A50),
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (openAlerts > 0) ...
                            [
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 12, color: Colors.red[700]),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$openAlerts Alert${openAlerts > 1 ? 's' : ''}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _infoChip(
                            Icons.badge_outlined,
                            student['student_code'] ?? 'N/A',
                          ),
                          const SizedBox(width: 6),
                          _infoChip(
                            Icons.school_outlined,
                            '$courseDisplay · Y$yearLevel',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF7C83FD)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5D5D72),
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
    final openAlerts =
        _riskAlerts.where((a) => !(a['is_resolved'] ?? false)).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                  'Journals', _totalJournalEntries.toString(),
                  Icons.book_rounded, const Color(0xFF7C83FD)),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildStatItem(
                  'Assessments', _totalQuestionnaires.toString(),
                  Icons.quiz_rounded, Colors.orange),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildStatItem(
                  'Sessions', _totalSessions.toString(),
                  Icons.psychology_rounded, Colors.teal),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildStatItem(
                  'Alerts', openAlerts.toString(),
                  Icons.warning_amber_rounded,
                  openAlerts > 0 ? Colors.red : Colors.grey,
                  highlight: openAlerts > 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(highlight ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: highlight ? color : const Color(0xFF3A3A50),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: highlight ? color : const Color(0xFF5D5D72),
              fontWeight:
                  highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 14),
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildTabSection() {
    final openAlerts =
        _riskAlerts.where((a) => !(a['is_resolved'] ?? false)).length;
    final alertColor =
        openAlerts > 0 ? Colors.red : const Color(0xFF5D5D72);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF7C83FD),
            unselectedLabelColor: const Color(0xFF9E9EB8),
            indicatorColor: const Color(0xFF7C83FD),
            indicatorWeight: 2.5,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 14),
            labelStyle: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w400),
            tabs: [
              const Tab(
                key: Key('activities_tab'),
                icon: Icon(Icons.view_timeline_rounded, size: 18),
                text: 'Activity',
              ),
              const Tab(
                key: Key('journals_tab'),
                icon: Icon(Icons.book_rounded, size: 18),
                text: 'Journal',
              ),
              const Tab(
                key: Key('questionnaires_tab'),
                icon: Icon(Icons.quiz_rounded, size: 18),
                text: 'Assessment',
              ),
              const Tab(
                key: Key('sessions_tab'),
                icon: Icon(Icons.psychology_rounded, size: 18),
                text: 'Session',
              ),
              const Tab(
                key: Key('emergency_contacts_tab'),
                icon: Icon(Icons.contact_emergency_rounded, size: 18),
                text: 'Emergency',
              ),
              Tab(
                key: const Key('risk_alerts_tab'),
                icon: Icon(Icons.warning_amber_rounded,
                    size: 18, color: alertColor),
                child: Text(
                  openAlerts > 0 ? 'Alerts ($openAlerts)' : 'Alerts',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: alertColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEF5)),
          // Responsive height: at least 420, at most 60% of screen
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 420, maxHeight: 560),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivitiesTab(),
                _buildJournalsTab(),
                _buildQuestionnairesTab(),
                _buildSessionsTab(),
                _buildEmergencyContactsTab(),
                _buildRiskAlertsTab(),
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

  Widget _buildRiskAlertsTab() {
    final openCount =
        _riskAlerts.where((a) => !(a['is_resolved'] ?? false)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Risk Alerts',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: openCount > 0
                      ? Colors.red.withOpacity(0.12)
                      : Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  openCount > 0 ? '$openCount open' : 'All clear',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: openCount > 0 ? Colors.red[700] : Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _riskAlerts.isEmpty
              ? _buildEmptyState(
                  'No risk alerts for this student',
                  Icons.check_circle_outline,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _riskAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = _riskAlerts[index];
                    final isResolved = alert['is_resolved'] ?? false;
                    final isAcknowledged = alert['is_acknowledged'] ?? false;
                    final reason =
                        alert['trigger_reason'] ?? 'No reason provided';
                    final triggeredAt = alert['trigger_timestamp'];

                    final alertColor = isResolved
                        ? Colors.grey
                        : isAcknowledged
                            ? Colors.orange
                            : Colors.red;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: alertColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: alertColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: alertColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3A3A50),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(
                                  isResolved, isAcknowledged),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 13,
                                  color: Color(0xFF7C83FD)),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(triggeredAt),
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF7C83FD)),
                              ),
                            ],
                          ),
                          if (alert['action_notes'] != null &&
                              (alert['action_notes'] as String)
                                  .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Note: ${alert['action_notes']}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF5D5D72)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (!isResolved) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!isAcknowledged)
                                  TextButton(
                                    onPressed: () => _acknowledgeAlert(
                                        alert['alert_id']),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                    ),
                                    child: Text(
                                      'Acknowledge',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.orange[700]),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () =>
                                      _resolveAlert(alert['alert_id']),
                                  child: Text(
                                    'Mark Resolved',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white),
                                  ),
                                ),
                              ],
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

  Widget _buildStatusChip(bool isResolved, bool isAcknowledged) {
    if (isResolved) {
      return _chip('Resolved', Colors.green);
    } else if (isAcknowledged) {
      return _chip('Acknowledged', Colors.orange);
    }
    return _chip('Open', Colors.red);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Future<void> _acknowledgeAlert(dynamic alertId) async {
    try {
      await Supabase.instance.client.from('risk_alerts').update({
        'is_acknowledged': true,
        'handled_by': Supabase.instance.client.auth.currentUser?.id,
      }).eq('alert_id', alertId);
      await _loadRiskAlerts();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error acknowledging alert: $e');
    }
  }

  Future<void> _resolveAlert(dynamic alertId) async {
    try {
      await Supabase.instance.client.from('risk_alerts').update({
        'is_resolved': true,
        'is_acknowledged': true,
        'resolved_timestamp': DateTime.now().toIso8601String(),
        'handled_by': Supabase.instance.client.auth.currentUser?.id,
      }).eq('alert_id', alertId);
      await _loadRiskAlerts();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error resolving alert: $e');
    }
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
      final DateTime date = DateTime.parse(dateTime.toString()).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[date.month - 1];
      final hour = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return '$month ${date.day}, ${date.year} · $hour:$min';
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
      // ── Load app logo ──────────────────────────────────────────────────
      final logoData =
          await rootBundle.load('assets/icon/breathe-better-logo-fixed-1.png');
      final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

      // ── Fetch data ─────────────────────────────────────────────────────
      final assessmentsResponse = await Supabase.instance.client
          .from('questionnaire_responses')
          .select('*')
          .eq('user_id', widget.userId)
          .order('submission_timestamp', ascending: false)
          .limit(10);
      final assessments = List<Map<String, dynamic>>.from(assessmentsResponse);

      final sessionsResponse = await Supabase.instance.client
          .from('counseling_appointments')
          .select('*, counselors(first_name, last_name)')
          .eq('user_id', widget.userId)
          .order('appointment_date', ascending: false)
          .limit(15);
      final sessions = List<Map<String, dynamic>>.from(sessionsResponse);

      final moodResponse = await Supabase.instance.client
          .from('mood_entries')
          .select('mood_type, entry_date')
          .eq('user_id', widget.userId)
          .order('entry_date', ascending: false)
          .limit(30);
      final moodEntries = List<Map<String, dynamic>>.from(moodResponse);

      // ── Risk alert counts ──────────────────────────────────────────────
      final openAlerts = _riskAlerts
          .where((a) => a['is_resolved'] != true && a['is_acknowledged'] != true)
          .length;
      final acknowledgedAlerts = _riskAlerts
          .where((a) => a['is_acknowledged'] == true && a['is_resolved'] != true)
          .length;
      final resolvedAlerts =
          _riskAlerts.where((a) => a['is_resolved'] == true).length;

      // ── Mood distribution ──────────────────────────────────────────────
      final moodCounts = <String, int>{};
      for (final e in moodEntries) {
        final mt = (e['mood_type'] as String? ?? 'unknown').toLowerCase();
        moodCounts[mt] = (moodCounts[mt] ?? 0) + 1;
      }

      // ── Assessment score trend ─────────────────────────────────────────
      String assessmentTrend = 'N/A';
      String trendDescription = '';
      if (assessments.length >= 2) {
        final latest = (assessments.first['total_score'] as int?) ?? 0;
        final previous = (assessments[1]['total_score'] as int?) ?? 0;
        final diff = latest - previous;
        if (diff < 0) {
          assessmentTrend = 'IMPROVING';
          trendDescription =
              'Score decreased by ${diff.abs()} points (lower is better)';
        } else if (diff > 0) {
          assessmentTrend = 'WORSENING';
          trendDescription =
              'Score increased by $diff points (lower is better)';
        } else {
          assessmentTrend = 'STABLE';
          trendDescription = 'No change from previous assessment';
        }
      } else if (assessments.length == 1) {
        assessmentTrend = 'BASELINE';
        trendDescription = 'First assessment on record';
      }

      // ── Journal sentiment breakdown ────────────────────────────────────
      final positiveJournals = _recentJournalEntries
          .where((j) => (j['sentiment'] as String?)?.toLowerCase() == 'positive')
          .length;
      final negativeJournals = _recentJournalEntries
          .where((j) => (j['sentiment'] as String?)?.toLowerCase() == 'negative')
          .length;
      final neutralJournals =
          _recentJournalEntries.length - positiveJournals - negativeJournals;

      // ── Brand palette ──────────────────────────────────────────────────
      const brandPurple = PdfColor(0.486, 0.514, 0.992);
      const brandBlue = PdfColor(0.13, 0.59, 0.95);
      const dangerRed = PdfColor(0.85, 0.15, 0.15);
      const warningOrange = PdfColor(0.95, 0.55, 0.10);
      const successGreen = PdfColor(0.13, 0.70, 0.37);
      const deepPurple = PdfColor(0.56, 0.26, 0.92);

      final now = DateTime.now();
      final generatedAt =
          '${_pdfMonthName(now.month)} ${now.day}, ${now.year}  |  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          build: (pw.Context context) {
            return [
              // ━━━ HEADER ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [
                      brandPurple,
                      const PdfColor(0.60, 0.62, 1.0)
                    ],
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                  ),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Image(logoImage, width: 50, height: 50),
                        pw.SizedBox(width: 14),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'BreatheBetter',
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              'Student Mental Health Report',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.white,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text(
                            'CONFIDENTIAL',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: brandPurple,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          generatedAt,
                          style: pw.TextStyle(
                              fontSize: 8, color: PdfColors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // ━━━ RISK BANNER (only when open alerts exist) ━━━━━━━━━━━━━━
              if (openAlerts > 0) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor(1.0, 0.94, 0.94),
                    border: pw.Border.all(color: dangerRed, width: 1.5),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 5,
                        height: 36,
                        decoration: pw.BoxDecoration(
                          color: dangerRed,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '[!] ACTIVE RISK ALERT - COUNSELOR ATTENTION REQUIRED',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: dangerRed,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'This student has $openAlerts unresolved risk alert${openAlerts > 1 ? 's' : ''}. Immediate follow-up is recommended.',
                              style: pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              // ━━━ STUDENT INFORMATION ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              _buildPdfSection(
                title: 'Student Information',
                accentColor: brandPurple,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfDetailRow('Full Name', widget.studentName),
                          _buildPdfDetailRow('Student ID',
                              _studentProfile?['student_code'] ?? 'N/A'),
                          _buildPdfDetailRow('Email',
                              _studentProfile?['users']?['email'] ?? 'N/A'),
                          _buildPdfDetailRow(
                            'Account Status',
                            (_studentProfile?['users']?['status']
                                        ?.toString() ??
                                    'active')
                                .toUpperCase(),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfDetailRow(
                            'Education Level',
                            (_studentProfile?['education_level'] as String? ??
                                    'N/A')
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                          ),
                          _buildPdfDetailRow(
                            'Course / Strand',
                            _studentProfile?['course'] ??
                                _studentProfile?['strand'] ??
                                'N/A',
                          ),
                          _buildPdfDetailRow(
                            'Year Level',
                            'Year ${_studentProfile?['year_level'] ?? 'N/A'}',
                          ),
                          _buildPdfDetailRow(
                            'Report Date',
                            '${_pdfMonthName(now.month)} ${now.day}, ${now.year}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // ━━━ ENGAGEMENT OVERVIEW — 4 stat cards ━━━━━━━━━━━━━━━━━━━━
              _buildPdfSection(
                title: 'Engagement Overview',
                accentColor: brandPurple,
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildPdfStatCard(
                        'Journal\nEntries',
                        _totalJournalEntries.toString(),
                        const PdfColor(0.13, 0.45, 0.85),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: _buildPdfStatCard(
                        'Assessments\nCompleted',
                        _totalQuestionnaires.toString(),
                        warningOrange,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: _buildPdfStatCard(
                        'Counseling\nSessions',
                        _totalSessions.toString(),
                        deepPurple,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: _buildPdfStatCard(
                        'Risk\nAlerts',
                        _riskAlerts.length.toString(),
                        openAlerts > 0 ? dangerRed : successGreen,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // ━━━ MENTAL HEALTH RISK ALERTS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              if (_riskAlerts.isNotEmpty) ...[
                _buildPdfSection(
                  title: 'Mental Health Risk Alerts',
                  accentColor: dangerRed,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          _buildPdfBadge('Open', openAlerts.toString(),
                              dangerRed, const PdfColor(1.0, 0.93, 0.93)),
                          pw.SizedBox(width: 10),
                          _buildPdfBadge(
                              'Acknowledged',
                              acknowledgedAlerts.toString(),
                              warningOrange,
                              const PdfColor(1.0, 0.97, 0.93)),
                          pw.SizedBox(width: 10),
                          _buildPdfBadge(
                              'Resolved',
                              resolvedAlerts.toString(),
                              successGreen,
                              const PdfColor(0.93, 1.0, 0.95)),
                        ],
                      ),
                      if (_riskAlerts.any((a) => a['is_resolved'] != true)) ...[
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'Unresolved Alerts:',
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 6),
                        ..._riskAlerts
                            .where((a) => a['is_resolved'] != true)
                            .take(5)
                            .map((alert) {
                          final isOpen = alert['is_acknowledged'] != true;
                          final statusLabel =
                              isOpen ? 'OPEN' : 'ACKNOWLEDGED';
                          final statusColor = isOpen ? dangerRed : warningOrange;
                          final rawDate =
                              alert['trigger_timestamp'] as String?;
                          String dateStr = 'Unknown date';
                          if (rawDate != null) {
                            try {
                              final d = DateTime.parse(rawDate);
                              dateStr =
                                  '${_pdfMonthName(d.month)} ${d.day}, ${d.year}';
                            } catch (_) {}
                          }
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                color: const PdfColor(1.0, 0.97, 0.97),
                                border: pw.Border.all(
                                    color: const PdfColor(0.90, 0.75, 0.75),
                                    width: 0.5),
                                borderRadius: pw.BorderRadius.circular(5),
                              ),
                              child: pw.Row(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Expanded(
                                    child: pw.Text(
                                      alert['trigger_reason'] ??
                                          'No reason provided',
                                      style: pw.TextStyle(
                                          fontSize: 9,
                                          color: PdfColors.grey800),
                                    ),
                                  ),
                                  pw.SizedBox(width: 8),
                                  pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    children: [
                                      pw.Container(
                                        padding: const pw.EdgeInsets
                                            .symmetric(
                                            horizontal: 5, vertical: 2),
                                        decoration: pw.BoxDecoration(
                                          color: statusColor,
                                          borderRadius:
                                              pw.BorderRadius.circular(3),
                                        ),
                                        child: pw.Text(
                                          statusLabel,
                                          style: pw.TextStyle(
                                            fontSize: 7,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.white,
                                          ),
                                        ),
                                      ),
                                      pw.SizedBox(height: 3),
                                      pw.Text(
                                        dateStr,
                                        style: pw.TextStyle(
                                            fontSize: 7,
                                            color: PdfColors.grey500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
              ],

              // ━━━ MOOD DISTRIBUTION ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              if (moodEntries.isNotEmpty) ...[
                _buildPdfSection(
                  title:
                      'Emotional Mood Distribution (Last ${moodEntries.length} Entries)',
                  accentColor: brandBlue,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: moodCounts.entries.map((entry) {
                      final pct =
                          (entry.value / moodEntries.length * 100).round();
                      final moodColor = _pdfMoodColor(entry.key);
                      final barWidth =
                          entry.value / moodEntries.length * 260;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(
                          children: [
                            pw.SizedBox(
                              width: 68,
                              child: pw.Text(
                                '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                                style: pw.TextStyle(
                                    fontSize: 10, color: PdfColors.grey700),
                              ),
                            ),
                            pw.Container(
                              width: barWidth,
                              height: 12,
                              decoration: pw.BoxDecoration(
                                color: moodColor,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text(
                              '${entry.value}x  ($pct%)',
                              style: pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey600),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                pw.SizedBox(height: 14),
              ],

              // ━━━ ASSESSMENT SCORE TREND ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              if (assessments.isNotEmpty) ...[
                _buildPdfSection(
                  title: 'Mental Health Assessment Score Trend',
                  accentColor: warningOrange,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (assessments.length >= 2) ...[
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          margin: const pw.EdgeInsets.only(bottom: 12),
                          decoration: pw.BoxDecoration(
                            color: assessmentTrend == 'IMPROVING'
                                ? const PdfColor(0.90, 1.0, 0.92)
                                : assessmentTrend == 'WORSENING'
                                    ? const PdfColor(1.0, 0.93, 0.93)
                                    : const PdfColor(0.94, 0.94, 1.0),
                            border: pw.Border.all(
                              color: assessmentTrend == 'IMPROVING'
                                  ? successGreen
                                  : assessmentTrend == 'WORSENING'
                                      ? dangerRed
                                      : brandPurple,
                              width: 1.0,
                            ),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Text(
                                assessmentTrend,
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: assessmentTrend == 'IMPROVING'
                                      ? successGreen
                                      : assessmentTrend == 'WORSENING'
                                          ? dangerRed
                                          : brandPurple,
                                ),
                              ),
                              pw.SizedBox(width: 12),
                              pw.Text(
                                trendDescription,
                                style: pw.TextStyle(
                                    fontSize: 9, color: PdfColors.grey700),
                              ),
                            ],
                          ),
                        ),
                      ],
                      pw.Table(
                        border: pw.TableBorder.all(
                            color: PdfColors.grey200, width: 0.5),
                        columnWidths: const {
                          0: pw.FlexColumnWidth(3),
                          1: pw.FlexColumnWidth(1.5),
                          2: pw.FlexColumnWidth(2),
                          3: pw.FlexColumnWidth(2),
                        },
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                                color: PdfColors.grey100),
                            children: [
                              _pdfTableCell('Date', isHeader: true),
                              _pdfTableCell('Score', isHeader: true),
                              _pdfTableCell('Risk Level', isHeader: true),
                              _pdfTableCell('Severity', isHeader: true),
                            ],
                          ),
                          ...assessments.take(8).map((a) {
                            final d =
                                DateTime.parse(a['submission_timestamp']);
                            final dateStr =
                                '${_pdfMonthName(d.month)} ${d.day}, ${d.year}';
                            final score = (a['total_score'] as int?) ?? 0;
                            String risk = 'Low';
                            PdfColor riskColor = successGreen;
                            if (score >= 20) {
                              risk = 'High';
                              riskColor = dangerRed;
                            } else if (score >= 10) {
                              risk = 'Moderate';
                              riskColor = warningOrange;
                            }
                            return pw.TableRow(
                              children: [
                                _pdfTableCell(dateStr),
                                _pdfTableCell(score.toString()),
                                _pdfTableCell(risk, textColor: riskColor),
                                _pdfTableCell(
                                    a['severity_level']?.toString() ?? 'N/A'),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
              ],

              // ━━━ JOURNAL SENTIMENT ANALYSIS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              if (_recentJournalEntries.isNotEmpty) ...[
                _buildPdfSection(
                  title: 'Journal Sentiment Analysis',
                  accentColor: const PdfColor(0.13, 0.45, 0.85),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          _buildPdfBadge(
                              'Positive',
                              positiveJournals.toString(),
                              successGreen,
                              const PdfColor(0.92, 1.0, 0.94)),
                          pw.SizedBox(width: 10),
                          _buildPdfBadge(
                              'Neutral',
                              neutralJournals.toString(),
                              PdfColors.grey600,
                              PdfColors.grey200),
                          pw.SizedBox(width: 10),
                          _buildPdfBadge(
                              'Negative',
                              negativeJournals.toString(),
                              dangerRed,
                              const PdfColor(1.0, 0.93, 0.93)),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      ..._recentJournalEntries.take(5).map((journal) {
                        final sentiment =
                            (journal['sentiment'] as String?)?.toLowerCase() ??
                                'neutral';
                        final sentimentColor = sentiment == 'positive'
                            ? successGreen
                            : sentiment == 'negative'
                                ? dangerRed
                                : PdfColors.grey500;
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 7),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 3,
                                height: 26,
                                color: sentimentColor,
                                margin:
                                    const pw.EdgeInsets.only(right: 10),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  journal['title'] ?? 'Untitled Entry',
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey800),
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    sentiment.toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: sentimentColor,
                                    ),
                                  ),
                                  pw.Text(
                                    _formatDate(journal['entry_timestamp']),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        color: PdfColors.grey400),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
              ],

              // ━━━ COUNSELING SESSIONS TABLE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              if (sessions.isNotEmpty) ...[
                _buildPdfSection(
                  title: 'Counseling Sessions',
                  accentColor: deepPurple,
                  child: pw.Table(
                    border: pw.TableBorder.all(
                        color: PdfColors.grey200, width: 0.5),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2.5),
                      1: pw.FlexColumnWidth(3),
                      2: pw.FlexColumnWidth(1.5),
                      3: pw.FlexColumnWidth(4),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                            color: PdfColors.grey100),
                        children: [
                          _pdfTableCell('Date', isHeader: true),
                          _pdfTableCell('Counselor', isHeader: true),
                          _pdfTableCell('Status', isHeader: true),
                          _pdfTableCell('Notes', isHeader: true),
                        ],
                      ),
                      ...sessions.take(10).map((session) {
                        final counselor =
                            session['counselors'] as Map<String, dynamic>?;
                        final counselorName = counselor != null &&
                                counselor['first_name'] != null
                            ? '${counselor['first_name']} ${counselor['last_name']}'
                            : 'Unknown';
                        final d =
                            DateTime.parse(session['appointment_date']);
                        final dateStr =
                            '${_pdfMonthName(d.month)} ${d.day}, ${d.year}';
                        final status =
                            (session['status']?.toString() ?? 'pending')
                                .toUpperCase();
                        final statusColor = status == 'COMPLETED'
                            ? successGreen
                            : status == 'CANCELLED'
                                ? dangerRed
                                : warningOrange;
                        final notes = session['notes']?.toString() ?? '';
                        return pw.TableRow(
                          children: [
                            _pdfTableCell(dateStr),
                            _pdfTableCell(counselorName),
                            _pdfTableCell(status, textColor: statusColor),
                            _pdfTableCell(notes.length > 60
                                ? '${notes.substring(0, 60)}...'
                                : notes.isEmpty
                                    ? 'N/A'
                                    : notes),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
              ],

              // ━━━ SESSION NOTES SUMMARY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              if (_sessionNotes.isNotEmpty) ...[
                _buildPdfSection(
                  title: 'Counselor Session Notes',
                  accentColor: deepPurple,
                  child: pw.Column(
                    children: _sessionNotes.take(3).map((session) {
                      final counselor =
                          session['counselors'] is Map
                              ? session['counselors']
                                  as Map<String, dynamic>
                              : null;
                      final counselorName = (counselor?['first_name'] !=
                                  null &&
                              counselor?['last_name'] != null)
                          ? '${counselor!['first_name']} ${counselor['last_name']}'
                          : 'Unknown Counselor';
                      final appointment =
                          session['counseling_appointments'] is Map
                              ? session['counseling_appointments']
                                  as Map<String, dynamic>
                              : null;
                      final recommendations =
                          session['recommendations']?.toString() ?? '';
                      final summary = session['summary']?.toString() ??
                          'No summary available';
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor(0.97, 0.95, 1.0),
                            border: pw.Border.all(
                                color: const PdfColor(0.80, 0.75, 0.95),
                                width: 0.5),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Counselor: $counselorName',
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                  if (appointment != null)
                                    pw.Text(
                                      appointment['appointment_date'] ?? '',
                                      style: pw.TextStyle(
                                          fontSize: 8,
                                          color: PdfColors.grey500),
                                    ),
                                ],
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                summary.length > 200
                                    ? '${summary.substring(0, 200)}...'
                                    : summary,
                                style: pw.TextStyle(
                                    fontSize: 9, color: PdfColors.grey700),
                              ),
                              if (recommendations.trim().isNotEmpty) ...[
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Recommendations: ${recommendations.length > 150 ? '${recommendations.substring(0, 150)}...' : recommendations}',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontStyle: pw.FontStyle.italic,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                pw.SizedBox(height: 14),
              ],

              // ━━━ EMERGENCY CONTACTS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              if (_emergencyContacts.isNotEmpty) ...[
                _buildPdfSection(
                  title: 'Emergency Contacts',
                  accentColor: dangerRed,
                  child: pw.Column(
                    children: _emergencyContacts.map((contact) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor(1.0, 0.97, 0.97),
                            border: pw.Border.all(
                                color: const PdfColor(0.90, 0.72, 0.72),
                                width: 0.5),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      contact['contact_name'] ?? 'Unknown',
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.grey900,
                                      ),
                                    ),
                                    pw.Text(
                                      contact['relationship'] ?? 'N/A',
                                      style: pw.TextStyle(
                                          fontSize: 9,
                                          color: PdfColors.grey600),
                                    ),
                                  ],
                                ),
                              ),
                              pw.Text(
                                contact['contact_number'] ?? 'N/A',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: dangerRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                pw.SizedBox(height: 14),
              ],

              // ━━━ FOOTER ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey200),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'This document is strictly confidential and intended solely for authorized school guidance counselors.',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '(c) 2026 BreatheBetter  |  Student Mental Health Report  |  Generated by Counseling System',
                      textAlign: pw.TextAlign.center,
                      style:
                          pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                    ),
                  ],
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

  // ─── PDF: section wrapper ────────────────────────────────────────────────
  pw.Widget _buildPdfSection({
    required String title,
    required PdfColor accentColor,
    required pw.Widget child,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 16,
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          pw.Container(
            height: 0.5,
            color: PdfColors.grey200,
            margin: const pw.EdgeInsets.only(top: 8, bottom: 10),
          ),
          child,
        ],
      ),
    );
  }

  // ─── PDF: badge counter ───────────────────────────────────────────────────
  pw.Widget _buildPdfBadge(
      String label, String count, PdfColor color, PdfColor bgColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(color: color, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            count,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ─── PDF: table cell ──────────────────────────────────────────────────────
  pw.Widget _pdfTableCell(String text,
      {bool isHeader = false, PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color:
              textColor ?? (isHeader ? PdfColors.grey800 : PdfColors.grey700),
        ),
      ),
    );
  }

  // ─── PDF: mood → PdfColor ─────────────────────────────────────────────────
  PdfColor _pdfMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return const PdfColor(0.13, 0.70, 0.37);
      case 'calm':
        return const PdfColor(0.13, 0.59, 0.95);
      case 'sad':
        return const PdfColor(0.24, 0.42, 0.78);
      case 'angry':
        return const PdfColor(0.85, 0.15, 0.15);
      case 'anxious':
        return const PdfColor(0.95, 0.55, 0.10);
      default:
        return PdfColors.grey400;
    }
  }

  // ─── PDF: integer month → abbreviated name ────────────────────────────────
  String _pdfMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return month >= 1 && month <= 12 ? months[month - 1] : '$month';
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
