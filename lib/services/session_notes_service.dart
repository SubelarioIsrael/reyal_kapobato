import 'package:supabase_flutter/supabase_flutter.dart';

class SessionNotesService {
  static final _supabase = Supabase.instance.client;

  /// Create or update session notes for a counseling session
  static Future<void> saveSessionNotes({
    required int counselorId,
    required String studentUserId,
    required String summary,
    String? topicsDiscussed,
    String? recommendations,
    int? appointmentId,
  }) async {
    final notesData = {
      'counselor_id': counselorId,
      'student_user_id': studentUserId,
      'summary': summary,
      'topics_discussed': topicsDiscussed,
      'recommendations': recommendations,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (appointmentId != null) {
      notesData['appointment_id'] = appointmentId;
    }

    // Check if notes already exist for this appointment
    if (appointmentId != null) {
      final existingNotes = await _supabase
          .from('counseling_session_notes')
          .select('session_note_id')
          .eq('appointment_id', appointmentId)
          .eq('counselor_id', counselorId)
          .maybeSingle();

      if (existingNotes != null) {
        // Update existing notes
        await _supabase
            .from('counseling_session_notes')
            .update({
              'summary': summary,
              'topics_discussed': topicsDiscussed,
              'recommendations': recommendations,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('session_note_id', existingNotes['session_note_id']);
        return;
      }
    }

    // Create new notes
    await _supabase.from('counseling_session_notes').insert(notesData);
  }

  /// Get session notes for a specific appointment
  static Future<Map<String, dynamic>?> getSessionNotesByAppointment(
    int appointmentId,
    int counselorId,
  ) async {
    return await _supabase
        .from('counseling_session_notes')
        .select()
        .eq('appointment_id', appointmentId)
        .eq('counselor_id', counselorId)
        .maybeSingle();
  }

  /// Get recent session notes for a student (within last 24 hours)
  static Future<Map<String, dynamic>?> getRecentSessionNotes(
    String studentUserId,
    int counselorId,
  ) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    final notes = await _supabase
        .from('counseling_session_notes')
        .select()
        .eq('student_user_id', studentUserId)
        .eq('counselor_id', counselorId)
        .gte('created_at', yesterday.toIso8601String())
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return notes;
  }

  /// Get all session notes for a student by a specific counselor
  static Future<List<Map<String, dynamic>>> getSessionNotesHistory(
    String studentUserId,
    int counselorId,
  ) async {
    final notes = await _supabase
        .from('counseling_session_notes')
        .select('''
          *,
          counseling_appointments(appointment_date, start_time, end_time)
        ''')
        .eq('student_user_id', studentUserId)
        .eq('counselor_id', counselorId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(notes);
  }

  /// Update video call status after session ends
  static Future<void> endVideoCallSession(String callCode) async {
    await _supabase
        .from('video_calls')
        .update({
          'status': 'ended',
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('call_code', callCode);
  }

  /// Get video call details including student information
  static Future<Map<String, dynamic>?> getVideoCallDetails(String callCode) async {
    return await _supabase
        .from('video_calls')
        .select('''
          *,
          users!video_calls_student_user_id_fkey(user_id),
          counselors(counselor_id, first_name, last_name)
        ''')
        .eq('call_code', callCode)
        .maybeSingle();
  }

  /// Find today's appointment between counselor and student
  static Future<int?> findTodaysAppointment(
    int counselorId,
    String studentUserId,
  ) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final appointment = await _supabase
        .from('counseling_appointments')
        .select('appointment_id')
        .eq('counselor_id', counselorId)
        .eq('user_id', studentUserId)
        .eq('appointment_date', todayStr)
        .eq('status', 'accepted')
        .maybeSingle();

    return appointment?['appointment_id'];
  }
}