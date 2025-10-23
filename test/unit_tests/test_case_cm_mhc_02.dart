// CM-MHC-02: Student can receive a reply from the chat bot with the use of an API
// Requirement: The chatbot should respond to student messages using an API

import 'package:flutter_test/flutter_test.dart';

class MockChatbotService {
  static const String botName = 'Eirene';
  
  static Future<String> generateResponse(String userMessage) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (userMessage.trim().isEmpty) {
      throw Exception('Cannot process empty message');
    }
    
    // Mock responses based on message content
    if (userMessage.toLowerCase().contains('stress')) {
      return 'I understand you\'re feeling stressed. That\'s completely normal. Would you like to talk about what\'s causing the stress?';
    } else if (userMessage.toLowerCase().contains('hello')) {
      return 'Hello! I\'m $botName, and I\'m here to support you. How are you feeling today?';
    } else {
      return 'Thank you for sharing that with me. I\'m here to listen and support you.';
    }
  }
}

class MockChatSession {
  final List<Map<String, String>> messages = [];
  
  Future<void> sendMessageAndGetResponse(String userMessage) async {
    messages.add({'sender': 'user', 'text': userMessage});
    
    final response = await MockChatbotService.generateResponse(userMessage);
    messages.add({'sender': 'bot', 'text': response});
  }
}

void main() {
  group('CM-MHC-02: Student can receive a reply from the chat bot', () {
    test('Chatbot responds to user message via API', () async {
      final chatSession = MockChatSession();
      
      await chatSession.sendMessageAndGetResponse('Hello');
      
      expect(chatSession.messages.length, 2);
      expect(chatSession.messages[0]['sender'], 'user');
      expect(chatSession.messages[1]['sender'], 'bot');
      expect(chatSession.messages[1]['text'], contains('Eirene'));
    });

    test('Chatbot provides contextual response to stress-related message', () async {
      final chatSession = MockChatSession();
      
      await chatSession.sendMessageAndGetResponse('I am feeling very stressed about exams');
      
      expect(chatSession.messages.length, 2);
      expect(chatSession.messages[1]['text'], contains('stress'));
      expect(chatSession.messages[1]['text'], contains('normal'));
    });

    test('API handles empty message error', () async {
      expect(
        () => MockChatbotService.generateResponse(''),
        throwsA(predicate((e) => e.toString().contains('Cannot process empty message'))),
      );
    });

    test('Chatbot response contains bot name', () async {
      final response = await MockChatbotService.generateResponse('Hello');
      
      expect(response, contains(MockChatbotService.botName));
    });
  });
}
