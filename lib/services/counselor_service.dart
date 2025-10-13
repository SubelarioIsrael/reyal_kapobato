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
    } catch (e) {
      print('Error updating appointment status: $e');
      rethrow;
    }
  }
}
