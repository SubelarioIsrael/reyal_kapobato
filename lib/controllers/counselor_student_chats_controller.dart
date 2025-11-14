import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/department_mapping.dart';

class CounselorStudentChatsController {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get counselor ID and department for the current user
  Future<Map<String, dynamic>?> getCounselorInfo() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final counselorResponse = await _supabase
          .from('counselors')
          .select('counselor_id, department_assigned')
          .eq('user_id', currentUser.id)
          .single();

      return {
        'counselor_id': counselorResponse['counselor_id'] as int,
        'department': counselorResponse['department_assigned'] as String,
      };
    } catch (e) {
      print('Error getting counselor info: $e');
      return null;
    }
  }

  /// Get counselor ID for the current user (backward compatibility)
  Future<int?> getCounselorId() async {
    final info = await getCounselorInfo();
    return info?['counselor_id'] as int?;
  }

  /// Load students from counselor's department with direct messages (no appointment required)
  Future<List<Map<String, dynamic>>> loadAppointmentsWithMessages(int counselorId, String? counselorDepartment) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get all students from the counselor's department if not volunteer
      List<Map<String, dynamic>> departmentStudents = [];
      
      if (counselorDepartment != null && counselorDepartment != 'Volunteer') {
        // Get all students from this department
        final allStudents = await _supabase
            .from('students')
            .select('user_id, first_name, last_name, education_level, course, strand');

        for (var student in allStudents) {
          final educationLevel = student['education_level'] as String?;
          final course = student['course'] as String?;
          final strand = student['strand'] as String?;
          
          // Use the DepartmentMapping utility
          final studentDepartment = DepartmentMapping.getStudentDepartment(
            educationLevel: educationLevel?.toLowerCase(),
            course: course,
            strand: strand,
          );

          if (studentDepartment == counselorDepartment) {
            departmentStudents.add(student);
          }
        }
      } else {
        // Volunteer counselors: get all students who have sent them messages
        final messagedStudents = await _supabase
            .from('messages')
            .select('sender_id, receiver_id')
            .or('sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}')
            .isFilter('appointment_id', null);

        final studentUserIds = <String>{};
        for (var msg in messagedStudents) {
          if (msg['sender_id'] != currentUser.id) {
            studentUserIds.add(msg['sender_id']);
          }
          if (msg['receiver_id'] != currentUser.id) {
            studentUserIds.add(msg['receiver_id']);
          }
        }

        if (studentUserIds.isNotEmpty) {
          departmentStudents = await _supabase
              .from('students')
              .select('user_id, first_name, last_name, education_level, course, strand')
              .inFilter('user_id', studentUserIds.toList());
        }
      }

      if (departmentStudents.isEmpty) {
        return [];
      }

      // Create student chat groups
      Map<String, Map<String, dynamic>> studentGroups = {};

      for (var student in departmentStudents) {
        final studentUserId = student['user_id'] as String;
        
        // Get direct messages with this student
        final messages = await _supabase
            .from('messages')
            .select('sender_id, receiver_id, created_at, message, is_read')
            .or('and(sender_id.eq.$studentUserId,receiver_id.eq.${currentUser.id}),and(sender_id.eq.${currentUser.id},receiver_id.eq.$studentUserId)')
            .isFilter('appointment_id', null)
            .order('created_at', ascending: false);
        
        // Filter to messages between counselor and this student
        final relevantMessages = messages.where((msg) {
          return (msg['sender_id'] == currentUser.id && msg['receiver_id'] == studentUserId) ||
                 (msg['sender_id'] == studentUserId && msg['receiver_id'] == currentUser.id);
        }).toList();

        String? lastMessage;
        DateTime? lastMessageTime;
        int unreadCount = 0;

        if (relevantMessages.isNotEmpty) {
          final latestMessage = relevantMessages.first;
          lastMessage = latestMessage['message'];
          lastMessageTime = DateTime.parse(latestMessage['created_at']);

          // Count unread messages from student
          unreadCount = relevantMessages.where((msg) =>
              msg['receiver_id'] == currentUser.id && !(msg['is_read'] ?? true)
          ).length;
        } else {
          lastMessage = 'No messages yet';
          lastMessageTime = null;
        }

        final studentInfo = await _getStudentInfo(studentUserId);

        studentGroups[studentUserId] = {
          'appointment': {
            'user_id': studentUserId,
            'counselor_id': counselorId,
            'status': 'direct_chat',
          },
          'user_name': studentInfo['name'],
          'user_initials': studentInfo['initials'],
          'messages': relevantMessages,
          'unread_count': unreadCount,
          'last_message': lastMessage,
          'last_message_time': lastMessageTime,
        };
      }

      // Convert to list and sort by last message time
      final studentsList = studentGroups.values.toList();
      studentsList.sort((a, b) {
        final timeA = a['last_message_time'] as DateTime?;
        final timeB = b['last_message_time'] as DateTime?;
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA);
      });

      return studentsList;
    } catch (e) {
      print('Error loading student chats: $e');
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

  /// Search students by name
  List<Map<String, dynamic>> searchStudents(List<Map<String, dynamic>> chats, String query) {
    if (query.trim().isEmpty) {
      return chats;
    }

    final searchQuery = query.trim().toLowerCase();
    return chats.where((chat) {
      final userName = (chat['user_name'] as String).toLowerCase();
      return userName.contains(searchQuery);
    }).toList();
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
