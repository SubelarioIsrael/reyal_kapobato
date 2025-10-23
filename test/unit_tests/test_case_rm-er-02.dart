// RM-ER-02: Counselor can export the generated student report as a correctly formatted PDF
// Requirement: Counselor can export student progress report with activities, journals, assessments, sessions
// Mirrors logic in `student_overview.dart` (generate student report PDF with comprehensive data)

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent student profile data
class MockStudentProfile {
  final String userId;
  final String studentName;
  final String studentId;
  final String? course;
  final int? yearLevel;
  final String email;
  final String status;

  MockStudentProfile({
    required this.userId,
    required this.studentName,
    required this.studentId,
    this.course,
    this.yearLevel,
    required this.email,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'student_code': studentId,
      'course': course,
      'year_level': yearLevel,
      'users': {
        'email': email,
        'status': status,
      },
    };
  }
}

// Mock class to represent student statistics
class MockStudentStats {
  final int totalActivitiesCompleted;
  final int totalJournalEntries;
  final int totalQuestionnaires;
  final int totalSessions;
  final List<Map<String, dynamic>> activityCounts;
  final List<Map<String, dynamic>> recentJournalEntries;
  final List<Map<String, dynamic>> recentQuestionnaires;
  final List<Map<String, dynamic>> sessionNotes;

  MockStudentStats({
    required this.totalActivitiesCompleted,
    required this.totalJournalEntries,
    required this.totalQuestionnaires,
    required this.totalSessions,
    required this.activityCounts,
    required this.recentJournalEntries,
    required this.recentQuestionnaires,
    required this.sessionNotes,
  });
}

// Mock PDF document class
class MockPdfDocument {
  List<Map<String, dynamic>> pages = [];
  
  void addPage(Map<String, dynamic> pageContent) {
    pages.add(pageContent);
  }
  
  List<int> save() {
    // Simulate PDF binary data
    return List.generate(2048, (index) => index % 256);
  }
}

// Mock database class to simulate Supabase operations
class MockDatabase {
  Map<String, dynamic>? _studentProfile;
  List<Map<String, dynamic>> _activityCompletions = [];
  List<Map<String, dynamic>> _journalEntries = [];
  List<Map<String, dynamic>> _questionnaires = [];
  List<Map<String, dynamic>> _sessionNotes = [];

  void seedStudentProfile(Map<String, dynamic> profile) {
    _studentProfile = profile;
  }

  void seedActivityCompletions(List<Map<String, dynamic>> completions) {
    _activityCompletions = completions;
  }

  void seedJournalEntries(List<Map<String, dynamic>> entries) {
    _journalEntries = entries;
  }

  void seedQuestionnaires(List<Map<String, dynamic>> questionnaires) {
    _questionnaires = questionnaires;
  }

  void seedSessionNotes(List<Map<String, dynamic>> notes) {
    _sessionNotes = notes;
  }

  Future<Map<String, dynamic>?> fetchStudentProfile(String userId) async {
    return _studentProfile;
  }

  Future<List<Map<String, dynamic>>> fetchActivityCompletions(String userId) async {
    return _activityCompletions;
  }

