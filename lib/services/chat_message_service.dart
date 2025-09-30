import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessageService {
  static final supabase = Supabase.instance.client;

  /// Stores a chat message in the database
  static Future<void> storeMessage(String messageContent, String sender) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('chat_messages').insert({
        'user_id': userId,
        'message_content': messageContent,
        'sender': sender, // 'user' or 'bot'
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error storing chat message: $e');
    }
  }

  /// Retrieves recent chat messages for a user
  static Future<List<Map<String, dynamic>>> getRecentMessages({
    int limit = 50,
    Duration? timeWindow,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await supabase
          .from('chat_messages')
          .select('message_content, sender, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (timeWindow != null) {
        final cutoffTime = DateTime.now().subtract(timeWindow);
        final filteredResponse = response.where((message) {
          final messageTime = DateTime.parse(message['created_at']);
          return messageTime.isAfter(cutoffTime);
        }).toList();
        return List<Map<String, dynamic>>.from(filteredResponse);
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error retrieving chat messages: $e');
      return [];
    }
  }

  /// Clears old chat messages (for privacy and performance)
  static Future<void> clearOldMessages(
      {Duration age = const Duration(days: 30)}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final cutoffTime = DateTime.now().subtract(age);
      await supabase
          .from('chat_messages')
          .delete()
          .eq('user_id', userId)
          .lt('created_at', cutoffTime.toIso8601String());
    } catch (e) {
      print('Error clearing old messages: $e');
    }
  }

  /// Checks for unread messages from counselors to the current student
  static Future<int> getUnreadMessagesFromCounselors() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return 0;

    try {
      // Get all counselors that have appointments with this student
      final appointmentsResponse = await supabase
          .from('counseling_appointments')
          .select('counselor_id')
          .eq('user_id', currentUserId);

      final Set<int> counselorIds = (appointmentsResponse as List)
          .map((e) => e['counselor_id'] as int)
          .toSet();

      if (counselorIds.isEmpty) return 0;

      // Get counselor user_ids
      final counselorsResponse = await supabase
          .from('counselors')
          .select('user_id, counselor_id')
          .inFilter('counselor_id', counselorIds.toList());

      final counselorUserIds = (counselorsResponse as List)
          .map((e) => e['user_id'] as String)
          .toList();

      if (counselorUserIds.isEmpty) return 0;

      // Count unread messages from counselors to this student
      final unreadResponse = await supabase
          .from('messages')
          .select('id')
          .eq('receiver_id', currentUserId)
          .inFilter('sender_id', counselorUserIds)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return unreadResponse.length;
    } catch (e) {
      print('Error getting unread messages count: $e');
      return 0;
    }
  }

  /// Marks messages as read when user opens chat
  static Future<void> markMessagesAsRead(String senderUserId) async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      print('No current user ID for marking messages as read');
      return;
    }

    try {
      print('Marking messages as read from sender: $senderUserId to receiver: $currentUserId');
      
      // First check what messages we're about to update
      final unreadMessages = await supabase
          .from('messages')
          .select('id, message, is_read')
          .eq('receiver_id', currentUserId)
          .eq('sender_id', senderUserId)
          .eq('is_read', false);
      
      print('Found ${unreadMessages.length} unread messages to mark as read');
      
      if (unreadMessages.isNotEmpty) {
        final result = await supabase
            .from('messages')
            .update({'is_read': true})
            .eq('receiver_id', currentUserId)
            .eq('sender_id', senderUserId)
            .eq('is_read', false); // Only update unread messages
            
        print('Mark as read result: $result');
        print('Successfully marked ${unreadMessages.length} messages as read');
      } else {
        print('No unread messages found to mark as read');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      print('Error details: ${e.toString()}');
    }
  }

  /// Gets unread messages grouped by counselor
  static Future<Map<String, int>> getUnreadMessagesByCounselor() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return {};

    try {
      // Get all counselors that have appointments with this student
      final appointmentsResponse = await supabase
          .from('counseling_appointments')
          .select('counselor_id')
          .eq('user_id', currentUserId);

      final Set<int> counselorIds = (appointmentsResponse as List)
          .map((e) => e['counselor_id'] as int)
          .toSet();

      if (counselorIds.isEmpty) return {};

      // Get counselor details
      final counselorsResponse = await supabase
          .from('counselors')
          .select('user_id, counselor_id, first_name, last_name')
          .inFilter('counselor_id', counselorIds.toList());

      final Map<String, int> unreadByCounselor = {};

      for (final counselor in counselorsResponse) {
        final counselorUserId = counselor['user_id'] as String;
        final counselorName = '${counselor['first_name'] ?? ''} ${counselor['last_name'] ?? ''}'.trim();

        // Count unread messages from this counselor
        final unreadResponse = await supabase
            .from('messages')
            .select('id')
            .eq('receiver_id', currentUserId)
            .eq('sender_id', counselorUserId)
            .eq('is_read', false);

        final count = unreadResponse.length;
        if (count > 0) {
          unreadByCounselor[counselorName] = count;
        }
      }

      return unreadByCounselor;
    } catch (e) {
      print('Error getting unread messages by counselor: $e');
      return {};
    }
  }
}
