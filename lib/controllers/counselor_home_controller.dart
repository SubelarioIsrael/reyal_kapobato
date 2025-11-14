import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../../services/chatbot_service.dart'; // existing import
import '../../services/notification_service.dart'; // new import

// Result classes
class LoadAppointmentsResult {
  final bool success;
  final List<Appointment> appointments;
  final Map<String, Map<String, String>> studentInfo;
  final int totalStudents;
  final int completedSessions;
  final int upcomingSessions;
  final String? counselorName;
  final String? errorMessage;

  LoadAppointmentsResult({
    required this.success,
    this.appointments = const [],
    this.studentInfo = const {},
    this.totalStudents = 0,
    this.completedSessions = 0,
    this.upcomingSessions = 0,
    this.counselorName,
    this.errorMessage,
  });
}

class UpdateAppointmentStatusResult {
  final bool success;
  final String? errorMessage;

  UpdateAppointmentStatusResult({
    required this.success,
    this.errorMessage,
  });
}

class GenerateCallCodeResult {
  final bool success;
  final String? callCode;
  final String? errorMessage;

  GenerateCallCodeResult({
    required this.success,
    this.callCode,
    this.errorMessage,
  });
}

class JoinCallResult {
  final bool success;
  final Map<String, dynamic>? callData;
  final String? userName;
  final int? counselorId;
  final String? errorMessage;

  JoinCallResult({
    required this.success,
    this.callData,
    this.userName,
    this.counselorId,
    this.errorMessage,
  });
}

class UnreadMessagesResult {
  final bool success;
  final Map<int, int> unreadCounts; // appointmentId -> unread count
  final String? errorMessage;

  UnreadMessagesResult({
    required this.success,
    this.unreadCounts = const {},
    this.errorMessage,
  });
}

// New result class for intervention log analysis
class InterventionAnalysisResult {
  final bool success;
  final String? analysis;
  final String? errorMessage;

  InterventionAnalysisResult({
    required this.success,
    this.analysis,
    this.errorMessage,
  });
}

class CounselorHomeController {
  final _supabase = Supabase.instance.client;

