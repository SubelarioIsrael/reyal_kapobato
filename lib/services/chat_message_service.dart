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
}
