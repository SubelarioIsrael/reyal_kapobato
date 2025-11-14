import '../services/chatbot_service.dart';
import '../services/intervention_service.dart';
import '../services/chat_message_service.dart';

class StudentChatbotController {
  // Abuse protection constants
  static const Duration _sendCooldown = Duration(seconds: 3);
  static const Duration _windowDuration = Duration(minutes: 10);
  static const int _windowMaxMessages = 15;

  DateTime? _lastSendAt;
  final List<DateTime> _sendTimestamps = [];

  /// Check if user can send a message (cooldown and rate limiting)
  CooldownCheckResult checkCooldown() {
    final now = DateTime.now();

    // Check cooldown
    if (_lastSendAt != null && now.difference(_lastSendAt!) < _sendCooldown) {
      final remaining = _sendCooldown - now.difference(_lastSendAt!);
      return CooldownCheckResult(
        canSend: false,
        errorMessage: 'Please wait ${remaining.inSeconds}s before sending again.',
      );
    }

    // Check rolling window cap
    _sendTimestamps.removeWhere((t) => now.difference(t) > _windowDuration);
    if (_sendTimestamps.length >= _windowMaxMessages) {
      return CooldownCheckResult(
        canSend: false,
        errorMessage: 'You have reached the message limit. Please try again later.',
      );
    }

    return CooldownCheckResult(canSend: true);
  }

  /// Record that a message was sent
  void recordMessageSent() {
    final now = DateTime.now();
    _sendTimestamps.add(now);
    _lastSendAt = now;
  }

  /// Send a message and get response
  Future<SendMessageResult> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return SendMessageResult(
        success: false,
        errorMessage: 'Message cannot be empty',
      );
    }

    try {
      // Store user message
      await ChatMessageService.storeMessage(text, 'user');

      // Check for intervention triggers
      final interventionResult = await _checkForIntervention(text);

      // Get bot response
      final response = await ChatbotService.generateResponse(text);

      // Store bot response
      await ChatMessageService.storeMessage(response, 'bot');

      return SendMessageResult(
        success: true,
        botResponse: response,
        interventionLevel: interventionResult.interventionLevel,
        hotlines: interventionResult.hotlines,
      );
    } catch (e) {
      print('Error sending message: $e');
      return SendMessageResult(
        success: false,
        errorMessage: e.toString(),
        botResponse: "I'm sorry, I'm having trouble responding right now. Please try again later.",
      );
    }
  }

  /// Check if the message requires intervention
  Future<InterventionCheckResult> _checkForIntervention(String message) async {
    try {
      // Analyze the current message
      final messageLevel = InterventionService.analyzeMessage(message);

      // If the message itself is concerning, trigger intervention
      if (messageLevel != InterventionLevel.none) {
        final hasRecent = await InterventionService.hasRecentIntervention();
        if (!hasRecent) {
          await InterventionService.triggerIntervention(messageLevel, message);
          if (messageLevel == InterventionLevel.high) {
            final hotlines = await InterventionService.fetchHotlines(limit: 5);
            return InterventionCheckResult(
              interventionLevel: messageLevel,
              hotlines: hotlines,
            );
          }
        }
        return InterventionCheckResult(interventionLevel: messageLevel);
      }

      // Analyze recent chat history for patterns
      final historyLevel = await InterventionService.analyzeRecentChatHistory();
      if (historyLevel != InterventionLevel.none) {
        final hasRecent = await InterventionService.hasRecentIntervention();
        if (!hasRecent) {
          await InterventionService.triggerIntervention(historyLevel, message);
          if (historyLevel == InterventionLevel.high) {
            final hotlines = await InterventionService.fetchHotlines(limit: 5);
            return InterventionCheckResult(
              interventionLevel: historyLevel,
              hotlines: hotlines,
            );
          }
        }
        return InterventionCheckResult(interventionLevel: historyLevel);
      }

      return InterventionCheckResult(interventionLevel: InterventionLevel.none);
    } catch (e) {
      print('Error checking for intervention: $e');
      return InterventionCheckResult(interventionLevel: InterventionLevel.none);
    }
  }

  /// Get the bot name
  String getBotName() {
    return ChatbotService.botName;
  }
}

class CooldownCheckResult {
  final bool canSend;
  final String? errorMessage;

  CooldownCheckResult({
    required this.canSend,
    this.errorMessage,
  });
}

class SendMessageResult {
  final bool success;
  final String? botResponse;
  final String? errorMessage;
  final InterventionLevel? interventionLevel;
  final List<Map<String, dynamic>>? hotlines;

  SendMessageResult({
    required this.success,
    this.botResponse,
    this.errorMessage,
    this.interventionLevel,
    this.hotlines,
  });
}

class InterventionCheckResult {
  final InterventionLevel interventionLevel;
  final List<Map<String, dynamic>>? hotlines;

  InterventionCheckResult({
    required this.interventionLevel,
    this.hotlines,
  });
}
