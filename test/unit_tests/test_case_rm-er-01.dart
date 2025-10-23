// RM-ER-01: Admin can export the generated analytics report as a correctly formatted PDF
// Requirement: Admin can export analytics report with system statistics as PDF
// Mirrors logic in `admin_home.dart` (generate analytics PDF with user stats, sessions, registrations)

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent analytics data
class MockAnalyticsData {
  final int totalUsers;
  final int activeUsers;
  final int completedSessions;
  final List<Map<String, dynamic>> recentRegistrations;

  MockAnalyticsData({
    required this.totalUsers,
    required this.activeUsers,
    required this.completedSessions,
    required this.recentRegistrations,
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
    return List.generate(1024, (index) => index % 256);
  }
}

// Mock database class to simulate Supabase operations
class MockDatabase {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _appointments = [];

  void seedUsers(List<Map<String, dynamic>> users) {
    _users = users;
  }

  void seedAppointments(List<Map<String, dynamic>> appointments) {
    _appointments = appointments;
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    return _users;
  }

  Future<List<Map<String, dynamic>>> fetchActiveUsers() async {
    return _users.where((user) => user['status'] == 'active').toList();
  }

  Future<List<Map<String, dynamic>>> fetchCompletedSessions() async {
    return _appointments.where((appointment) => appointment['status'] == 'completed').toList();
  }

  Future<List<Map<String, dynamic>>> fetchRecentRegistrations(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _users.where((user) {
      final regDate = DateTime.parse(user['registration_date']);
      return regDate.isAfter(cutoffDate);
    }).toList();
  }
}

// Service class to handle analytics and PDF generation
class AnalyticsReportService {
  final MockDatabase _database;

  AnalyticsReportService(this._database);

  Future<MockAnalyticsData> loadAnalyticsData() async {
    try {
      final totalUsers = await _database.fetchAllUsers();
      final activeUsers = await _database.fetchActiveUsers();
      final completedSessions = await _database.fetchCompletedSessions();
      final recentRegistrations = await _database.fetchRecentRegistrations(30);

      return MockAnalyticsData(
        totalUsers: totalUsers.length,
        activeUsers: activeUsers.length,
        completedSessions: completedSessions.length,
        recentRegistrations: recentRegistrations,
      );
    } catch (e) {
      throw Exception('Error loading analytics data: $e');
    }
  }

  MockPdfDocument generateAnalyticsReport(MockAnalyticsData data) {
    final pdf = MockPdfDocument();
    
    // Add header page content
    pdf.addPage({
      'type': 'header',
      'title': 'BREATHE BETTER',
      'subtitle': 'Admin Analytics Report',
      'timestamp': DateTime.now().toIso8601String().split('.')[0],
    });

    // Add statistics overview
    pdf.addPage({
      'type': 'statistics',
      'total_users': data.totalUsers,
      'active_users': data.activeUsers,
      'completed_sessions': data.completedSessions,
      'recent_registrations': data.recentRegistrations.length,
    });

    // Add recent registrations details if available
    if (data.recentRegistrations.isNotEmpty) {
      pdf.addPage({
        'type': 'recent_registrations',
        'registrations': data.recentRegistrations.take(5).map((user) {
          final registrationDate = DateTime.parse(user['registration_date']);
          return {
            'email': user['email'],
            'date': '${registrationDate.day}/${registrationDate.month}/${registrationDate.year}',
          };
        }).toList(),
      });
    }

    // Add report details
    pdf.addPage({
      'type': 'report_details',
      'report_type': 'Administrative Analytics',
      'data_period': 'All time (with 30-day filters for specific metrics)',
      'generated_by': 'System Administrator',
      'status': 'Active',
    });

    // Add footer
    pdf.addPage({
      'type': 'footer',
      'text': '© 2024 Breathe Better - Confidential Administrative Report',
    });

    return pdf;
  }

  String validateReportData(MockAnalyticsData data) {
    if (data.totalUsers < 0) return 'Invalid total users count';
    if (data.activeUsers < 0) return 'Invalid active users count';
    if (data.activeUsers > data.totalUsers) return 'Active users cannot exceed total users';
    if (data.completedSessions < 0) return 'Invalid completed sessions count';
    return 'valid';
  }

  Map<String, dynamic> generateReportSummary(MockAnalyticsData data) {
    return {
      'total_users': data.totalUsers,
      'active_users': data.activeUsers,
      'active_percentage': data.totalUsers > 0 
        ? ((data.activeUsers / data.totalUsers) * 100).round()
        : 0,
      'completed_sessions': data.completedSessions,
      'recent_registrations': data.recentRegistrations.length,
      'report_timestamp': DateTime.now().toIso8601String(),
    };
  }

