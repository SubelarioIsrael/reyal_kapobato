import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/counselor.dart';
import '../services/counselor_service.dart';
import '../utils/department_mapping.dart';

class StudentCounselorsController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CounselorService _counselorService = CounselorService();

  /// Get student's department based on their education info
  Future<String?> getStudentDepartment() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final studentData = await _supabase
          .from('students')
          .select('education_level, course, strand')
          .eq('user_id', userId)
          .maybeSingle();

      if (studentData == null) return null;

      return DepartmentMapping.getStudentDepartment(
        educationLevel: studentData['education_level']?.toLowerCase(),
        course: studentData['course'],
        strand: studentData['strand'],
      );
    } catch (e) {
      print('Error getting student department: $e');
      return null;
    }
  }

  /// Load counselors from student's department and volunteers
  Future<Map<String, List<Counselor>>> loadCounselors() async {
    try {
      final studentDepartment = await getStudentDepartment();
      final allCounselors = await _counselorService.getCounselors();

      final departmentCounselors = <Counselor>[];
      final volunteerCounselors = <Counselor>[];

      for (final counselor in allCounselors) {
        if (counselor.departmentAssigned == 'Volunteer') {
          volunteerCounselors.add(counselor);
        } else if (studentDepartment != null &&
            counselor.departmentAssigned == studentDepartment) {
          departmentCounselors.add(counselor);
        }
      }

      return {
        'department': departmentCounselors,
        'volunteer': volunteerCounselors,
        'department_name': [Counselor(
          id: 0,
          firstName: studentDepartment ?? 'Unknown',
          lastName: '',
          email: '',
          departmentAssigned: studentDepartment ?? '',
          availabilityStatus: 'available',
        )],
      };
    } catch (e) {
      print('Error loading counselors: $e');
      rethrow;
    }
  }

  /// Book an appointment with a counselor
  Future<BookAppointmentResult> bookAppointment({
    required int counselorId,
    required DateTime appointmentDate,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return BookAppointmentResult(
          success: false,
          errorMessage: 'User not authenticated',
        );
      }

      // Check for existing appointments at the same time
      final existingAppointments = await _supabase
          .from('counseling_appointments')
          .select('appointment_id')
          .eq('counselor_id', counselorId)
          .eq('appointment_date', appointmentDate.toIso8601String().split('T')[0])
          .gte('start_time', '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}')
          .lt('end_time', '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}')
          .inFilter('status', ['pending', 'accepted']);

      if (existingAppointments.isNotEmpty) {
        return BookAppointmentResult(
          success: false,
          errorMessage: 'This time slot is already booked',
        );
      }

      // Create the appointment
      await _supabase.from('counseling_appointments').insert({
        'counselor_id': counselorId,
        'user_id': userId,
        'appointment_date': appointmentDate.toIso8601String().split('T')[0],
        'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
        'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
        'status': 'pending',
        'notes': notes,
      });

      return BookAppointmentResult(success: true);
    } catch (e) {
      print('Error booking appointment: $e');
      return BookAppointmentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}

class BookAppointmentResult {
  final bool success;
  final String? errorMessage;

  BookAppointmentResult({
    required this.success,
    this.errorMessage,
  });
}
