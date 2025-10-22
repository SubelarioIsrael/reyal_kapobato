// MM-C-02: Retrieve chat messages between student and counselor
// Requirement: When student opens chat with a counselor, they see all messages related to that counselor
// This test uses a mock DB and follows the logic in chat_message_service.getRecentMessages

import 'package:flutter_test/flutter_test.dart';

class MockUser {
  final String id;
  final String role; // 'student' or 'counselor'
  MockUser(this.id, this.role);
}

class MockChatDatabase {
  final List<Map<String, dynamic>> messages = [];

  void seedMessages(List<Map<String, dynamic>> initial) {
    messages.addAll(initial);
  }

  List<Map<String, dynamic>> getRecentMessagesForChat(String studentId, String counselorId, {int limit = 50}) {
    final chatMessages = messages.where((m) =>
      (m['user_id'] == studentId && m['receiver_id'] == counselorId) ||
      (m['user_id'] == counselorId && m['receiver_id'] == studentId)
    ).toList();
    chatMessages.sort((a, b) => b['created_at'].compareTo(a['created_at']));
    return chatMessages.take(limit).toList();
  }
}

void main() {
  group('MM-C-02: Student opens chat with counselor and sees messages', () {
    final student = MockUser('student-1', 'student');
    final counselor = MockUser('counselor-1', 'counselor');
    final db = MockChatDatabase();

    db.seedMessages([
      {'user_id': student.id, 'receiver_id': counselor.id, 'message_content': 'Hi counselor', 'sender': 'user', 'created_at': DateTime.now().subtract(Duration(minutes: 3)).toIso8601String()},
      {'user_id': counselor.id, 'receiver_id': student.id, 'message_content': 'Hello student', 'sender': 'counselor', 'created_at': DateTime.now().subtract(Duration(minutes: 2)).toIso8601String()},
      {'user_id': student.id, 'receiver_id': counselor.id, 'message_content': 'I need help', 'sender': 'user', 'created_at': DateTime.now().subtract(Duration(minutes: 1)).toIso8601String()},
      // Other unrelated chat
      {'user_id': student.id, 'receiver_id': 'other-counselor', 'message_content': 'Other chat', 'sender': 'user', 'created_at': DateTime.now().toIso8601String()},
    ]);

    test('Retrieve messages for student-counselor chat ordered desc', () {
      final messages = db.getRecentMessagesForChat(student.id, counselor.id);
      expect(messages.length, 3);
      expect(messages[0]['message_content'], 'I need help');
      expect(messages[1]['message_content'], 'Hello student');
      expect(messages[2]['message_content'], 'Hi counselor');
    });

    test('Limit parameter works', () {
      final messages = db.getRecentMessagesForChat(student.id, counselor.id, limit: 2);
      expect(messages.length, 2);
    });
  });
}
