import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/department_mapping.dart';

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

    // Try to insert into alerts table; risk_level is a DB enum so we
    // catch any type mismatch and still fall through to risk_alerts.
    try {
      await supabase.from('alerts').insert({
        'user_id': userId,
        'journal_id': journalId,
        'risk_level': level.name,
        'sentiment': sentiment.toLowerCase(),
        'matched_terms': matches,
      });
    } catch (e) {
      print('alerts insert skipped (enum mismatch?): $e');
    }

    // Persist a risk_alert row (plain text — always type-safe)
    await _writeRiskAlert(
      userId,
      'Journal entry flagged — ${matches.isEmpty ? sentiment : matches.join(', ')}',
    );

    // Student notification
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

    // Notify the student's assigned counselor(s)
    await _notifyCounselor(
      userId,
      'Journal entry — matched terms: ${matches.isEmpty ? sentiment : matches.join(', ')}',
      level,
    );

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
      'action_url': '/student/counselors',
    });

    // Log the intervention for monitoring
    await supabase.from('intervention_logs').insert({
      'user_id': userId,
      'intervention_level': level.name,
      'trigger_message': triggerMessage,
      'triggered_at': DateTime.now().toIso8601String(),
    });

    // Persist a risk_alert row so counselors can track it in the dashboard
    await _writeRiskAlert(userId, triggerMessage);

    // Notify the student's assigned counselor(s)
    await _notifyCounselor(userId, triggerMessage, level);
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

  // ─── New risk-detection helpers ──────────────────────────────────────────

  /// Inserts a row into [risk_alerts] (plain-text trigger_reason — no enum).
  static Future<void> _writeRiskAlert(String userId, String reason) async {
    try {
      await supabase.from('risk_alerts').insert({
        'user_id': userId,
        'trigger_reason': reason,
        'is_notified': false,
        'is_acknowledged': false,
        'is_resolved': false,
      });
    } catch (e) {
      print('Error writing risk_alert: $e');
    }
  }

  /// Routes a counselor notification using a 3-tier priority:
  ///
  /// Tier 1 — Student has a past/current appointment:
  ///   → Notify only that specific counselor.
  ///
  /// Tier 2 — No appointment yet, but student has a known department:
  ///   → Notify all counselors whose [department_assigned] matches the
  ///     student's department (derived via [DepartmentMapping]).
  ///
  /// Tier 3 — No appointment AND department cannot be resolved:
  ///   → Notify ALL counselors (last-resort broadcast).
  static Future<void> _notifyCounselor(
    String userId,
    String triggerReason,
    InterventionLevel level,
  ) async {
    try {
      // ── Fetch student profile (name + education info) ──────────────────
      final student = await supabase
          .from('students')
          .select('first_name, last_name, education_level, course, strand')
          .eq('user_id', userId)
          .maybeSingle();

      final studentName = student != null
          ? '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim()
          : 'A student';

      // ── Tier 1: appointment-based counselor ────────────────────────────
      List<String> counselorUserIds = [];

      final appointments = await supabase
          .from('counseling_appointments')
          .select('counselors(user_id)')
          .eq('user_id', userId)
          .order('appointment_date', ascending: false)
          .limit(1);

      if (appointments.isNotEmpty) {
        final c = appointments.first['counselors'] as Map<String, dynamic>?;
        if (c?['user_id'] != null) {
          counselorUserIds.add(c!['user_id'] as String);
        }
      }

      // ── Tier 2: department-matched counselors ──────────────────────────
      if (counselorUserIds.isEmpty && student != null) {
        final dept = DepartmentMapping.getStudentDepartment(
          educationLevel: student['education_level'] as String?,
          course: student['course'] as String?,
          strand: student['strand'] as String?,
        );

        if (dept != null) {
          final deptCounselors = await supabase
              .from('counselors')
              .select('user_id')
              .eq('department_assigned', dept);

          counselorUserIds =
              deptCounselors.map<String>((c) => c['user_id'] as String).toList();
        }
      }

      // ── Tier 3: broadcast to all counselors ────────────────────────────
      if (counselorUserIds.isEmpty) {
        final all = await supabase.from('counselors').select('user_id');
        counselorUserIds =
            all.map<String>((c) => c['user_id'] as String).toList();
      }

      if (counselorUserIds.isEmpty) return;

      // ── Build notification content ─────────────────────────────────────
      final notifType = level == InterventionLevel.high
          ? '⚠️ Student At Risk — Immediate Attention'
          : 'Student May Need Support';
      final content = level == InterventionLevel.high
          ? '$studentName has triggered a HIGH-RISK alert. Trigger: $triggerReason. Immediate follow-up is recommended.'
          : '$studentName may need support. Trigger: $triggerReason. Please consider reaching out.';

      for (final counselorUserId in counselorUserIds) {
        await supabase.from('user_notifications').insert({
          'user_id': counselorUserId,
          'notification_type': notifType,
          'content': content,
          'is_read': false,
          'action_url': '/counselor/students',
        });
      }
    } catch (e) {
      print('Error notifying counselor: $e');
    }
  }

  /// Detects consecutive low-mood days.
  /// Returns [InterventionLevel.high] for 3+ days, [moderate] for 2 days.
  static Future<InterventionLevel> analyzeConsecutiveMoods(
      String userId) async {
    try {
      final entries = await supabase
          .from('mood_entries')
          .select('mood_type, entry_date')
          .eq('user_id', userId)
          .order('entry_date', ascending: false)
          .limit(7);

      if (entries.length < 2) return InterventionLevel.none;

      const lowMoods = ['angry', 'sad'];
      int consecutiveLow = 0;
      for (final entry in entries) {
        final moodType = (entry['mood_type'] as String).toLowerCase();
        if (lowMoods.contains(moodType)) {
          consecutiveLow++;
          if (consecutiveLow >= 3) return InterventionLevel.high;
        } else {
          break;
        }
      }
      return consecutiveLow >= 2
          ? InterventionLevel.moderate
          : InterventionLevel.none;
    } catch (e) {
      print('Error analyzing consecutive moods: $e');
      return InterventionLevel.none;
    }
  }

  /// Detects sudden disengagement: was active in days 8-14 but has had
  /// zero activity completions in the last 7 days.
  static Future<InterventionLevel> analyzeAppEngagement(
      String userId) async {
    try {
      final twoWeeksAgo =
          DateTime.now().subtract(const Duration(days: 14)).toIso8601String();
      final oneWeekAgo =
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

      final entries = await supabase
          .from('activity_completions')
          .select('completed_at')
          .eq('user_id', userId)
          .gte('completed_at', twoWeeksAgo)
          .order('completed_at', ascending: false);

      if (entries.isEmpty) return InterventionLevel.none;

      final hadActivityBefore = entries.any((e) {
        final d = DateTime.tryParse(e['completed_at'] ?? '');
        return d != null && d.isBefore(DateTime.parse(oneWeekAgo));
      });
      final hasRecentActivity = entries.any((e) {
        final d = DateTime.tryParse(e['completed_at'] ?? '');
        return d != null && d.isAfter(DateTime.parse(oneWeekAgo));
      });

      if (hadActivityBefore && !hasRecentActivity) {
        return InterventionLevel.moderate;
      }
      return InterventionLevel.none;
    } catch (e) {
      print('Error analyzing app engagement: $e');
      return InterventionLevel.none;
    }
  }
}

enum InterventionLevel {
  none,
  moderate,
  high,
}
