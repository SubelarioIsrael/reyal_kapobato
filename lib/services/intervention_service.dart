import 'package:supabase_flutter/supabase_flutter.dart';
// import 'notification_service.dart';

class InterventionService {
  static final supabase = Supabase.instance.client;
  static Duration interventionCooldown =
      const Duration(hours: 6); // Easily modifiable cooldown

  // Keywords and phrases that might indicate concerning content
  static const List<String> _concerningKeywords = [
    'depression',
    'hopeless',
    'i feel hopeless',
    'worthless',
    'i feel worthless',
    'useless',
    'burden',
    'anxiety',
    'panic attack',
    'can\'t breathe',
    'stress',
    'overwhelmed',
    'can\'t cope',
    'breaking point',
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
    'no one cares'
  ];

  // High-risk phrases that require immediate attention
  static const List<String> _highRiskPhrases = [
    'suicide',
    'kill myself',
    'kill me',
    'want to die',
    'i don\'t want to live',
    'end it all',
    'self harm',
    'cut myself',
    'cutting',
    'hurt myself',
    'hang myself',
    'jump off',
    'abuse',
    'domestic violence',
    'sexual assault'
  ];

  /// Find keyword and phrase matches in a text
  static List<String> _findMatches(String textLower) {
    final List<String> matches = [];
    for (final phrase in _highRiskPhrases) {
      if (textLower.contains(phrase)) matches.add(phrase);
    }
    for (final keyword in _concerningKeywords) {
      if (textLower.contains(keyword)) matches.add(keyword);
    }
    return matches.toSet().toList();
  }

  /// Determine journal intervention level from sentiment + text
  static InterventionLevel analyzeJournal(String sentiment, String text,
      {String? insight}) {
    if (sentiment.toLowerCase().trim() != 'negative') {
      return InterventionLevel.none;
    }

    final lower = (text + ' ' + (insight ?? '')).toLowerCase();
    // High risk if any high-risk phrase present
    for (final phrase in _highRiskPhrases) {
      if (lower.contains(phrase)) return InterventionLevel.high;
    }

    // Moderate if any concerning keyword found
    for (final keyword in _concerningKeywords) {
      if (lower.contains(keyword)) return InterventionLevel.moderate;
    }

    // Otherwise negative sentiment without keywords → low
    return InterventionLevel.moderate; // prefer surfacing negative entries
  }

  /// Throttle alerts by risk level
  static Future<bool> _isThrottled(
      String userId, InterventionLevel level) async {
    final Duration window = switch (level) {
      InterventionLevel.high => const Duration(hours: 2),
      InterventionLevel.moderate => const Duration(minutes: 30),
      InterventionLevel.none => const Duration(seconds: 0),
    };
    if (level == InterventionLevel.none) return true;

    final cutoff = DateTime.now().subtract(window).toIso8601String();
    final resp = await supabase
        .from('alerts')
        .select('created_at')
        .eq('user_id', userId)
        .gte('created_at', cutoff)
        .order('created_at', ascending: false)
        .limit(1);
    return resp.isNotEmpty;
  }

  /// Create alert + notifications for a journal entry
  static Future<InterventionLevel> triggerJournalIntervention({
    required int journalId,
    required String userId,
    required String sentiment,
    required String content,
    String? insight,
  }) async {
    final level = analyzeJournal(sentiment, content, insight: insight);
    if (level == InterventionLevel.none) return level;

    if (await _isThrottled(userId, level)) return level;

    final textLower = (content + ' ' + (insight ?? '')).toLowerCase();
    final matches = _findMatches(textLower);

    // TODO: Fix alerts table enum values - temporarily disabled to prevent error
    // The alerts table's risk_level enum doesn't accept "moderate"
    // We need to determine the correct enum values for this table
    
    // Temporarily comment out alerts insertion to prevent error
    /*
    await supabase.from('alerts').insert({
      'user_id': userId,
      'journal_id': journalId,
      'risk_level': level.name,  
      'sentiment': sentiment.toLowerCase(),
      'matched_terms': matches,
    });
    */
    
    // For now, just log that we would have created an alert
    print('Would create alert for user $userId with risk level: ${level.name}, matches: $matches');

    // Student notification content
    final String studentTitle = level == InterventionLevel.high
        ? 'We are here for you'
        : 'You are not alone';
    final String studentContent = level == InterventionLevel.high
        ? 'If things feel overwhelming, consider reaching out now. Hotlines and your counselor are available.'
        : 'It helps to talk. Would you like to reach out to your counselor or try a grounding exercise?';

    await supabase.from('user_notifications').insert({
      'user_id': userId,
      'notification_type': studentTitle,
      'content': studentContent,
      'is_read': false,
      'action_url': '/student/counselors',
    });

    return level;
  }

  /// Fetch mental health hotlines (can filter by region later)
  static Future<List<Map<String, dynamic>>> fetchHotlines(
      {int limit = 5}) async {
    final rows = await supabase
        .from('mental_health_hotlines')
        .select('name, phone, city_or_region, notes, profile_picture')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

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

      if (response.isEmpty) {
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
