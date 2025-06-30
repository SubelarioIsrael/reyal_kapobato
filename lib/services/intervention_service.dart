import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class InterventionService {
  static final supabase = Supabase.instance.client;
  static Duration interventionCooldown =
      const Duration(hours: 6); // Easily modifiable cooldown

  // Keywords and phrases that might indicate concerning content
  static const List<String> _concerningKeywords = [
    'suicide',
    'kill myself',
    'want to die',
    'end it all',
    'no reason to live',
    'self harm',
    'cut myself',
    'hurt myself',
    'self injury',
    'depression',
    'hopeless',
    'worthless',
    'useless',
    'burden',
    'anxiety',
    'panic attack',
    'can\'t breathe',
    'heart attack',
    'abuse',
    'domestic violence',
    'sexual assault',
    'trauma',
    'drugs',
    'alcohol',
    'substance abuse',
    'overdose',
    'bullying',
    'harassment',
    'discrimination',
    'lonely',
    'isolated',
    'no friends',
    'no one cares',
    'stress',
    'overwhelmed',
    'can\'t cope',
    'breaking point'
  ];

  // High-risk phrases that require immediate attention
  static const List<String> _highRiskPhrases = [
    'suicide',
    'kill myself',
    'want to die',
    'end it all',
    'self harm',
    'cut myself',
    'hurt myself',
    'abuse',
    'domestic violence',
    'sexual assault'
  ];

  /// Analyzes a chat message for concerning content
  static InterventionLevel analyzeMessage(String message) {
    final lowerMessage = message.toLowerCase();

    // Check for high-risk phrases first
    for (final phrase in _highRiskPhrases) {
      if (lowerMessage.contains(phrase)) {
        return InterventionLevel.high;
      }
    }

    // Check for concerning keywords
    int concerningCount = 0;
    for (final keyword in _concerningKeywords) {
      if (lowerMessage.contains(keyword)) {
        concerningCount++;
      }
    }

    if (concerningCount >= 3) {
      return InterventionLevel.high;
    } else if (concerningCount >= 1) {
      return InterventionLevel.moderate;
    }

    return InterventionLevel.none;
  }

  /// Analyzes recent chat history for patterns
  static Future<InterventionLevel> analyzeRecentChatHistory() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return InterventionLevel.none;

    try {
      // Get recent messages from the last 24 hours
      final response = await supabase
          .from('chat_messages')
          .select('message_content, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      if (response == null || response.isEmpty) {
        return InterventionLevel.none;
      }

      // Filter messages from the last 24 hours
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final recentMessages = response.where((message) {
        final messageTime = DateTime.parse(message['created_at']);
        return messageTime.isAfter(cutoffTime);
      }).toList();

      if (recentMessages.isEmpty) {
        return InterventionLevel.none;
      }

      int highRiskCount = 0;
      int moderateRiskCount = 0;

      for (final message in recentMessages) {
        final level = analyzeMessage(message['message_content'] ?? '');
        if (level == InterventionLevel.high) {
          highRiskCount++;
        } else if (level == InterventionLevel.moderate) {
          moderateRiskCount++;
        }
      }

      if (highRiskCount >= 2) {
        return InterventionLevel.high;
      } else if (highRiskCount >= 1 || moderateRiskCount >= 3) {
        return InterventionLevel.moderate;
      }

      return InterventionLevel.none;
    } catch (e) {
      print('Error analyzing chat history: $e');
      return InterventionLevel.none;
    }
  }

  /// Triggers intervention based on the level
  static Future<void> triggerIntervention(
      InterventionLevel level, String triggerMessage) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    String notificationContent;
    String notificationType;

    switch (level) {
      case InterventionLevel.high:
        notificationContent = '''
We care about you and want you to know that you are not alone. If things feel overwhelming, please consider reaching out to someone you trust or a professional who can help.

If you need someone to talk to, here are some hotlines in the Philippines:
• National Center for Mental Health Crisis Hotline: 1553 (landline)
• Globe/TM: 0966-351-4518, 0917-899-8727
• Smart/Sun/TNT: 0908-639-2672

You can also talk to your school counselor, a trusted teacher, or a close friend or family member. Remember, reaching out is a sign of strength. We're here for you.''';
        notificationType = 'Urgent Support Needed';
        break;

      case InterventionLevel.moderate:
        notificationContent = '''
We noticed you might be going through a tough time. Remember, it's okay to ask for help and talk about how you're feeling. Consider reaching out to a counselor, a teacher, or someone you trust. You are important, and support is always available.''';
        notificationType = 'Support Suggestion';
        break;

      case InterventionLevel.none:
        return;
    }

    // Create the intervention notification
    await supabase.from('user_notifications').insert({
      'user_id': userId,
      'notification_type': notificationType,
      'content': notificationContent,
      'is_read': false,
      'action_url': '/student/counselors', // Link to counselor page
      // 'timestamp' will be set automatically
    });

    // Log the intervention for monitoring
    await supabase.from('intervention_logs').insert({
      'user_id': userId,
      'intervention_level': level.name,
      'trigger_message': triggerMessage,
      'triggered_at': DateTime.now().toIso8601String(),
    });
  }

  /// Checks if user has already received an intervention recently
  static Future<bool> hasRecentIntervention() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await supabase
          .from('user_notifications')
          .select('timestamp')
          .eq('user_id', userId)
          .inFilter('notification_type',
              ['intervention_high_risk', 'intervention_moderate_risk'])
          .order('timestamp', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final lastNotificationTime = DateTime.parse(response[0]['timestamp']);
        final cooldownAgo = DateTime.now().subtract(interventionCooldown);
        return lastNotificationTime.isAfter(cooldownAgo);
      }

      return false;
    } catch (e) {
      print('Error checking recent interventions: $e');
      return false;
    }
  }
}

enum InterventionLevel {
  none,
  moderate,
  high,
}
