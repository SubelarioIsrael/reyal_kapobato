import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/counselor.dart';
import '../models/appointment.dart';
import 'push_noti_service.dart';

class CounselorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PushNotiService _pushNotiService = PushNotiService();

  // Get all counselors
  Future<List<Counselor>> getCounselors() async {
    try {
      final response =
          await _supabase.from('counselors').select().order('first_name');

      return (response as List)
          .map((json) => Counselor.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching counselors: $e');
      rethrow;
    }
  }

  // Get counselor by ID
  Future<Counselor> getCounselorById(int id) async {
    try {
      final response = await _supabase
          .from('counselors')
          .select()
          .eq('counselor_id', id)
          .single();

      return Counselor.fromJson(response);
    } catch (e) {
      print('Error fetching counselor: $e');
      rethrow;
    }
  }

  // Create new appointment
  Future<Appointment> createAppointment({
    required int counselorId,
    required DateTime appointmentDate,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already has a pending or accepted appointment
      final hasPending = await hasPendingAppointments();
      if (hasPending) {
        throw Exception('You already have a pending or accepted appointment. Please wait for it to be completed or cancelled before booking another one.');
      }

      // Format the time values to HH:mm:ss format
      final formattedStartTime =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      final formattedEndTime =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';

      final response = await _supabase
          .from('counseling_appointments')
          .insert({
            'counselor_id': counselorId,
            'user_id': userId,
            'appointment_date': appointmentDate
                .toIso8601String()
                .split('T')[0], // Store only the date part
            'start_time': formattedStartTime,
            'end_time': formattedEndTime,
            'status': 'pending',
            'notes': notes,
          })
          .select()
          .single();

      // Notify counselor about new appointment request
      await _notifyCounselorNewAppointment(counselorId, appointmentDate, startTime);

      return Appointment.fromJson(response);
    } catch (e) {
      print('Error creating appointment: $e');
      rethrow;
    }
  }

  // Get user's appointments
  Future<List<Appointment>> getUserAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('counseling_appointments')
          .select('''
            appointment_id,
            counselor_id,
            user_id,
            appointment_date,
            start_time,
            end_time,
            status,
            notes,
            status_message,
            counselors!inner(first_name, last_name)
          ''')
          .eq('user_id', userId)
          .order('appointment_date');

      // Transform the response to include counselor_name field
      final transformedResponse = (response as List).map((json) {
        final counselor = json['counselors'];
        String? counselorName;
        
        if (counselor != null) {
          final firstName = counselor['first_name'] ?? '';
          final lastName = counselor['last_name'] ?? '';
          counselorName = '$firstName $lastName'.trim();
          if (counselorName.isEmpty) counselorName = null;
        }
        
        // Remove the nested counselors object and add counselor_name
        final transformedJson = Map<String, dynamic>.from(json);
        transformedJson.remove('counselors');
        transformedJson['counselor_name'] = counselorName;
        
        return transformedJson;
      }).toList();

      return transformedResponse
          .map((json) => Appointment.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching appointments: $e');
      rethrow;
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment(int appointmentId) async {
    try {
      await _supabase
          .from('counseling_appointments')
          .update({'status': 'cancelled'}).eq('appointment_id', appointmentId);
    } catch (e) {
      print('Error cancelling appointment: $e');
      rethrow;
    }
  }

  // Check if user has any pending appointments
  Future<bool> hasPendingAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('counseling_appointments')
          .select('appointment_id')
          .eq('user_id', userId)
          .inFilter('status', ['pending', 'accepted'])
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking pending appointments: $e');
      rethrow;
    }
  }

  // Update appointment status (for counselors)
  Future<void> updateAppointmentStatus(int appointmentId, String status, {String? statusMessage}) async {
    try {
      final updateData = {
        'status': status,
        if (statusMessage != null && statusMessage.isNotEmpty) 'status_message': statusMessage,
      };

      await _supabase
          .from('counseling_appointments')
          .update(updateData)
          .eq('appointment_id', appointmentId);

      // Notify student about status update
      await _notifyStudentStatusUpdate(appointmentId, status, statusMessage);
    } catch (e) {
      print('Error updating appointment status: $e');
      rethrow;
    }
  }

  // NOTIFICATION METHODS

  // Notify counselor about new appointment request
  Future<void> _notifyCounselorNewAppointment(int counselorId, DateTime appointmentDate, DateTime startTime) async {
    try {
      // Get counselor's user_id from counselors table
      final counselorResponse = await _supabase
          .from('counselors')
          .select('user_id, first_name, last_name')
          .eq('counselor_id', counselorId)
          .single();

      final counselorUserId = counselorResponse['user_id'] as String?;
      if (counselorUserId == null) return;

      // Don't send notification if counselor user_id is same as current user (shouldn't happen, but safety check)
      final currentUserId = _supabase.auth.currentUser?.id;
      if (counselorUserId == currentUserId) {
        print('Warning: Counselor user ID is same as current user. Skipping notification.');
        return;
      }

      final formattedDate = '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
      final formattedTime = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

      // This will only show when the counselor is logged in due to the user context check in PushNotiService
      await _pushNotiService.showNotificationToUser(
        userId: counselorUserId,
        title: 'New Appointment Request',
        body: 'A student has requested an appointment on $formattedDate at $formattedTime',
        route: '/counselor-appointments',
      );
    } catch (e) {
      print('Error notifying counselor: $e');
    }
  }

  // Notify student about appointment status update
  Future<void> _notifyStudentStatusUpdate(int appointmentId, String status, String? statusMessage) async {
    try {
      // Get appointment details
      final appointmentResponse = await _supabase
          .from('counseling_appointments')
          .select('user_id, appointment_date, start_time')
          .eq('appointment_id', appointmentId)
          .single();

      final studentUserId = appointmentResponse['user_id'] as String?;
      if (studentUserId == null) return;

      String title;
      String body;
      String route = '/appointments'; // Default route for appointments

      switch (status) {
        case 'accepted':
          title = 'Appointment Confirmed!';
          body = 'Your counseling appointment has been accepted.';
          break;
        case 'rejected':
          title = 'Appointment Update';
          body = statusMessage ?? 'Your appointment request was declined.';
          break;
        case 'cancelled':
          title = 'Appointment Cancelled';
          body = statusMessage ?? 'Your appointment has been cancelled.';
          break;
        case 'completed':
          title = 'Session Completed';
          body = 'Your counseling session has been completed.';
          break;
        default:
          title = 'Appointment Update';
          body = 'Your appointment status has been updated to $status.';
      }

      await _pushNotiService.showNotificationToUser(
        userId: studentUserId,
        title: title,
        body: body,
        route: route,
      );
    } catch (e) {
      print('Error notifying student: $e');
    }
  }

  // Check for upcoming appointments and send reminders
  Future<void> checkUpcomingAppointments() async {
    try {
      final now = DateTime.now();
      final reminderTime = now.add(const Duration(hours: 1)); // 1 hour before

      final upcomingAppointments = await _supabase
          .from('counseling_appointments')
          .select('''
            appointment_id,
            user_id,
            appointment_date,
            start_time,
            counselors!inner(first_name, last_name)
          ''')
          .eq('status', 'accepted')
          .gte('appointment_date', now.toIso8601String().split('T')[0]);

      for (final appointment in upcomingAppointments) {
        final appointmentDateStr = appointment['appointment_date'] as String;
        final startTimeStr = appointment['start_time'] as String;
        
        // Parse appointment datetime
        final appointmentDate = DateTime.parse(appointmentDateStr);
        final timeParts = startTimeStr.split(':');
        final appointmentDateTime = DateTime(
          appointmentDate.year,
          appointmentDate.month,
          appointmentDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        // Check if appointment is within reminder window
        if (appointmentDateTime.isAfter(now) && appointmentDateTime.isBefore(reminderTime)) {
          final counselor = appointment['counselors'];
          final counselorName = counselor != null 
              ? '${counselor['first_name'] ?? ''} ${counselor['last_name'] ?? ''}'.trim()
              : 'your counselor';

          final formattedTime = '${timeParts[0]}:${timeParts[1]}';

          await _pushNotiService.showNotificationToUser(
            userId: appointment['user_id'],
            title: 'Upcoming Appointment Reminder',
            body: 'You have an appointment with $counselorName at $formattedTime',
            route: '/appointments',
          );
        }
      }
    } catch (e) {
      print('Error checking upcoming appointments: $e');
    }
  }

  // Schedule appointment reminders (call this periodically)
  Future<void> scheduleAppointmentReminders() async {
    // This method should be called periodically (e.g., every 15-30 minutes)
    // You might want to implement this with a background service or periodic timer
    await checkUpcomingAppointments();
  }
}
