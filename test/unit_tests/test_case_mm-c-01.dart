
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String id;
	MockUser(this.id);
}

class MockChatDatabase {
	final List<Map<String, dynamic>> messages = [];

	void storeMessage(String userId, String messageContent, String sender) {
		if (userId.isEmpty || messageContent.trim().isEmpty) return;
		messages.add({
			'user_id': userId,
			'message_content': messageContent,
			'sender': sender,
			'created_at': DateTime.now().toIso8601String(),
		});
	}

	List<Map<String, dynamic>> getRecentMessages(String userId, {int limit = 50}) {
		final userMessages = messages
				.where((msg) => msg['user_id'] == userId)
				.toList();
		userMessages.sort((a, b) => b['created_at'].compareTo(a['created_at']));
		return userMessages.take(limit).toList();
	}
}


void main() {
	group('MM-C-01: Chat message send and retrieve', () {
		final user = MockUser('user-123');

		test('User can send a message and see it in chat', () {
			final db = MockChatDatabase();
      db.storeMessage(user.id, 'Hello, this is a test!', 'user');
			db.storeMessage(user.id, 'Second message', 'user');
			db.storeMessage(user.id, 'Third message', 'user');
			final messages = db.getRecentMessages(user.id);
			expect(messages.length, 1);
			expect(messages[0]['message_content'], 'Hello, this is a test!');
			expect(messages[0]['sender'], 'user');
		});

		test('Empty message is not stored', () {
			final db = MockChatDatabase();
			db.storeMessage(user.id, '', 'user');
			final messages = db.getRecentMessages(user.id);
			expect(messages.length, 0); // No valid message exists
		});

		test('Multiple messages are ordered by created_at desc', ()  {
			final db = MockChatDatabase();
			// Pre-store a message so that three messages exist for this tes
			final messages = db.getRecentMessages(user.id);
			expect(messages.length, 3);
			expect(messages[0]['message_content'], 'Third message');
			expect(messages[1]['message_content'], 'Second message');
			expect(messages[2]['message_content'], 'Hello, this is a test!');
		});
	});
}
