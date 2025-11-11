// UPD-PD-01: A logged-in user's dashboard displays role-specific metrics and a welcome message
// Requirement: The dashboard loads with a personalized greeting and widgets relevant to the user's role
// This test simulates the dashboard loading logic for different user types

import 'package:flutter_test/flutter_test.dart';

class MockUser {
  final String email;
  final String id;
  final String userType;
  final DateTime? emailConfirmedAt;
  MockUser({required this.email, required this.id, required this.userType, this.emailConfirmedAt});
}

class MockDashboardWidget {
  final String widgetType;
  final String title;
  final Map<String, dynamic> data;
  final bool isVisible;

  MockDashboardWidget({
    required this.widgetType,
    required this.title,
    required this.data,
    required this.isVisible,
  });
}

class MockDashboardData {
  final String welcomeMessage;
  final String userName;
  final List<MockDashboardWidget> widgets;
  final Map<String, dynamic> metrics;

  MockDashboardData({
    required this.welcomeMessage,
    required this.userName,
    required this.widgets,
    required this.metrics,
  });
}

Future<MockUser> mockAuthenticateUser({required String email, required String password, required String userType}) async {
  if (password == 'validpass') {
    return MockUser(email: email, id: '$userType-id', userType: userType, emailConfirmedAt: DateTime.now());
  }
  throw Exception('Invalid login credentials');
}

Future<MockDashboardData> mockLoadDashboardData({required String userId, required String userType}) async {
  String userName;
  String welcomeMessage;
  List<MockDashboardWidget> widgets;
  Map<String, dynamic> metrics;

  switch (userType) {
    case 'student':
      userName = 'John Doe';
      welcomeMessage = 'Hi, $userName!';
      widgets = [
        MockDashboardWidget(
          widgetType: 'progress',
          title: "Today's Progress",
          data: {'completion': 0.65, 'activities': ['mood_journal', 'daily_checkin']},
          isVisible: true,
        ),
        MockDashboardWidget(
          widgetType: 'mood_checkin',
          title: 'Daily Mood Check-in',
          data: {'last_checkin': '2024-01-15', 'streak': 7},
          isVisible: true,
        ),
        MockDashboardWidget(
          widgetType: 'quick_actions',
          title: 'Quick Actions',
          data: {'actions': ['Take Questionnaire', 'Breathing Exercises', 'Journal Entry']},
          isVisible: true,
        ),
      ];
      metrics = {
        'unread_messages': 3,
        'upcoming_appointments': 1,
        'journal_entries': 25,
      };
      break;

    case 'counselor':
      userName = 'Dr. Sarah Smith';
      welcomeMessage = userName;
      widgets = [
        MockDashboardWidget(
          widgetType: 'appointments',
          title: 'Pending Requests',
          data: {'pending_count': 5, 'today_sessions': 3},
          isVisible: true,
        ),
        MockDashboardWidget(
          widgetType: 'student_stats',
          title: 'Student Statistics',
          data: {'total_students': 45, 'active_students': 38},
          isVisible: true,
        ),
        MockDashboardWidget(
          widgetType: 'schedule',
          title: "Today's Schedule",
          data: {'appointments': [{'time': '10:00 AM', 'student': 'Student A'}]},
          isVisible: true,
        ),
      ];
      metrics = {
        'pending_appointments': 5,
        'completed_sessions': 125,
        'total_students': 45,
      };
      break;

    case 'admin':
      userName = 'Administrator';
      welcomeMessage = 'Welcome, $userName';
      widgets = [
        MockDashboardWidget(
          widgetType: 'system_stats',
          title: 'System Overview',
          data: {'total_users': 250, 'active_users': 180},
          isVisible: true,
        ),
        MockDashboardWidget(
          widgetType: 'recent_activity',
          title: 'Recent Activity',
          data: {'registrations': 5, 'appointments': 12},
          isVisible: true,
        ),
        MockDashboardWidget(
          widgetType: 'quick_management',
          title: 'Quick Management',
          data: {'actions': ['User Management', 'Resource Management', 'Reports']},
          isVisible: true,
        ),
      ];
      metrics = {
        'total_users': 250,
        'active_users': 180,
        'completed_appointments': 890,
      };
      break;

    default:
      throw Exception('Invalid user type');
  }

  return MockDashboardData(
    welcomeMessage: welcomeMessage,
    userName: userName,
    widgets: widgets,
    metrics: metrics,
  );
}

