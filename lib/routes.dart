// routes.dart

import 'package:flutter/material.dart';
import 'widgets/auth_guard.dart';

import 'pages/login_page.dart';
import 'pages/signup_page.dart';

import 'pages/counselor/counselor_profile_setup.dart';

//student
import 'pages/student/student_home.dart';
import 'pages/student/student_breathing_exercises.dart';
import 'pages/student/student_mental_health_resources.dart';
import 'pages/student/student_mtq.dart';
import 'pages/student/student_mood_journal.dart';
import 'pages/student/student_chatbot.dart';
import 'pages/student/student_profile.dart';
import 'pages/student/student_counselors.dart';
import 'pages/student/student_appointments.dart';
import 'pages/student/questionnaire_summary.dart';
import 'pages/student/questionnaire_history.dart';
import 'pages/student/student_daily_checkin.dart';
import 'pages/student/student_journal_entries.dart';
import 'pages/student/counselor_profile_view.dart';
import 'pages/student/student_contacts.dart';
import 'pages/student/student_chat_list.dart';
import 'pages/chat/appointment_chat.dart';
import 'models/appointment.dart';

//admin
import 'pages/admin/admin_home.dart';
import 'pages/admin/admin_accounts.dart';
import 'pages/admin/admin_users.dart';
import 'pages/admin/admin_resources.dart';
import 'pages/admin/admin_exercises.dart';
import 'pages/admin/admin_notifications.dart';
import 'pages/admin/admin_settings.dart';
import 'pages/admin/admin_profile.dart';
import 'pages/admin/admin_questionnaire.dart';
import 'pages/admin/admin_hotlines.dart';
import 'pages/counselor/counselor_home.dart';
import 'pages/counselor/counselor_settings.dart';
import 'pages/counselor/student_history.dart';
import 'pages/counselor/student_overview.dart';

// page routes
final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => const LoginPage(),
  '/signup': (context) => const SignUpPage(),

  //home page routes
  'student-home': (context) => const AuthGuard(child: StudentHome()),
  'admin-home': (context) => const AuthGuard(child: AdminHome()),
  'counselor-home': (context) => const AuthGuard(child: CounselorHome()),

  //profile
  '/student-profile': (context) => const AuthGuard(child: StudentProfile()),

  //student page routes
  'student-mtq': (context) => const AuthGuard(child: StudentMtq()),
  'questionnaire-summary': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(
          child: Text('Error: Missing required arguments'),
        ),
      );
    }
    return AuthGuard(
      child: QuestionnaireSummary(
        responseId: args['responseId'] as int,
        totalScore: args['totalScore'] as int,
      ),
    );
  },
  'questionnaire-history': (context) =>
      const AuthGuard(child: QuestionnaireHistory()),
  'student-breathing-exercises': (context) =>
      const AuthGuard(child: StudentBreathingExercises()),
  'student-mood-journal': (context) =>
      const AuthGuard(child: StudentJournalEntries()),
  'student-mood-journal-write': (context) =>
      const AuthGuard(child: StudentMoodJournal()),
  'student-mental-health-resources': (context) =>
      const AuthGuard(child: StudentMentalHealthResources()),
  'student-chatbot': (context) => const AuthGuard(child: StudentChatbot()),
  'student-counselors': (context) =>
      const AuthGuard(child: StudentCounselors()),
  'student-contacts': (context) =>
      const AuthGuard(child: StudentContactsPage()),
  'student-appointments': (context) =>
      const AuthGuard(child: StudentAppointments()),
  '/student-daily-checkin': (context) =>
      const AuthGuard(child: StudentDailyCheckInPage()),
  'student-journal-entries': (context) =>
      const AuthGuard(child: StudentJournalEntries()),
  'student-chat-list': (context) => const AuthGuard(child: StudentChatList()),
  '/appointment-chat': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(child: Text('Error: Missing chat arguments')),
      );
    }

    final appointmentId = args['appointmentId'] as int?;
    final counselorName = args['counselorName'] as String?;

    if (appointmentId == null ||
        counselorName == null ||
        counselorName == null ||
        counselorName.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Error: Invalid or missing chat arguments')),
      );
    }

    // Create a dummy appointment object for the chat
    final appointment = Appointment(
      id: appointmentId,
      counselorId: 0, // This will be filled from the database if needed
      userId: '', // Will be filled from current user
      appointmentDate: DateTime.now(),
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      status: 'accepted',
      counselorName: counselorName,
    );

    return AuthGuard(
      child: AppointmentChat(
        appointment: appointment,
        isCounselor: false,
      ),
    );
  },
  '/counselor-profile-view': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(child: Text('Error: Missing counselorId')),
      );
    }
    final id = args['counselorId'];
    if (id is! int) {
      return const Scaffold(
        body: Center(child: Text('Error: Invalid counselorId')),
      );
    }
    return AuthGuard(child: CounselorProfileView(counselorId: id));
  },
  'counselor-profile-view': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(child: Text('Error: Missing counselorId')),
      );
    }
    final id = args['counselorId'];
    if (id is! int) {
      return const Scaffold(
        body: Center(child: Text('Error: Invalid counselorId')),
      );
    }
    return AuthGuard(child: CounselorProfileView(counselorId: id));
  },

  // admin page routes
  'admin-accounts': (context) => const AuthGuard(child: AdminAccounts()),
  'admin-users': (context) => const AuthGuard(child: AdminUsers()),
  'admin-resources': (context) => const AuthGuard(child: AdminResources()),
  'admin-exercises': (context) => const AuthGuard(child: AdminExercises()),
  'admin-notifications': (context) =>
      const AuthGuard(child: AdminNotifications()),
  'admin-settings': (context) => const AuthGuard(child: AdminSettings()),
  'admin-profile': (context) => const AuthGuard(child: AdminProfile()),
  '/admin-questionnaire': (context) =>
      const AuthGuard(child: AdminQuestionnaire()),
  'admin-hotlines': (context) => const AuthGuard(child: AdminHotlines()),

  // counselor page routes
  '/counselor-profile': (context) =>
      const AuthGuard(child: CounselorProfileSetup()),
  '/counselor-profile-setup': (context) =>
      const AuthGuard(child: CounselorProfileSetup()),
  'counselor-settings': (context) =>
      const AuthGuard(child: CounselorSettings()),
  '/student-history': (context) => AuthGuard(
        child: StudentHistory(
          userId: (ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>)['userId'] as String,
          studentName: (ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>)['studentName'] as String,
          studentId: (ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>)['studentId'] as String,
        ),
      ),
};
