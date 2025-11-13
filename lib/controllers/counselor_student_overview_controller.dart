import 'package:supabase_flutter/supabase_flutter.dart';

class CounselorStudentOverviewController {
  Future<Map<String, dynamic>?> loadStudentProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('students')
          .select(
              '*, users!students_user_id_fkey(email, registration_date, status)')
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error loading student profile: $e');
    }
  }

  Future<List<Map<String, dynamic>>> loadActivityStats(String userId) async {
    try {
      List<Map<String, dynamic>> allActivities = [];

      // Get recent activity completions with details
      final recentActivitiesResponse = await Supabase.instance.client
          .from('activity_completions')
          .select('completion_id, completed_at, completion_date, activities(name, description, points)')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(20);

      // Add activity completions with type marker
      for (var activity in recentActivitiesResponse) {
        allActivities.add({
          ...activity,
          'activity_type': 'completion',
          'timestamp': activity['completed_at'],
        });
      }

      // Get counseling appointments
      final appointmentsResponse = await Supabase.instance.client
          .from('counseling_appointments')
          .select('appointment_id, appointment_date, start_time, status, counselors(first_name, last_name)')
          .eq('user_id', userId)
          .order('appointment_date', ascending: false)
          .limit(20);

      // Add appointments with type marker
      for (var appointment in appointmentsResponse) {
        allActivities.add({
          ...appointment,
          'activity_type': 'appointment',
          'timestamp': appointment['appointment_date'],
        });
      }

      // Sort all activities by timestamp (most recent first)
      allActivities.sort((a, b) {
        final aTime = DateTime.tryParse(a['timestamp']?.toString() ?? '') ?? DateTime(2000);
        final bTime = DateTime.tryParse(b['timestamp']?.toString() ?? '') ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      // Take only the most recent 20 items after combining
      return allActivities.take(20).toList();
    } catch (e) {
      throw Exception('Error loading activity stats: $e');
    }
  }

  Future<Map<String, dynamic>> loadJournalStats(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('journal_entries')
          .select(
              'journal_id, title, content, entry_timestamp, sentiment, is_shared_with_counselor')
          .eq('user_id', userId)
          .eq('is_shared_with_counselor', true)  // Only shared entries
          .order('entry_timestamp', ascending: false);

      return {
        'total': response.length,
        'recent': List<Map<String, dynamic>>.from(response.take(5)),
      };
    } catch (e) {
      throw Exception('Error loading journal stats: $e');
    }
  }

  Future<Map<String, dynamic>> loadQuestionnaireStats(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('questionnaire_responses')
          .select('''
            response_id, 
            total_score, 
            submission_timestamp,
            questionnaire_summaries(severity_level, insights, recommendations)
          ''')
          .eq('user_id', userId)
          .order('submission_timestamp', ascending: false);

      return {
        'total': response.length,
        'recent': List<Map<String, dynamic>>.from(response.take(5)),
      };
    } catch (e) {
      throw Exception('Error loading questionnaire stats: $e');
    }
  }

  Future<Map<String, dynamic>> loadSessionStats(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('counseling_session_notes')
          .select('''
            *, 
            counseling_appointments(appointment_date, start_time, end_time),
            counselors(counselor_id, first_name, last_name)
          ''')
          .eq('student_user_id', userId)
          .order('created_at', ascending: false);

      return {
        'total': response.length,
        'sessions': List<Map<String, dynamic>>.from(response),
      };
    } catch (e) {
      throw Exception('Error loading session stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> loadEmergencyContacts(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('emergency_contacts')
          .select('*')
          .eq('user_id', userId)
          .order('contact_id', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error loading emergency contacts: $e');
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
