import 'package:supabase_flutter/supabase_flutter.dart';

class CounselorStudentChatsController {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get counselor ID for the current user
  Future<int?> getCounselorId() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final counselorResponse = await _supabase
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', currentUser.id)
          .single();

      return counselorResponse['counselor_id'] as int;
    } catch (e) {
      print('Error getting counselor ID: $e');
      return null;
    }
  }

  /// Load appointments with messages for a counselor
  Future<List<Map<String, dynamic>>> loadAppointmentsWithMessages(int counselorId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get accepted appointments
      final acceptedAppointments = await _supabase
          .from('counseling_appointments')
          .select('appointment_id, user_id, counselor_id, appointment_date, start_time, end_time, status, notes')
          .eq('counselor_id', counselorId)
          .eq('status', 'accepted');

      if (acceptedAppointments.isEmpty) {
        return [];
      }

      final appointmentIds = acceptedAppointments.map((a) => a['appointment_id']).toList();

      // Get messages for accepted appointments
      final appointmentsWithMessages = await _supabase
          .from('messages')
          .select('appointment_id, sender_id, receiver_id, created_at, message, is_read')
          .inFilter('appointment_id', appointmentIds)
          .order('created_at', ascending: false);

      // Create appointment groups
      Map<int, Map<String, dynamic>> appointmentGroups = {};

      // Initialize groups for all accepted appointments
      for (var appointment in acceptedAppointments) {
        final appointmentId = appointment['appointment_id'];
        appointmentGroups[appointmentId] = {
          'appointment': appointment,
          'user_name': 'Unknown User',
          'user_initials': 'UU',
          'messages': [],
          'unread_count': 0,
          'last_message': null,
          'last_message_time': null,
        };
      }

      // Add messages to their respective appointment groups
      for (var message in appointmentsWithMessages) {
        final appointmentId = message['appointment_id'];
        
        if (appointmentGroups.containsKey(appointmentId)) {
          appointmentGroups[appointmentId]!['messages'].add(message);

          // Update last message if this is more recent
          final messageTime = DateTime.parse(message['created_at']);
          if (appointmentGroups[appointmentId]!['last_message_time'] == null ||
              messageTime.isAfter(appointmentGroups[appointmentId]!['last_message_time'])) {
            appointmentGroups[appointmentId]!['last_message'] = message['message'];
            appointmentGroups[appointmentId]!['last_message_time'] = messageTime;
          }

          // Count unread messages (from student to counselor)
          if (message['receiver_id'] == currentUser.id && !message['is_read']) {
            appointmentGroups[appointmentId]!['unread_count']++;
          }
        }
      }

      // Fetch student information for each appointment
      for (var appointmentGroup in appointmentGroups.values) {
        final userId = appointmentGroup['appointment']['user_id'];
        final studentInfo = await _getStudentInfo(userId);
        
        appointmentGroup['user_name'] = studentInfo['name'];
        appointmentGroup['user_initials'] = studentInfo['initials'];
      }

      // Convert to list and sort by last message time
      final appointmentsList = appointmentGroups.values.toList();
      appointmentsList.sort((a, b) {
        final timeA = a['last_message_time'] as DateTime?;
        final timeB = b['last_message_time'] as DateTime?;
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); // Most recent first
      });

      return appointmentsList;
    } catch (e) {
      print('Error loading appointments with messages: $e');
      rethrow;
    }
  }

  /// Get student information (name and initials)
  Future<Map<String, String>> _getStudentInfo(String userId) async {
    try {
      // Try to get student info
      final studentInfo = await _supabase
          .from('students')
          .select('user_id, first_name, last_name, student_code')
          .eq('user_id', userId)
          .maybeSingle();

      if (studentInfo != null &&
          studentInfo['first_name'] != null &&
          studentInfo['last_name'] != null &&
          studentInfo['first_name'].isNotEmpty &&
          studentInfo['last_name'].isNotEmpty) {
        final firstName = studentInfo['first_name'];
        final lastName = studentInfo['last_name'];

        // Helper function to properly capitalize names
        String formatName(String name) {
          if (name.isEmpty) return name;
          return name[0].toUpperCase() + name.substring(1);
        }

        return {
          'name': '${formatName(firstName)} ${formatName(lastName)}',
          'initials': '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}',
        };
      } else {
        // Fallback to email if student info not found
        final userInfo = await _supabase
            .from('users')
            .select('email')
            .eq('user_id', userId)
            .maybeSingle();

        if (userInfo != null && userInfo['email'] != null) {
          final email = userInfo['email'];
          return {
            'name': email,
            'initials': email.length >= 2
                ? email.substring(0, 2).toUpperCase()
                : email[0].toUpperCase(),
          };
        }
      }
    } catch (e) {
      print('Error fetching student info for user_id $userId: $e');
    }

    return {
      'name': 'Unknown User',
      'initials': 'UU',
    };
  }

  /// Subscribe to realtime updates for messages
  RealtimeChannel subscribeToMessages(Function() onUpdate) {
    return _supabase
        .channel('counselor_chat_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) => onUpdate(),
        )
        .subscribe();
  }

  /// Unsubscribe from all channels
  void dispose() {
    _supabase.removeAllChannels();
  }
}
