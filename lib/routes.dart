// routes.dart

import 'package:flutter/material.dart';
import 'widgets/auth_guard.dart';

import 'pages/login_page.dart';
import 'pages/signup_page.dart';

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
import 'pages/student/student_settings.dart';
import 'pages/student/questionnaire_summary.dart';

//admin
import 'pages/admin/admin_home.dart';
import 'pages/admin/admin_accounts.dart';
import 'pages/admin/admin_users.dart';
import 'pages/admin/admin_resources.dart';
import 'pages/admin/admin_exercises.dart';
import 'pages/admin/admin_notifications.dart';
import 'pages/admin/admin_settings.dart';
import 'pages/admin/admin_profile.dart';
import 'pages/counselor/counselor_home.dart';
import 'pages/counselor/counselor_settings.dart';

// page routes
final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => LoginPage(),
  '/signup': (context) => SignUpPage(),

  //home page routes
  'student-home': (context) => const AuthGuard(child: StudentHome()),
  'admin-home': (context) => const AuthGuard(child: AdminHome()),
  'counselor-home': (context) => const AuthGuard(child: CounselorHome()),

  //profile
  '/student-profile': (context) => const AuthGuard(child: ProfilePage()),

  //student page routes
  'student-mtq': (context) => const AuthGuard(child: StudentMtq()),
  'questionnaire-summary': (context) => AuthGuard(
        child: QuestionnaireSummary(
          responseId: (ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>)['responseId'] as int,
          totalScore: (ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>)['totalScore'] as int,
        ),
      ),
  'student-breathing-exercises': (context) =>
      const AuthGuard(child: StudentBreathingExercises()),
  'student-mood-journal': (context) =>
      const AuthGuard(child: StudentMoodJournal()),
  'student-mental-health-resources': (context) =>
      const AuthGuard(child: StudentMentalHealthResources()),
  'student-chatbot': (context) => const AuthGuard(child: StudentChatbot()),
  'student-counselors': (context) =>
      const AuthGuard(child: StudentCounselors()),
  'student-appointments': (context) =>
      const AuthGuard(child: StudentAppointments()),
  'student-settings': (context) => const AuthGuard(child: StudentSettings()),

  // admin page routes
  'admin-accounts': (context) => const AuthGuard(child: AdminAccounts()),
  'admin-users': (context) => const AuthGuard(child: AdminUsers()),
  'admin-resources': (context) => const AuthGuard(child: AdminResources()),
  'admin-exercises': (context) => const AuthGuard(child: AdminExercises()),
  'admin-notifications': (context) =>
      const AuthGuard(child: AdminNotifications()),
  'admin-settings': (context) => const AuthGuard(child: AdminSettings()),
  'admin-profile': (context) => const AuthGuard(child: AdminProfile()),
  'counselor-settings': (context) =>
      const AuthGuard(child: CounselorSettings()),
};
