import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/counselor.dart';
import '../models/appointment.dart';

class CounselorService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
          .select()
          .eq('user_id', userId)
          .order('appointment_date');

      return (response as List)
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
}
