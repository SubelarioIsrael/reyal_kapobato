import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';

class StudentAppointmentsController {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Load all appointments for the current student
  Future<LoadAppointmentsResult> loadAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return LoadAppointmentsResult(
          success: false,
          errorMessage: 'User not authenticated',
        );
      }

      final appointmentsData = await _supabase
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
            counselors!counselingappointments_counselor_id_fkey(first_name, last_name)
          ''')
          .eq('user_id', userId)
          .order('appointment_date', ascending: false)
          .order('start_time', ascending: false);

      final List<Appointment> appointments = [];
      for (var data in appointmentsData) {
        try {
          final counselorData = data['counselors'] as Map<String, dynamic>?;
          final counselorName = counselorData != null
              ? '${counselorData['first_name']} ${counselorData['last_name']}'
              : 'Unknown Counselor';

          appointments.add(Appointment(
            id: data['appointment_id'],
            counselorId: data['counselor_id'],
            userId: data['user_id'],
            appointmentDate: DateTime.parse(data['appointment_date']),
            startTime: _parseTime(data['start_time'], data['appointment_date']),
            endTime: _parseTime(data['end_time'], data['appointment_date']),
            status: data['status'] ?? 'pending',
            notes: data['notes'],
            counselorName: counselorName,
          ));
        } catch (e) {
          print('Error parsing appointment: $e');
        }
      }

      return LoadAppointmentsResult(
        success: true,
        appointments: appointments,
      );
    } catch (e) {
      print('Error loading appointments: $e');
      return LoadAppointmentsResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  DateTime _parseTime(String timeString, String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final timeParts = timeString.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      print('Error parsing time: $e');
      return DateTime.now();
    }
  }

  /// Cancel an appointment
  Future<CancelAppointmentResult> cancelAppointment(int appointmentId, String reason) async {
    try {
      // Get appointment and counselor info before updating
      final appointmentResponse = await _supabase
          .from('counseling_appointments')
          .select('''
            counselor_id,
            appointment_date,
            start_time,
            counselors!inner(
              user_id,
              first_name,
              last_name
            )
          ''')
          .eq('appointment_id', appointmentId)
          .single();

      // Get student name
      final currentUserId = _supabase.auth.currentUser?.id;
      String studentName = 'A student';
      if (currentUserId != null) {
        try {
          final studentResponse = await _supabase
              .from('students')
              .select('first_name, last_name')
              .eq('user_id', currentUserId)
              .maybeSingle();
          
          if (studentResponse != null) {
            final firstName = studentResponse['first_name'] as String? ?? '';
            final lastName = studentResponse['last_name'] as String? ?? '';
            studentName = '$firstName $lastName'.trim();
            if (studentName.isEmpty) studentName = 'A student';
          }
        } catch (e) {
          print('Error fetching student name: $e');
        }
      }

      // Update appointment status
      await _supabase
          .from('counseling_appointments')
          .update({
            'status': 'cancelled',
            'status_message': reason,
          })
          .eq('appointment_id', appointmentId);

      // Create notification for counselor
      final counselorUserId = appointmentResponse['counselors']['user_id'] as String?;
      if (counselorUserId != null) {
        final appointmentDate = appointmentResponse['appointment_date'] as String;
        final startTime = appointmentResponse['start_time'] as String;
        
        await _supabase.from('user_notifications').insert({
          'user_id': counselorUserId,
          'notification_type': 'appointment_cancelled',
          'content': 'Your appointment with $studentName on $appointmentDate at $startTime has been cancelled.',
          'action_url': '/counselor_appointments',
          'is_read': false,
        });
      }

      return CancelAppointmentResult(success: true);
    } catch (e) {
      print('Error cancelling appointment: $e');
      return CancelAppointmentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reschedule an appointment
  Future<RescheduleAppointmentResult> rescheduleAppointment({
    required int appointmentId,
    required DateTime newDate,
    required DateTime newStartTime,
    required DateTime newEndTime,
    String? reason,
  }) async {
    try {
      await _supabase
          .from('counseling_appointments')
          .update({
            'appointment_date': newDate.toIso8601String().split('T')[0],
            'start_time': '${newStartTime.hour.toString().padLeft(2, '0')}:${newStartTime.minute.toString().padLeft(2, '0')}:00',
            'end_time': '${newEndTime.hour.toString().padLeft(2, '0')}:${newEndTime.minute.toString().padLeft(2, '0')}:00',
            'status': 'rescheduled',
            'status_message': reason,
          })
          .eq('appointment_id', appointmentId);

      return RescheduleAppointmentResult(success: true);
    } catch (e) {
      print('Error rescheduling appointment: $e');
      return RescheduleAppointmentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}

class LoadAppointmentsResult {
  final bool success;
  final List<Appointment> appointments;
  final String? errorMessage;

  LoadAppointmentsResult({
    required this.success,
    this.appointments = const [],
    this.errorMessage,
  });
}

class CancelAppointmentResult {
  final bool success;
  final String? errorMessage;

  CancelAppointmentResult({
    required this.success,
    this.errorMessage,
  });
}

class RescheduleAppointmentResult {
  final bool success;
  final String? errorMessage;

  RescheduleAppointmentResult({
    required this.success,
    this.errorMessage,
  });
}
