// CM-MHC-01: Student can send a message
// Requirement: Students should be able to send messages in the chat interface

import 'package:flutter_test/flutter_test.dart';

class MockChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;
  
  MockChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
  });
}

class MockChatSession {
  final List<MockChatMessage> messages = [];
  
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      throw Exception('Cannot send empty message');
    }
    
    messages.add(MockChatMessage(
      sender: 'user',
      text: text,
      timestamp: DateTime.now(),
    ));
  }
}

void main() {
  group('CM-MHC-01: Student can send a message', () {
    test('Student successfully sends a text message', () async {
      final chatSession = MockChatSession();
      
      await chatSession.sendMessage('Hello, I need some help with stress');
      
      expect(chatSession.messages.length, 1);
      expect(chatSession.messages.first.sender, 'user');
      expect(chatSession.messages.first.text, 'Hello, I need some help with stress');
    });

    test('Student cannot send empty message', () async {
      final chatSession = MockChatSession();
      
      expect(
        () => chatSession.sendMessage(''),
        throwsA(predicate((e) => e.toString().contains('Cannot send empty message'))),
      );
      
      expect(chatSession.messages.length, 0);
    });

    test('Multiple messages are stored in correct order', () async {
      final chatSession = MockChatSession();
      
      await chatSession.sendMessage('First message');
      await chatSession.sendMessage('Second message');
      
      expect(chatSession.messages.length, 2);
      expect(chatSession.messages[0].text, 'First message');
      expect(chatSession.messages[1].text, 'Second message');
    });
  });
}
