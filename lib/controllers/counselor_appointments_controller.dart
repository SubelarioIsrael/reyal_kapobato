import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';
import 'dart:math';

// Result classes
class LoadAllAppointmentsResult {
  final bool success;
  final List<Appointment> appointments;
  final Map<String, Map<String, String>> studentInfo;
  final String? errorMessage;

  LoadAllAppointmentsResult({
    required this.success,
    this.appointments = const [],
    this.studentInfo = const {},
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

class SaveSessionNotesResult {
  final bool success;
  final String? errorMessage;

  SaveSessionNotesResult({
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
  final int? counselorId;
  final String? userName;
  final String? studentUserId;
  final String? errorMessage;

  JoinCallResult({
    required this.success,
    this.counselorId,
    this.userName,
    this.studentUserId,
    this.errorMessage,
  });
}

class UnreadCountsResult {
  final bool success;
  final Map<int, int> unreadCounts; // appointmentId -> count
  final String? errorMessage;

  UnreadCountsResult({
    required this.success,
    this.unreadCounts = const {},
    this.errorMessage,
  });
}

class CounselorAppointmentsController {
  final _supabase = Supabase.instance.client;

  // Load all appointments for the counselor
  Future<LoadAllAppointmentsResult> loadAppointments() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return LoadAllAppointmentsResult(
          success: false,
          errorMessage: 'Not logged in',
        );
      }

      // Get counselor ID
      final counselorProfile = await _supabase
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', user.id)
          .single();

      final counselorId = counselorProfile['counselor_id'] as int;

      // Load appointments
      final response = await _supabase
          .from('counseling_appointments')
          .select()
          .eq('counselor_id', counselorId)
          .order('appointment_date', ascending: false);

      final appointments =
          (response as List).map((json) => Appointment.fromJson(json)).toList();

      // Fetch student info
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
            'student_code': s['student_code'] ?? '',
            'first_name': firstName,
            'last_name': lastName,
            'student_name': fullName.isNotEmpty ? fullName : 'Unknown Student'
          };
        }
      }

      return LoadAllAppointmentsResult(
        success: true,
        appointments: appointments,
        studentInfo: studentInfo,
      );
    } catch (e) {
      return LoadAllAppointmentsResult(
        success: false,
        errorMessage: 'Error loading appointments: ${e.toString()}',
      );
    }
  }

  // Get unread message counts for appointments
  Future<UnreadCountsResult> getUnreadCounts(List<int> appointmentIds) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return UnreadCountsResult(
          success: false,
          errorMessage: 'Not logged in',
        );
      }

      Map<int, int> unreadCounts = {};

      for (var appointmentId in appointmentIds) {
        final response = await _supabase
            .from('messages')
            .select('id')
            .eq('appointment_id', appointmentId)
            .eq('receiver_id', user.id)
            .eq('is_read', false);

        unreadCounts[appointmentId] = (response as List).length;
      }

      return UnreadCountsResult(
        success: true,
        unreadCounts: unreadCounts,
      );
    } catch (e) {
      return UnreadCountsResult(
        success: false,
        errorMessage: 'Error loading unread counts: ${e.toString()}',
      );
    }
  }

  // Update appointment status
  Future<UpdateAppointmentStatusResult> updateAppointmentStatus({
    required int appointmentId,
    required String newStatus,
    String? statusMessage,
  }) async {
    try {
      await _supabase
          .from('counseling_appointments')
          .update({'status': newStatus})
          .eq('appointment_id', appointmentId);

      return UpdateAppointmentStatusResult(success: true);
    } catch (e) {
      return UpdateAppointmentStatusResult(
        success: false,
        errorMessage: 'Error updating appointment status: ${e.toString()}',
      );
    }
  }

  // Save session notes and mark appointment as completed
  Future<SaveSessionNotesResult> saveSessionNotes({
    required int appointmentId,
    required String studentUserId,
    required String summary,
    String? topicsDiscussed,
    String? recommendations,
  }) async {
    try {
      print('Starting saveSessionNotes for appointment: $appointmentId');
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('Error: User not logged in');
        return SaveSessionNotesResult(
          success: false,
          errorMessage: 'Not logged in',
        );
      }

      print('Getting counselor profile for user: ${user.id}');
      // Get counselor ID
      final counselorProfile = await _supabase
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', user.id)
          .single();

      final counselorId = counselorProfile['counselor_id'] as int;
      print('Counselor ID: $counselorId');

      // Save session notes
      print('Inserting session notes...');
      final insertResult = await _supabase.from('counseling_session_notes').insert({
        'appointment_id': appointmentId,
        'counselor_id': counselorId,
        'student_user_id': studentUserId,
        'summary': summary,
        'topics_discussed': topicsDiscussed,
        'recommendations': recommendations,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select();

      print('Session notes inserted: $insertResult');

      // Update appointment status to completed
      print('Updating appointment status...');
      final updateResult = await _supabase
          .from('counseling_appointments')
          .update({'status': 'completed'})
          .eq('appointment_id', appointmentId)
          .select();

      print('Appointment status updated: $updateResult');

      return SaveSessionNotesResult(success: true);
    } catch (e, stackTrace) {
      print('Error in saveSessionNotes: $e');
      print('Stack trace: $stackTrace');
      return SaveSessionNotesResult(
        success: false,
        errorMessage: 'Error saving session notes: ${e.toString()}',
      );
    }
  }

  // Generate a random call code
  String _generateRandomCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    final random = Random();

    String generateGroup() {
      return String.fromCharCodes(
        Iterable.generate(3, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
      );
    }

    return '${generateGroup()}-${generateGroup()}-${generateGroup()}';
  }

  // Generate call code for video call
  Future<GenerateCallCodeResult> generateCallCode() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return GenerateCallCodeResult(
          success: false,
          errorMessage: 'Not logged in',
        );
      }

      // Get counselor ID
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

  // Join video call
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

      // Check if call exists and get student info
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
        counselorId: counselorId,
        userName: userName,
        studentUserId: videoCallData['student_user_id'],
      );
    } catch (e) {
      return JoinCallResult(
        success: false,
        errorMessage: 'Error joining call: ${e.toString()}',
      );
    }
  }

  // Send notification to student
  Future<void> sendStatusUpdateNotification({
    required String studentUserId,
    required String appointmentDate,
    required String newStatus,
    String? message,
  }) async {
    try {
      // Create notification content
      final notificationContent = 'Your appointment on $appointmentDate has been ${newStatus.toUpperCase()}.'
          '${message != null && message.isNotEmpty ? ' Message: $message' : ''}';

      // Insert notification into database
      await _supabase.from('user_notifications').insert({
        'user_id': studentUserId,
        'notification_type': 'Appointment Status Update',
        'content': notificationContent,
        'action_url': '/appointments'
      });

      // Try to send push notification via Edge Function
      try {
        await _supabase.functions.invoke(
          'send-notification',
          body: {
            'user_id': studentUserId,
            'title': 'Appointment Status Update',
            'body': notificationContent,
            'data': {
              'action': 'appointment_status_changed',
              'route': '/appointments'
            }
          },
        );
      } catch (pushError) {
        // Continue even if push notification fails
      }
    } catch (e) {
      // Don't throw error - notification failure shouldn't block status update
    }
  }
}