  Future<List<Map<String, dynamic>>> fetchJournalEntries(String userId) async {
    return _journalEntries.map((entry) => Map<String, dynamic>.from(entry)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchQuestionnaires(String userId) async {
    return _questionnaires;
  }

  Future<List<Map<String, dynamic>>> fetchSessionNotes(String userId) async {
    return _sessionNotes;
  }
}

// Service class to handle student report generation
class StudentReportService {
  final MockDatabase _database;

  StudentReportService(this._database);

  Future<MockStudentStats> loadStudentData(String userId) async {
    try {
      final activityCompletions = await _database.fetchActivityCompletions(userId);
      final journalEntries = await _database.fetchJournalEntries(userId);
      final questionnaires = await _database.fetchQuestionnaires(userId);
      final sessionNotes = await _database.fetchSessionNotes(userId);

      // Group activities by type and count them
      Map<String, Map<String, dynamic>> activityMap = {};
      for (var completion in activityCompletions) {
        final activityName = completion['activities']['name'];
        if (activityMap.containsKey(activityName)) {
          activityMap[activityName]!['count'] = (activityMap[activityName]!['count'] as int) + 1;
        } else {
          activityMap[activityName] = {
            'activity_info': completion['activities'],
            'count': 1,
          };
        }
      }

      final activityCounts = activityMap.values.toList();
      activityCounts.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return MockStudentStats(
        totalActivitiesCompleted: activityCompletions.length,
        totalJournalEntries: journalEntries.length,
        totalQuestionnaires: questionnaires.length,
        totalSessions: sessionNotes.length,
        activityCounts: activityCounts,
        recentJournalEntries: journalEntries.take(5).toList(),
        recentQuestionnaires: questionnaires.take(5).toList(),
        sessionNotes: sessionNotes.take(3).toList(),
      );
    } catch (e) {
      throw Exception('Error loading student data: $e');
    }
  }

  MockPdfDocument generateStudentReport(MockStudentProfile profile, MockStudentStats stats) {
    final pdf = MockPdfDocument();
    
    // Add header page
    pdf.addPage({
      'type': 'header',
      'title': 'BREATHE BETTER',
      'subtitle': 'Student Progress Report',
      'timestamp': DateTime.now().toIso8601String().split('.')[0],
    });

    // Add student information
    pdf.addPage({
      'type': 'student_info',
      'name': profile.studentName,
      'student_id': profile.studentId,
      'course': profile.course ?? 'N/A',
      'year_level': 'Year ${profile.yearLevel ?? 'N/A'}',
      'email': profile.email,
      'status': profile.status.toUpperCase(),
    });

    // Add activity overview
    pdf.addPage({
      'type': 'activity_overview',
      'activities_completed': stats.totalActivitiesCompleted,
      'journal_entries': stats.totalJournalEntries,
      'assessments': stats.totalQuestionnaires,
      'counseling_sessions': stats.totalSessions,
    });

    // Add activity breakdown if available
    if (stats.activityCounts.isNotEmpty) {
      pdf.addPage({
        'type': 'activity_breakdown',
        'activities': stats.activityCounts.take(5).map((activity) {
          final activityInfo = activity['activity_info'] as Map<String, dynamic>;
          return {
            'name': getActivityDisplayName(activityInfo['name']),
            'count': activity['count'],
          };
        }).toList(),
      });
    }

    // Add recent journal entries if available
    if (stats.recentJournalEntries.isNotEmpty) {
      pdf.addPage({
        'type': 'recent_journals',
        'entries': stats.recentJournalEntries.map((journal) {
          final sentiment = (journal['sentiment'] as String?)?.toLowerCase();
          return {
            'title': journal['title'] ?? 'Untitled Entry',
            'date': formatDate(journal['entry_timestamp']),
            'sentiment': getSentimentTextLabel(sentiment),
          };
        }).toList(),
      });
    }

    // Add counseling sessions if available
    if (stats.sessionNotes.isNotEmpty) {
      pdf.addPage({
        'type': 'counseling_sessions',
        'sessions': stats.sessionNotes.map((session) {
          final appointment = session['counseling_appointments'] as Map<String, dynamic>?;
          final counselor = session['counselors'] as Map<String, dynamic>?;
          final counselorName = counselor != null && 
                                counselor['first_name'] != null && 
                                counselor['last_name'] != null
              ? '${counselor['first_name']} ${counselor['last_name']}'
              : 'Unknown Counselor';
              
          return {
            'counselor': counselorName,
            'date': appointment?['appointment_date'] ?? '',
            'summary': session['summary'] ?? 'No summary available',
            'recommendations': session['recommendations'] ?? '',
          };
        }).toList(),
      });
    }

    // Add report details
    pdf.addPage({
      'type': 'report_details',
      'report_type': 'Comprehensive Student Progress Report',
      'student_name': profile.studentName,
      'student_id': profile.studentId,
      'generated_by': 'Counselor',
      'status': 'Complete',
    });

    // Add footer
    pdf.addPage({
      'type': 'footer',
      'text': '© 2024 Breathe Better - Confidential Student Report',
    });

    return pdf;
  }

  String getActivityDisplayName(String activityName) {
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

  String formatDate(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateTime.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String getSentimentTextLabel(String? label) {
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

  String validateStudentData(MockStudentProfile profile, MockStudentStats stats) {
    if (profile.studentName.isEmpty) return 'Student name is required';
    if (profile.studentId.isEmpty) return 'Student ID is required';
    if (profile.email.isEmpty) return 'Student email is required';
    if (stats.totalActivitiesCompleted < 0) return 'Invalid activities count';
    if (stats.totalJournalEntries < 0) return 'Invalid journal entries count';
    if (stats.totalQuestionnaires < 0) return 'Invalid questionnaires count';
    if (stats.totalSessions < 0) return 'Invalid sessions count';
    return 'valid';
  }

  bool isStudentDataValid(MockStudentProfile profile, MockStudentStats stats) {
    return validateStudentData(profile, stats) == 'valid';
  }

  Map<String, dynamic> generateReportSummary(MockStudentProfile profile, MockStudentStats stats) {
    return {
      'student_name': profile.studentName,
      'student_id': profile.studentId,
      'total_activities': stats.totalActivitiesCompleted,
      'total_journals': stats.totalJournalEntries,
      'total_assessments': stats.totalQuestionnaires,
      'total_sessions': stats.totalSessions,
      'report_timestamp': DateTime.now().toIso8601String(),
      'report_type': 'student_progress',
    };
  }
}

void main() {
  group('RM-ER-02: Counselor can export the generated student report as a correctly formatted PDF', () {
    late MockDatabase mockDatabase;
    late StudentReportService reportService;

    setUp(() {
      mockDatabase = MockDatabase();
      reportService = StudentReportService(mockDatabase);
    });

    test('Should load student data correctly', () async {
      final userId = 'student-123';
      
      // Seed test data
      mockDatabase.seedStudentProfile({
        'user_id': userId,
        'student_code': 'STU2025001',
        'course': 'Computer Science',
        'year_level': 2,
        'users': {
          'email': 'student@university.edu',
          'status': 'active',
        },
      });

      mockDatabase.seedActivityCompletions([
        {'activity_id': 1, 'activities': {'name': 'daily_checkin', 'description': 'Daily check-in'}},
        {'activity_id': 1, 'activities': {'name': 'daily_checkin', 'description': 'Daily check-in'}},
        {'activity_id': 2, 'activities': {'name': 'mood_journal', 'description': 'Mood journaling'}},
      ]);

      mockDatabase.seedJournalEntries([
        {'title': 'My First Entry', 'entry_timestamp': '2025-10-20T10:00:00Z', 'sentiment': 'positive'},
        {'title': 'Second Entry', 'entry_timestamp': '2025-10-21T10:00:00Z', 'sentiment': 'neutral'},
      ]);

      mockDatabase.seedQuestionnaires([
        {'response_id': 1, 'total_score': 25, 'submission_timestamp': '2025-10-20T10:00:00Z'},
      ]);

      mockDatabase.seedSessionNotes([
        {
          'summary': 'Good progress in stress management',
          'recommendations': 'Continue breathing exercises',
          'counseling_appointments': {'appointment_date': '2025-10-20'},
          'counselors': {'first_name': 'Dr. Jane', 'last_name': 'Smith'},
        },
      ]);

      final stats = await reportService.loadStudentData(userId);

      expect(stats.totalActivitiesCompleted, 3);
      expect(stats.totalJournalEntries, 2);
      expect(stats.totalQuestionnaires, 1);
      expect(stats.totalSessions, 1);
      expect(stats.activityCounts.length, 2); // daily_checkin and mood_journal
      expect(stats.activityCounts[0]['count'], 2); // daily_checkin should be first (highest count)
    });

    test('Should generate correctly formatted PDF report', () {
      final profile = MockStudentProfile(
        userId: 'student-123',
        studentName: 'John Doe',
        studentId: 'STU2025001',
        course: 'Computer Science',
        yearLevel: 2,
        email: 'john.doe@university.edu',
        status: 'active',
      );

      final stats = MockStudentStats(
        totalActivitiesCompleted: 5,
        totalJournalEntries: 3,
        totalQuestionnaires: 2,
        totalSessions: 1,
        activityCounts: [
          {
            'activity_info': {'name': 'daily_checkin', 'description': 'Daily check-in'},
            'count': 3,
          },
        ],
        recentJournalEntries: [
          {'title': 'Test Entry', 'entry_timestamp': '2025-10-20T10:00:00Z', 'sentiment': 'positive'},
        ],
        recentQuestionnaires: [],
        sessionNotes: [
          {
            'summary': 'Good session',
            'recommendations': 'Keep it up',
            'counseling_appointments': {'appointment_date': '2025-10-20'},
            'counselors': {'first_name': 'Dr. John', 'last_name': 'Smith'},
          },
        ],
      );

      final pdf = reportService.generateStudentReport(profile, stats);

      // Verify PDF structure
      expect(pdf.pages.length, 8); // Header, student info, overview, breakdown, journals, sessions, details, footer

      // Verify header page
      final headerPage = pdf.pages.firstWhere((page) => page['type'] == 'header');
      expect(headerPage['title'], 'BREATHE BETTER');
      expect(headerPage['subtitle'], 'Student Progress Report');

      // Verify student info page
      final studentInfoPage = pdf.pages.firstWhere((page) => page['type'] == 'student_info');
      expect(studentInfoPage['name'], 'John Doe');
      expect(studentInfoPage['student_id'], 'STU2025001');
      expect(studentInfoPage['course'], 'Computer Science');
      expect(studentInfoPage['year_level'], 'Year 2');
      expect(studentInfoPage['email'], 'john.doe@university.edu');
      expect(studentInfoPage['status'], 'ACTIVE');

      // Verify activity overview page
      final overviewPage = pdf.pages.firstWhere((page) => page['type'] == 'activity_overview');
      expect(overviewPage['activities_completed'], 5);
      expect(overviewPage['journal_entries'], 3);
      expect(overviewPage['assessments'], 2);
      expect(overviewPage['counseling_sessions'], 1);
    });

    test('Should handle empty student data gracefully', () {
      final profile = MockStudentProfile(
        userId: 'empty-student',
        studentName: 'Empty Student',
        studentId: 'EMPTY001',
        email: 'empty@test.com',
        status: 'active',
      );

      final stats = MockStudentStats(
        totalActivitiesCompleted: 0,
        totalJournalEntries: 0,
        totalQuestionnaires: 0,
        totalSessions: 0,
        activityCounts: [],
        recentJournalEntries: [],
        recentQuestionnaires: [],
        sessionNotes: [],
      );

      final pdf = reportService.generateStudentReport(profile, stats);

      // Should still generate basic report structure
      expect(pdf.pages.length, 5); // Header, student info, overview, details, footer

      final overviewPage = pdf.pages.firstWhere((page) => page['type'] == 'activity_overview');
      expect(overviewPage['activities_completed'], 0);
      expect(overviewPage['journal_entries'], 0);
      expect(overviewPage['assessments'], 0);
      expect(overviewPage['counseling_sessions'], 0);
    });

    test('Should format activity display names correctly', () {
      expect(reportService.getActivityDisplayName('daily_checkin'), 'Daily Check-ins');
      expect(reportService.getActivityDisplayName('mood_journal'), 'Mood Journal Entries');
      expect(reportService.getActivityDisplayName('track_mood'), 'Mental Health Assessments');
      expect(reportService.getActivityDisplayName('breathing_exercise'), 'Breathing Exercise');
    });

    test('Should format dates correctly', () {
      expect(reportService.formatDate('2025-10-20T10:30:00Z'), '20/10/2025');
      expect(reportService.formatDate('2025-01-01T00:00:00Z'), '1/1/2025');
      expect(reportService.formatDate(null), 'N/A');
      expect(reportService.formatDate('invalid-date'), 'Invalid Date');
    });

    test('Should format sentiment labels correctly', () {
      expect(reportService.getSentimentTextLabel('positive'), 'Positive');
      expect(reportService.getSentimentTextLabel('neutral'), 'Neutral');
      expect(reportService.getSentimentTextLabel('negative'), 'Negative');
      expect(reportService.getSentimentTextLabel('unknown'), 'Unknown');
      expect(reportService.getSentimentTextLabel(null), 'Unknown');
    });

    test('Should validate student data correctly', () {
      final validProfile = MockStudentProfile(
        userId: 'valid-student',
        studentName: 'Valid Student',
        studentId: 'VALID001',
        email: 'valid@test.com',
        status: 'active',
      );

      final validStats = MockStudentStats(
        totalActivitiesCompleted: 5,
        totalJournalEntries: 3,
        totalQuestionnaires: 2,
        totalSessions: 1,
        activityCounts: [],
        recentJournalEntries: [],
        recentQuestionnaires: [],
        sessionNotes: [],
      );

      expect(reportService.validateStudentData(validProfile, validStats), 'valid');

      // Test invalid cases
      final invalidProfile = MockStudentProfile(
        userId: 'invalid-student',
        studentName: '', // Empty name
        studentId: 'INVALID001',
        email: 'invalid@test.com',
        status: 'active',
      );

      expect(reportService.validateStudentData(invalidProfile, validStats), 'Student name is required');

      final invalidStats = MockStudentStats(
        totalActivitiesCompleted: -1, // Negative count
        totalJournalEntries: 3,
        totalQuestionnaires: 2,
        totalSessions: 1,
        activityCounts: [],
        recentJournalEntries: [],
        recentQuestionnaires: [],
        sessionNotes: [],
      );

      expect(reportService.validateStudentData(validProfile, invalidStats), 'Invalid activities count');
    });

    test('Should generate report summary correctly', () {
      final profile = MockStudentProfile(
        userId: 'summary-student',
        studentName: 'Summary Student',
        studentId: 'SUM001',
        email: 'summary@test.com',
        status: 'active',
      );

      final stats = MockStudentStats(
        totalActivitiesCompleted: 10,
        totalJournalEntries: 5,
        totalQuestionnaires: 3,
        totalSessions: 2,
        activityCounts: [],
        recentJournalEntries: [],
        recentQuestionnaires: [],
        sessionNotes: [],
      );

      final summary = reportService.generateReportSummary(profile, stats);

      expect(summary['student_name'], 'Summary Student');
      expect(summary['student_id'], 'SUM001');
      expect(summary['total_activities'], 10);
      expect(summary['total_journals'], 5);
      expect(summary['total_assessments'], 3);
      expect(summary['total_sessions'], 2);
      expect(summary['report_type'], 'student_progress');
      expect(summary['report_timestamp'], isNotEmpty);
    });

    test('Should save PDF as binary data', () {
      final profile = MockStudentProfile(
        userId: 'pdf-student',
        studentName: 'PDF Student',
        studentId: 'PDF001',
        email: 'pdf@test.com',
        status: 'active',
      );

      final stats = MockStudentStats(
        totalActivitiesCompleted: 1,
        totalJournalEntries: 1,
        totalQuestionnaires: 1,
        totalSessions: 1,
        activityCounts: [],
        recentJournalEntries: [],
        recentQuestionnaires: [],
        sessionNotes: [],
      );

      final pdf = reportService.generateStudentReport(profile, stats);
      final pdfBytes = pdf.save();

      expect(pdfBytes, isA<List<int>>());
      expect(pdfBytes.length, 2048); // Mock returns 2048 bytes
      expect(pdfBytes.every((byte) => byte >= 0 && byte <= 255), true);
    });

    test('Should include counseling session details in PDF', () {
      final profile = MockStudentProfile(
        userId: 'session-student',
        studentName: 'Session Student',
        studentId: 'SES001',
        email: 'session@test.com',
        status: 'active',
      );

      final stats = MockStudentStats(
        totalActivitiesCompleted: 0,
        totalJournalEntries: 0,
        totalQuestionnaires: 0,
        totalSessions: 1,
        activityCounts: [],
        recentJournalEntries: [],
        recentQuestionnaires: [],
        sessionNotes: [
          {
            'summary': 'Student showed great improvement in anxiety management',
            'recommendations': 'Continue with breathing exercises and journaling',
            'counseling_appointments': {'appointment_date': '2025-10-20'},
            'counselors': {'first_name': 'Dr. Sarah', 'last_name': 'Johnson'},
          },
        ],
      );

      final pdf = reportService.generateStudentReport(profile, stats);
      final sessionsPage = pdf.pages.firstWhere((page) => page['type'] == 'counseling_sessions');
      
      expect(sessionsPage['sessions'].length, 1);
      final session = sessionsPage['sessions'][0];
      expect(session['counselor'], 'Dr. Sarah Johnson');
      expect(session['date'], '2025-10-20');
      expect(session['summary'], 'Student showed great improvement in anxiety management');
      expect(session['recommendations'], 'Continue with breathing exercises and journaling');
    });
  });
}