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

//admin
import 'pages/admin/admin_home.dart';
import 'pages/counselor/counselor_home.dart';

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
  'student-breathing-exercises': (context) =>
      const AuthGuard(child: StudentBreathingExercises()),
  'student-mood-journal': (context) =>
      const AuthGuard(child: StudentMoodJournal()),
  'student-mental-health-resources': (context) =>
      const AuthGuard(child: StudentMentalHealthResources()),
  'student-chatbot': (context) => const AuthGuard(child: StudentChatbot()),

  // adming page routes
  'admin-dashboard': (context) => const AuthGuard(child: AdminHome()),
  'admin-send-notification': (context) => const AuthGuard(child: AdminHome()),
  'admin-make-announcement': (context) => const AuthGuard(child: AdminHome()),
  'admin-student-list': (context) => const AuthGuard(child: AdminHome()),
};