  // Load all appointments for counselor with student info and statistics
  Future<LoadAppointmentsResult> loadAppointments() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return LoadAppointmentsResult(
          success: false,
          errorMessage: 'Not logged in',
        );
      }

      // Check user type
      final userRow = await _supabase
          .from('users')
          .select('user_type')
          .eq('user_id', user.id)
          .maybeSingle();

      if (userRow == null || userRow['user_type'] != 'counselor') {
        return LoadAppointmentsResult(
          success: false,
          errorMessage: 'You are not authorized to view this page.',
        );
      }

      // Get counselor profile
      final counselorProfile = await _supabase
          .from('counselors')
          .select('counselor_id, first_name, last_name, department_assigned, bio')
          .eq('user_id', user.id)
          .maybeSingle();

      if (counselorProfile == null) {
        return LoadAppointmentsResult(
          success: false,
          errorMessage: 'PROFILE_NOT_FOUND', // Special code to trigger setup
        );
      }

      // Check if profile is incomplete
      final firstName = counselorProfile['first_name'] as String?;
      final lastName = counselorProfile['last_name'] as String?;
      final departmentAssigned = counselorProfile['department_assigned'] as String?;

      final isProfileIncomplete = (firstName?.trim().isEmpty ?? true) ||
          (lastName?.trim().isEmpty ?? true) ||
          (departmentAssigned?.trim().isEmpty ?? true);

      if (isProfileIncomplete) {
        return LoadAppointmentsResult(
          success: false,
          errorMessage: 'PROFILE_INCOMPLETE', // Special code to trigger welcome dialog
        );
      }

      final counselorId = counselorProfile['counselor_id'] as int?;
      if (counselorId == null) {
        return LoadAppointmentsResult(
          success: false,
          errorMessage: 'Error with counselor profile. Please contact admin.',
        );
      }

      // Load appointments
      final response = await _supabase
          .from('counseling_appointments')
          .select()
          .eq('counselor_id', counselorId)
          .order('appointment_date');

      final appointments =
          (response as List).map((json) => Appointment.fromJson(json)).toList();

      // Fetch student info for all unique user_ids
      final userIds =
          appointments.map((a) => a.userId.toString().trim()).toSet().toList();
      
      Map<String, Map<String, String>> studentInfo = {};
      if (userIds.isNotEmpty) {
        final studentsResponse = await _supabase
            .from('students')
            .select('user_id, student_code, first_name, last_name')
            .inFilter('user_id', userIds);
        
        for (var s in studentsResponse) {
          final key = s['user_id'].toString().trim();
          final firstName = s['first_name'] ?? '';
          final lastName = s['last_name'] ?? '';
          final fullName = '$firstName $lastName'.trim();
          studentInfo[key] = {
            'student_name': fullName.isNotEmpty ? fullName : 'Unknown Student',
            'student_id': s['student_code'] ?? ''
          };
        }
      }

      // Calculate statistics
      final uniqueStudents = appointments.map((a) => a.userId).toSet().length;
      final completed = appointments
          .where((a) => a.status.toLowerCase() == 'completed')
          .length;
      final upcoming = appointments
          .where((a) =>
              a.status.toLowerCase() == 'accepted' &&
              a.appointmentDate.isAfter(DateTime.now()))
          .length;

      // Get counselor name
      final nameFirst = counselorProfile['first_name'] as String? ?? '';
      final nameLast = counselorProfile['last_name'] as String? ?? '';
      final fullName = '$nameFirst $nameLast'.trim();

      return LoadAppointmentsResult(
        success: true,
        appointments: appointments,
        studentInfo: studentInfo,
        totalStudents: uniqueStudents,
        completedSessions: completed,
        upcomingSessions: upcoming,
        counselorName: fullName.isNotEmpty ? fullName : null,
      );
    } catch (e) {
      return LoadAppointmentsResult(
        success: false,
        errorMessage: 'Error loading appointments: ${e.toString()}',
      );
    }
  }

  // Update appointment status with optional message
  Future<UpdateAppointmentStatusResult> updateAppointmentStatus({
    required int appointmentId,
    required String userId,
    required String newStatus,
    required DateTime appointmentDate,
    required DateTime startTime,
    required DateTime endTime,
    String? statusMessage,
  }) async {
    try {
      // Update appointment status
      await _supabase
          .from('counseling_appointments')
          .update({
            'status': newStatus,
            'status_message': statusMessage,
          })
          .eq('appointment_id', appointmentId);

      // Send in-app notification
      await _supabase.from('user_notifications').insert({
        'user_id': userId,
        'notification_type': 'Appointment Status Update',
        'content':
            'Your appointment on ${appointmentDate.toString().split(' ')[0]} from ${startTime.toString().split(' ')[1].substring(0, 5)} to ${endTime.toString().split(' ')[1].substring(0, 5)} has been changed to ${newStatus.toUpperCase()}. ${statusMessage?.isNotEmpty == true ? "Message: $statusMessage" : ""}',
        'action_url': '/appointments'
      });

      return UpdateAppointmentStatusResult(success: true);
    } catch (e) {
      return UpdateAppointmentStatusResult(
        success: false,
        errorMessage: 'Error updating appointment status: ${e.toString()}',
      );
    }
  }

  // Generate a new call code
  Future<GenerateCallCodeResult> generateCallCode() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return GenerateCallCodeResult(
          success: false,
          errorMessage: 'Not logged in',
        );
      }

      // Get counselor info
      final counselorData = await _supabase
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', user.id)
          .single();

      final counselorId = counselorData['counselor_id'] as int;
      final callCode = _generateRandomCode();

      // Insert video call record
      await _supabase.from('video_calls').insert({
        'call_code': callCode,
        'counselor_id': counselorId,
        'created_by': 'counselor',
        'status': 'active',
        'counselor_joined_at': DateTime.now().toIso8601String(),
      });

      return GenerateCallCodeResult(
        success: true,
        callCode: callCode,
      );
    } catch (e) {
      return GenerateCallCodeResult(
        success: false,
        errorMessage: 'Failed to generate call code: ${e.toString()}',
      );
    }
  }

  // Join a video call
  Future<JoinCallResult> joinVideoCall(String callCode) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return JoinCallResult(
          success: false,
          errorMessage: 'Not logged in',
        );
      }

      // Get counselor data
      final counselorData = await _supabase
          .from('counselors')
          .select('first_name, last_name, counselor_id')
          .eq('user_id', user.id)
          .single();

      final counselorId = counselorData['counselor_id'] as int;
      String userName = user.email ?? 'Counselor';

      if (counselorData['first_name'] != null && counselorData['last_name'] != null) {
        userName = '${counselorData['first_name']} ${counselorData['last_name']}';
      }

      // Check if call exists
      final videoCallData = await _supabase
          .from('video_calls')
          .select('*')
          .eq('call_code', callCode)
          .eq('status', 'active')
          .single();

      // Update counselor joined time
      await _supabase
          .from('video_calls')
          .update({
            'counselor_joined_at': DateTime.now().toIso8601String(),
          })
          .eq('call_code', callCode);

      return JoinCallResult(
        success: true,
        callData: videoCallData,
        userName: userName,
        counselorId: counselorId,
      );
    } catch (e) {
      return JoinCallResult(
        success: false,
        errorMessage: 'Error joining call: ${e.toString()}',
      );
    }
  }

  // Get unread message counts for appointments
  Future<UnreadMessagesResult> getUnreadMessageCounts(List<int> appointmentIds) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return UnreadMessagesResult(
          success: false,
          errorMessage: 'Not logged in',
        );
      }

      Map<int, int> unreadCounts = {};

      for (var appointmentId in appointmentIds) {
        // Get the appointment to find the student user_id
        final appointment = await _supabase
            .from('counseling_appointments')
            .select('user_id')
            .eq('appointment_id', appointmentId)
            .maybeSingle();
        
        if (appointment != null && appointment['user_id'] != null) {
          final studentUserId = appointment['user_id'] as String;
          
          // Count unread direct messages from this student (appointment_id IS NULL)
          final response = await _supabase
              .from('messages')
              .select('id')
              .eq('sender_id', studentUserId) // From student
              .eq('receiver_id', user.id) // To counselor
              .isFilter('appointment_id', null) // Direct messages only
              .eq('is_read', false); // Unread messages

          unreadCounts[appointmentId] = (response as List).length;
        }
      }

      return UnreadMessagesResult(
        success: true,
        unreadCounts: unreadCounts,
      );
    } catch (e) {
      return UnreadMessagesResult(
        success: false,
        errorMessage: 'Error loading unread messages: ${e.toString()}',
      );
    }
  }

  // Analyze recent intervention logs (last 7 days) using the ChatbotService
  Future<InterventionAnalysisResult> getWeeklyInterventionAnalysis({int days = 7, int maxMessages = 50}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return InterventionAnalysisResult(success: false, errorMessage: 'Not logged in');
      }

      // Fetch recent intervention logs (trigger_message and timestamp)
      final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final logsResponse = await _supabase
          .from('intervention_logs')
          .select('trigger_message, triggered_at')
          .gte('triggered_at', since)
          .order('triggered_at', ascending: false);

      if (logsResponse == null || (logsResponse as List).isEmpty) {
        return InterventionAnalysisResult(success: true, analysis: '', errorMessage: 'No recent intervention logs');
      }

      final logsList = (logsResponse as List).cast<Map<String, dynamic>>();

      // Extract messages and limit
      final messages = logsList
          .map((r) => (r['trigger_message'] ?? '').toString().trim())
          .where((m) => m.isNotEmpty)
          .take(maxMessages)
          .toList();

      if (messages.isEmpty) {
        return InterventionAnalysisResult(success: true, analysis: '', errorMessage: 'No recent intervention messages');
      }

      // Build a concise prompt for the model
      final buffer = StringBuffer();
      buffer.writeln('You are Eirene, a clinical-support assistant. Analyze the recent intervention log messages and produce: key themes or trends, any urgent safety concerns, prioritized counselor actions, brief outreach messages, and recommended resources or referrals. Keep it concise, strictly actionable, and formatted as a short prioritized list. No markdown, no bullets, no greetings, no introductions.');
      buffer.writeln('');
      buffer.writeln('Recent intervention log messages (most recent first):');
      for (var i = 0; i < messages.length; i++) {
        buffer.writeln('${i + 1}. ${messages[i]}');
      }
      buffer.writeln('');

      final prompt = buffer.toString();

      // Call ChatbotService to generate analysis
      final aiResponse = await ChatbotService.generateResponse(prompt);

      // Save generated analysis as an in-app notification and optionally send push
      try {
        final trimmed = (aiResponse ?? '').trim();
        if (trimmed.isNotEmpty) {
          await NotificationService.createInAppNotificationForCounselor(
            userId: user.id,
            title: 'Weekly Intervention Analysis',
            content: trimmed,
            sendPush: true,
            pushData: {'type': 'weekly_intervention_analysis'},
          );
        }
      } catch (e) {
        // notification failure should not fail the analysis call
        print('Failed to save/send AI analysis notification: $e');
      }

      return InterventionAnalysisResult(success: true, analysis: aiResponse);
    } catch (e) {
      return InterventionAnalysisResult(success: false, errorMessage: 'Analysis failed: ${e.toString()}');
    }
  }

  // Helper method to generate random call code
  String _generateRandomCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    final random = DateTime.now().millisecondsSinceEpoch;
    
    String generateGroup() {
      final r1 = (random % chars.length);
      final r2 = ((random ~/ chars.length) % chars.length);
      final r3 = ((random ~/ (chars.length * chars.length)) % chars.length);
      return '${chars[r1]}${chars[r2]}${chars[r3]}';
    }
    
    return '${generateGroup()}-${generateGroup()}-${generateGroup()}';
  }
}
