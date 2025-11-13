import 'package:supabase_flutter/supabase_flutter.dart';

class CounselorStudentListController {
  Future<int?> getCounselorId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final counselorProfile = await Supabase.instance.client
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', user.id)
          .single();

      return counselorProfile['counselor_id'] as int;
    } catch (e) {
      throw Exception('Error getting counselor ID: $e');
    }
  }

  Future<List<Map<String, dynamic>>> loadStudentHistory() async {
    try {
      final counselorId = await getCounselorId();
      if (counselorId == null) throw Exception('Counselor not found');

      // Get all students who have had appointments with this counselor
      final appointmentsResponse = await Supabase.instance.client
          .from('counseling_appointments')
          .select('user_id')
          .eq('counselor_id', counselorId);

      final uniqueUserIds = (appointmentsResponse as List)
          .map((appt) => appt['user_id'] as String)
          .toSet()
          .toList();

      if (uniqueUserIds.isEmpty) {
        return [];
      }

      // Get student details
      final studentsResponse = await Supabase.instance.client
          .from('students')
          .select('user_id, student_code, first_name, last_name')
          .inFilter('user_id', uniqueUserIds);

      final usersResponse = await Supabase.instance.client
          .from('users')
          .select('user_id, email')
          .inFilter('user_id', uniqueUserIds);

      // Combine data
      Map<String, Map<String, dynamic>> studentsMap = {};
      
      for (var student in studentsResponse) {
        studentsMap[student['user_id']] = {
          'user_id': student['user_id'],
          'student_code': student['student_code'] ?? '',
          'first_name': student['first_name'] ?? '',
          'last_name': student['last_name'] ?? '',
        };
      }

      for (var user in usersResponse) {
        if (studentsMap[user['user_id']] != null) {
          studentsMap[user['user_id']]!.addAll({
            'username': user['username'] ?? '',
            'email': user['email'] ?? '',
          });
        }
      }

      // Get appointment counts for each student
      for (var userId in uniqueUserIds) {
        final appointmentCountResponse = await Supabase.instance.client
            .from('counseling_appointments')
            .select('appointment_id, status')
            .eq('counselor_id', counselorId)
            .eq('user_id', userId);

        final totalAppointments = appointmentCountResponse.length;
        final completedAppointments = appointmentCountResponse
            .where((appt) => appt['status'] == 'completed')
            .length;

        if (studentsMap[userId] != null) {
          studentsMap[userId]!.addAll({
            'total_appointments': totalAppointments,
            'completed_appointments': completedAppointments,
          });
        }
      }

      return studentsMap.values.toList();
    } catch (e) {
      throw Exception('Error loading student history: $e');
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
