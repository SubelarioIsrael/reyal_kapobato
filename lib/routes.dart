// routes.dart

import 'package:flutter/material.dart';
import 'widgets/auth_guard.dart';

import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/reset_password_page.dart';

import 'pages/counselor_new/counselor_first_setup.dart';
import 'pages/counselor_new/counselor_profile.dart';

import 'pages/student_new/student_home.dart';
import 'pages/student_new/student_questionnaire.dart';
import 'pages/student_new/student_daily_checkin.dart';
import 'pages/student_new/student_journal_entries.dart';
import 'pages/student_new/student_checkin_history.dart';
import 'pages/student_new/student_breathing_exercises.dart';
import 'pages/student_new/student_support_contacts.dart';
import 'pages/student_new/student_wellness_resources.dart';
import 'pages/student_new/student_chats.dart';

//student
import 'pages/student/student_mood_journal.dart';
import 'pages/student/student_chatbot.dart';
import 'pages/student/student_profile.dart';
import 'pages/student/student_counselors.dart';
import 'pages/student/student_appointments.dart';
import 'pages/student/questionnaire_summary.dart';
import 'pages/student/questionnaire_history.dart';
import 'pages/student/counselor_profile_view.dart';

//admin
import 'pages/admin_new/admin_home.dart';
import 'pages/admin/admin_accounts.dart';
import 'pages/admin_new/admin_users.dart';
import 'pages/admin_new/admin_mental_health_resources.dart';
import 'pages/admin_new/admin_breathing_exercises.dart';
import 'pages/admin/admin_notifications.dart';
import 'pages/admin/admin_profile.dart';
import 'pages/admin_new/admin_questionnaire.dart';
import 'pages/admin_new/admin_mental_health_hotlines.dart';
import 'pages/admin_new/admin_daily_uplifts.dart';
import 'pages/counselor_new/counselor_home.dart';
import 'pages/counselor/all_appointments.dart';
import 'pages/counselor_new/counselor_student_chats.dart';
import 'pages/counselor_new/counselor_student_list.dart';
import 'pages/counselor_new/counselor_student_overview.dart';
import 'pages/settings.dart';
import 'pages/change_password.dart';

// page routes
final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => const LoginPage(),
  '/signup': (context) => const SignUpPage(),
  '/reset-password': (context) => const ResetPasswordPage(),

  //home page routes
  'student-home': (context) => const AuthGuard(child: StudentHomeNew()),
  'student-home-new': (context) => const AuthGuard(child: StudentHomeNew()),
  'admin-home': (context) => const AuthGuard(child: AdminHome()),
  'counselor-home': (context) => const AuthGuard(child: CounselorHome()),

  //profile
  '/student-profile': (context) => const AuthGuard(child: StudentProfile()),

  //student page routes
  'student-mtq': (context) => const AuthGuard(child: StudentQuestionnaire()),
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
      const AuthGuard(child: StudentJournalEntriesNew()),
  'student-mood-journal-write': (context) =>
      const AuthGuard(child: StudentMoodJournal()),
  'student-mental-health-resources': (context) =>
      const AuthGuard(child: StudentWellnessResources()),
  'student-chatbot': (context) => const AuthGuard(child: StudentChatbot()),
  'student-counselors': (context) =>
      const AuthGuard(child: StudentCounselors()),
  'student-contacts': (context) =>
      const AuthGuard(child: StudentSupportContacts()),
  'student-appointments': (context) =>
      const AuthGuard(child: StudentAppointments()),
  '/student-daily-checkin': (context) =>
      const AuthGuard(child: StudentDailyCheckinNew()),
  'student-checkin-history': (context) =>
      const AuthGuard(child: StudentCheckinHistoryNew()),
  'student-journal-entries': (context) =>
      const AuthGuard(child: StudentJournalEntriesNew()),
  'student-chat-list': (context) => const AuthGuard(child: StudentChats()),
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
  'admin-resources': (context) => const AuthGuard(child: AdminMentalHealthResources()),
  'admin-exercises': (context) => const AuthGuard(child: AdminBreathingExercises()),
  'admin-notifications': (context) =>
      const AuthGuard(child: AdminNotifications()),
  'admin-profile': (context) => const AuthGuard(child: AdminProfile()),
  '/admin-questionnaire': (context) =>
      const AuthGuard(child: AdminQuestionnaire()),
  'admin-hotlines': (context) => const AuthGuard(child: AdminMentalHealthHotlines()),
  'admin-daily-uplifts': (context) => const AuthGuard(child: AdminDailyUplifts()),

  // universal pages (accessible by all user types)
  '/settings': (context) => const AuthGuard(child: SettingsPage()),
  '/change-password': (context) => const AuthGuard(child: ChangePasswordPage()),

  // counselor page routes
  '/counselor-profile': (context) =>
      const AuthGuard(child: CounselorProfile()),
  '/counselor-profile-setup': (context) =>
      const AuthGuard(child: CounselorProfile()),
  '/counselor-profile-first-setup': (context) =>
      const AuthGuard(child: CounselorFirstSetup()),
  '/counselor-first-setup': (context) =>
      const AuthGuard(child: CounselorFirstSetup()),

  '/all-appointments': (context) =>
      const AuthGuard(child: AllAppointments()),
  '/student-history-list': (context) =>
      const AuthGuard(child: CounselorStudentList()),
  '/counselor-chat-list': (context) =>
      const AuthGuard(child: CounselorStudentChats()),
  '/student-overview': (context) => AuthGuard(
        child: CounselorStudentOverview(
          userId: (ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>)['userId'] as String,
          studentName: (ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>)['studentName'] as String,
          studentId: (ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>)['studentId'] as String,
        ),
      ),
};