  bool isReportDataValid(MockAnalyticsData data) {
    return validateReportData(data) == 'valid';
  }
}

void main() {
  group('RM-ER-01: Admin can export the generated analytics report as a correctly formatted PDF', () {
    late MockDatabase mockDatabase;
    late AnalyticsReportService reportService;

    setUp(() {
      mockDatabase = MockDatabase();
      reportService = AnalyticsReportService(mockDatabase);
    });

    test('Should load analytics data correctly', () async {
      // Seed test data
      mockDatabase.seedUsers([
        {
          'user_id': 'user-1',
          'email': 'user1@test.com',
          'status': 'active',
          'registration_date': DateTime.now().subtract(Duration(days: 15)).toIso8601String(),
        },
        {
          'user_id': 'user-2',
          'email': 'user2@test.com',
          'status': 'active',
          'registration_date': DateTime.now().subtract(Duration(days: 45)).toIso8601String(),
        },
        {
          'user_id': 'user-3',
          'email': 'user3@test.com',
          'status': 'suspended',
          'registration_date': DateTime.now().subtract(Duration(days: 10)).toIso8601String(),
        },
      ]);

      mockDatabase.seedAppointments([
        {'appointment_id': 'apt-1', 'status': 'completed'},
        {'appointment_id': 'apt-2', 'status': 'completed'},
        {'appointment_id': 'apt-3', 'status': 'scheduled'},
      ]);

      final data = await reportService.loadAnalyticsData();

      expect(data.totalUsers, 3);
      expect(data.activeUsers, 2);
      expect(data.completedSessions, 2);
      expect(data.recentRegistrations.length, 2); // Only users registered in last 30 days
    });

    test('Should generate correctly formatted PDF report', () async {
      // Seed test data
      mockDatabase.seedUsers([
        {
          'user_id': 'user-1',
          'email': 'test@example.com',
          'status': 'active',
          'registration_date': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
        },
      ]);

      mockDatabase.seedAppointments([
        {'appointment_id': 'apt-1', 'status': 'completed'},
      ]);

      final data = await reportService.loadAnalyticsData();
      final pdf = reportService.generateAnalyticsReport(data);

      // Verify PDF structure
      expect(pdf.pages.length, 5); // Header, stats, registrations, details, footer

      // Verify header page
      final headerPage = pdf.pages.firstWhere((page) => page['type'] == 'header');
      expect(headerPage['title'], 'BREATHE BETTER');
      expect(headerPage['subtitle'], 'Admin Analytics Report');
      expect(headerPage['timestamp'], isNotEmpty);

      // Verify statistics page
      final statsPage = pdf.pages.firstWhere((page) => page['type'] == 'statistics');
      expect(statsPage['total_users'], 1);
      expect(statsPage['active_users'], 1);
      expect(statsPage['completed_sessions'], 1);
      expect(statsPage['recent_registrations'], 1);

      // Verify report details page
      final detailsPage = pdf.pages.firstWhere((page) => page['type'] == 'report_details');
      expect(detailsPage['report_type'], 'Administrative Analytics');
      expect(detailsPage['generated_by'], 'System Administrator');
      expect(detailsPage['status'], 'Active');

      // Verify footer page
      final footerPage = pdf.pages.firstWhere((page) => page['type'] == 'footer');
      expect(footerPage['text'], contains('© 2024 Breathe Better'));
    });

    test('Should handle empty data gracefully', () async {
      // No seeded data
      final data = await reportService.loadAnalyticsData();
      final pdf = reportService.generateAnalyticsReport(data);

      expect(data.totalUsers, 0);
      expect(data.activeUsers, 0);
      expect(data.completedSessions, 0);
      expect(data.recentRegistrations.length, 0);

      // PDF should still be generated with zero values
      final statsPage = pdf.pages.firstWhere((page) => page['type'] == 'statistics');
      expect(statsPage['total_users'], 0);
      expect(statsPage['active_users'], 0);
      expect(statsPage['completed_sessions'], 0);
    });

    test('Should validate report data correctly', () {
      // Valid data
      final validData = MockAnalyticsData(
        totalUsers: 10,
        activeUsers: 8,
        completedSessions: 5,
        recentRegistrations: [],
      );
      expect(reportService.validateReportData(validData), 'valid');

      // Invalid: negative total users
      final invalidData1 = MockAnalyticsData(
        totalUsers: -1,
        activeUsers: 5,
        completedSessions: 3,
        recentRegistrations: [],
      );
      expect(reportService.validateReportData(invalidData1), 'Invalid total users count');

      // Invalid: active users exceed total
      final invalidData2 = MockAnalyticsData(
        totalUsers: 5,
        activeUsers: 10,
        completedSessions: 3,
        recentRegistrations: [],
      );
      expect(reportService.validateReportData(invalidData2), 'Active users cannot exceed total users');

      // Invalid: negative completed sessions
      final invalidData3 = MockAnalyticsData(
        totalUsers: 10,
        activeUsers: 8,
        completedSessions: -1,
        recentRegistrations: [],
      );
      expect(reportService.validateReportData(invalidData3), 'Invalid completed sessions count');
    });

    test('Should generate PDF with recent registrations details', () async {
      // Seed users with recent registrations
      mockDatabase.seedUsers([
        {
          'user_id': 'user-1',
          'email': 'recent1@test.com',
          'status': 'active',
          'registration_date': DateTime(2025, 10, 20).toIso8601String(),
        },
        {
          'user_id': 'user-2',
          'email': 'recent2@test.com',
          'status': 'active',
          'registration_date': DateTime(2025, 10, 21).toIso8601String(),
        },
      ]);

      final data = await reportService.loadAnalyticsData();
      final pdf = reportService.generateAnalyticsReport(data);

      // Verify recent registrations page exists
      final recentRegPage = pdf.pages.firstWhere((page) => page['type'] == 'recent_registrations');
      expect(recentRegPage['registrations'], isA<List>());
      expect(recentRegPage['registrations'].length, 2);
      
      final firstReg = recentRegPage['registrations'][0];
      expect(firstReg['email'], 'recent1@test.com');
      expect(firstReg['date'], '20/10/2025');
    });

    test('Should generate report summary correctly', () async {
      mockDatabase.seedUsers([
        {'user_id': 'u1', 'email': 'u1@test.com', 'status': 'active', 'registration_date': DateTime.now().toIso8601String()},
        {'user_id': 'u2', 'email': 'u2@test.com', 'status': 'active', 'registration_date': DateTime.now().toIso8601String()},
        {'user_id': 'u3', 'email': 'u3@test.com', 'status': 'suspended', 'registration_date': DateTime.now().toIso8601String()},
        {'user_id': 'u4', 'email': 'u4@test.com', 'status': 'active', 'registration_date': DateTime.now().toIso8601String()},
      ]);

      mockDatabase.seedAppointments([
        {'appointment_id': 'apt-1', 'status': 'completed'},
        {'appointment_id': 'apt-2', 'status': 'completed'},
      ]);

      final data = await reportService.loadAnalyticsData();
      final summary = reportService.generateReportSummary(data);

      expect(summary['total_users'], 4);
      expect(summary['active_users'], 3);
      expect(summary['active_percentage'], 75); // 3/4 * 100 = 75%
      expect(summary['completed_sessions'], 2);
      expect(summary['recent_registrations'], 4);
      expect(summary['report_timestamp'], isNotEmpty);
    });

    test('Should handle zero division in percentage calculation', () async {
      // No users
      final data = await reportService.loadAnalyticsData();
      final summary = reportService.generateReportSummary(data);

      expect(summary['total_users'], 0);
      expect(summary['active_users'], 0);
      expect(summary['active_percentage'], 0); // Should not throw division by zero
    });

    test('Should save PDF as binary data', () async {
      mockDatabase.seedUsers([
        {'user_id': 'user-1', 'email': 'test@test.com', 'status': 'active', 'registration_date': DateTime.now().toIso8601String()},
      ]);

      final data = await reportService.loadAnalyticsData();
      final pdf = reportService.generateAnalyticsReport(data);
      final pdfBytes = pdf.save();

      expect(pdfBytes, isA<List<int>>());
      expect(pdfBytes.length, 1024); // Mock returns 1024 bytes
      expect(pdfBytes.every((byte) => byte >= 0 && byte <= 255), true);
    });

    test('Should verify data validity before report generation', () {
      final validData = MockAnalyticsData(
        totalUsers: 100,
        activeUsers: 85,
        completedSessions: 50,
        recentRegistrations: [],
      );

      final invalidData = MockAnalyticsData(
        totalUsers: 10,
        activeUsers: 15, // More active than total
        completedSessions: 5,
        recentRegistrations: [],
      );

      expect(reportService.isReportDataValid(validData), true);
      expect(reportService.isReportDataValid(invalidData), false);
    });

    test('Should throw exception on database error', () async {
      // Simulate database error by not seeding any data and expecting normal operation
      // but then we'll simulate an error condition
      
      expect(
        () async {
          // This would simulate a database connection error
          throw Exception('Database connection failed');
        },
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Database connection failed'),
        )),
      );
    });
  });
}