void main() {
  group('UPD-PD-01: A logged-in user\'s dashboard displays role-specific metrics and welcome message', () {
    test('Student dashboard loads with personalized greeting and student-specific widgets', () async {
      final user = await mockAuthenticateUser(
        email: 'student@college.edu',
        password: 'validpass',
        userType: 'student',
      );
      expect(user.userType, 'student');

      final dashboardData = await mockLoadDashboardData(userId: user.id, userType: user.userType);

      expect(dashboardData.welcomeMessage, 'Hi, John Doe!');
      expect(dashboardData.userName, 'John Doe');
      expect(dashboardData.widgets.length, 3);

      final widgetTypes = dashboardData.widgets.map((w) => w.widgetType).toList();
      expect(widgetTypes, contains('progress'));
      expect(widgetTypes, contains('mood_checkin'));
      expect(widgetTypes, contains('quick_actions'));

      expect(dashboardData.metrics['unread_messages'], 3);
      expect(dashboardData.metrics['upcoming_appointments'], 1);
      expect(dashboardData.metrics['journal_entries'], 25);
    });

    test('Counselor dashboard loads with professional greeting and counselor-specific widgets', () async {
      final user = await mockAuthenticateUser(
        email: 'counselor@college.edu',
        password: 'validpass',
        userType: 'counselor',
      );
      expect(user.userType, 'counselor');

      final dashboardData = await mockLoadDashboardData(userId: user.id, userType: user.userType);

      expect(dashboardData.welcomeMessage, 'Dr. Sarah Smith');
      expect(dashboardData.userName, 'Dr. Sarah Smith');
      expect(dashboardData.widgets.length, 3);

      final widgetTypes = dashboardData.widgets.map((w) => w.widgetType).toList();
      expect(widgetTypes, contains('appointments'));
      expect(widgetTypes, contains('student_stats'));
      expect(widgetTypes, contains('schedule'));

      expect(dashboardData.metrics['pending_appointments'], 5);
      expect(dashboardData.metrics['completed_sessions'], 125);
      expect(dashboardData.metrics['total_students'], 45);
    });

    test('Admin dashboard loads with administrative greeting and admin-specific widgets', () async {
      final user = await mockAuthenticateUser(
        email: 'admin@college.edu',
        password: 'validpass',
        userType: 'admin',
      );
      expect(user.userType, 'admin');

      final dashboardData = await mockLoadDashboardData(userId: user.id, userType: user.userType);

      expect(dashboardData.welcomeMessage, 'Welcome, Administrator');
      expect(dashboardData.userName, 'Administrator');
      expect(dashboardData.widgets.length, 3);

      final widgetTypes = dashboardData.widgets.map((w) => w.widgetType).toList();
      expect(widgetTypes, contains('system_stats'));
      expect(widgetTypes, contains('recent_activity'));
      expect(widgetTypes, contains('quick_management'));

      expect(dashboardData.metrics['total_users'], 250);
      expect(dashboardData.metrics['active_users'], 180);
      expect(dashboardData.metrics['completed_appointments'], 890);
    });

    test('All dashboard widgets are marked as visible and contain required data', () async {
      final user = await mockAuthenticateUser(
        email: 'student@college.edu',
        password: 'validpass',
        userType: 'student',
      );

      final dashboardData = await mockLoadDashboardData(userId: user.id, userType: user.userType);

      for (var widget in dashboardData.widgets) {
        expect(widget.isVisible, true);
        expect(widget.title, isNotEmpty);
        expect(widget.data, isNotEmpty);
        expect(widget.widgetType, isNotEmpty);
      }
    });

    test('Dashboard data is role-specific and does not contain cross-role widgets', () async {
      final studentUser = await mockAuthenticateUser(
        email: 'student@college.edu',
        password: 'validpass',
        userType: 'student',
      );

      final counselorUser = await mockAuthenticateUser(
        email: 'counselor@college.edu',
        password: 'validpass',
        userType: 'counselor',
      );

      final studentDashboard = await mockLoadDashboardData(userId: studentUser.id, userType: studentUser.userType);
      final counselorDashboard = await mockLoadDashboardData(userId: counselorUser.id, userType: counselorUser.userType);

      final studentWidgetTypes = studentDashboard.widgets.map((w) => w.widgetType).toList();
      final counselorWidgetTypes = counselorDashboard.widgets.map((w) => w.widgetType).toList();

      expect(studentWidgetTypes, isNot(contains('appointments')));
      expect(studentWidgetTypes, isNot(contains('student_stats')));
      expect(counselorWidgetTypes, isNot(contains('progress')));
      expect(counselorWidgetTypes, isNot(contains('mood_checkin')));
    });

    test('Invalid user type throws exception', () async {
      final user = MockUser(email: 'test@test.com', id: 'invalid-id', userType: 'invalid');

      expect(() => mockLoadDashboardData(userId: user.id, userType: user.userType), throwsException);
    });

    test('Invalid credentials prevent dashboard loading', () async {
      expect(
        () => mockAuthenticateUser(email: 'user@test.com', password: 'wrongpass', userType: 'student'),
        throwsException,
      );
    });
  });
}
