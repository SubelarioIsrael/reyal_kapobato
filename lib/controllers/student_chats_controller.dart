import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/department_mapping.dart';

class StudentChatsController {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get student's department based on their course/education level
  Future<String?> getStudentDepartment() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final studentData = await _supabase
          .from('students')
          .select('education_level, course, strand')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (studentData == null) return null;

      return DepartmentMapping.getStudentDepartment(
        educationLevel: studentData['education_level'],
        course: studentData['course'],
        strand: studentData['strand'],
      );
    } catch (e) {
      print('Error getting student department: $e');
      return null;
    }
  }

  /// Load counselors from student's department with their latest messages (direct chat - no appointment required)
  Future<List<Map<String, dynamic>>> loadCounselorChats(String studentDepartment) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get all counselors assigned to the student's department or volunteers
      final counselors = await _supabase
          .from('counselors')
          .select('counselor_id, first_name, last_name, department_assigned, user_id')
          .or('department_assigned.eq.$studentDepartment,department_assigned.eq.Volunteer');

      if (counselors.isEmpty) {
        return [];
      }

      // Create counselor chat entries
      Map<int, Map<String, dynamic>> counselorChatsMap = {};

      for (var counselor in counselors) {
        final counselorId = counselor['counselor_id'] as int;
        final counselorUserId = counselor['user_id'] as String;
        final firstName = counselor['first_name'] ?? '';
        final lastName = counselor['last_name'] ?? '';

        // Get direct messages between student and counselor (no appointment_id)
        final messages = await _supabase
            .from('messages')
            .select('id, message, created_at, is_read, sender_id, receiver_id')
            .or('and(sender_id.eq.$counselorUserId,receiver_id.eq.${currentUser.id}),and(sender_id.eq.${currentUser.id},receiver_id.eq.$counselorUserId)')
            .isFilter('appointment_id', null)
            .order('created_at', ascending: false)
            .limit(1);

        // Filter to only messages between these two users
        final relevantMessages = messages.where((msg) {
          return (msg['sender_id'] == currentUser.id && msg['receiver_id'] == counselorUserId) ||
                 (msg['sender_id'] == counselorUserId && msg['receiver_id'] == currentUser.id);
        }).toList();

        String lastMessage;
        String? lastMessageTime;
        bool isRead = true;

        if (relevantMessages.isNotEmpty) {
          final latestMessage = relevantMessages.first;
          lastMessage = latestMessage['message'];
          lastMessageTime = latestMessage['created_at'];
          // Check if latest message is unread and received by student
          isRead = (latestMessage['is_read'] ?? true) ||
              latestMessage['receiver_id'] != currentUser.id;
        } else {
          // No messages yet
          lastMessage = 'No messages yet - Start chatting';
          lastMessageTime = null;
        }

        counselorChatsMap[counselorId] = {
          'counselor_id': counselorId,
          'counselor_user_id': counselorUserId,
          'counselor_name': '$firstName $lastName',
          'counselor_first_name': firstName,
          'counselor_last_name': lastName,
          'last_message': lastMessage,
          'last_message_time': lastMessageTime,
          'is_read': isRead,
        };
      }

      // Convert to list and sort by last message time
      final chatsList = counselorChatsMap.values.toList();
      chatsList.sort((a, b) {
        final timeA = a['last_message_time'] as String?;
        final timeB = b['last_message_time'] as String?;
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return DateTime.parse(timeB).compareTo(DateTime.parse(timeA));
      });

      return chatsList;
    } catch (e) {
      print('Error loading counselor chats: $e');
      rethrow;
    }
  }

  /// Search counselors by name
  List<Map<String, dynamic>> searchCounselors(List<Map<String, dynamic>> chats, String query) {
    if (query.trim().isEmpty) {
      return chats;
    }

    final searchQuery = query.trim().toLowerCase();
    return chats.where((chat) {
      final counselorName = (chat['counselor_name'] as String).toLowerCase();
      return counselorName.contains(searchQuery);
    }).toList();
  }

  /// Subscribe to realtime updates for messages
  RealtimeChannel subscribeToMessages(Function() onUpdate) {
    return _supabase
        .channel('student_chat_updates')
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
