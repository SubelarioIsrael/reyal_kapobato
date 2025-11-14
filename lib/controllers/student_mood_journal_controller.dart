import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/activity_service.dart';
import '../services/api/sentiment_app.dart';
import '../services/intervention_service.dart';

class StudentMoodJournalController {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Validate title - no numbers or special characters (title is optional)
  String? validateTitle(String? value) {
    // Title is optional, so empty is allowed
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final trimmed = value.trim();
    
    // Check for numbers
    if (RegExp(r'\d').hasMatch(trimmed)) {
      return 'Title should not contain numbers';
    }

    // Check for special characters (allow only letters, spaces, apostrophes, hyphens, periods)
    if (RegExp(r"[^a-zA-Z\s'\-\.]").hasMatch(trimmed)) {
      return 'Title should not contain special characters';
    }

    return null;
  }

  /// Validate content
  String? validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Speak your mind';
    }
    return null;
  }

  /// Submit journal entry
  Future<SubmitJournalResult> submitJournal({
    required String title,
    required String content,
    required bool isSharedWithCounselor,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return SubmitJournalResult(
          success: false,
          errorMessage: 'Not logged in',
        );
      }

      // Start activity recording in background (fire-and-forget)
      // ignore: unawaited_futures
      ActivityService.recordActivityCompletion('mood_journal');

      // Get sentiment analysis (with 10-second timeout and fallback)
      final sentimentResult = await analyzeSentiment(content.trim());

      // Insert journal entry
      final inserted = await _supabase
          .from('journal_entries')
          .insert({
            if (title.trim().isNotEmpty) 'title': title.trim(),
            'content': content.trim(),
            'sentiment': sentimentResult['sentiment'],
            'insight': sentimentResult['thought'],
            'entry_timestamp': DateTime.now().toIso8601String(),
            'is_shared_with_counselor': isSharedWithCounselor,
            'user_id': userId,
          })
          .select('journal_id')
          .single();

      final int journalId = inserted['journal_id'] as int;

      // Trigger intervention check
      final level = await InterventionService.triggerJournalIntervention(
        journalId: journalId,
        userId: userId,
        sentiment: (sentimentResult['sentiment'] ?? '').toString(),
        content: content.trim(),
        insight: (sentimentResult['thought'] ?? '').toString(),
      );

      // Fetch hotlines if high risk
      List<Map<String, dynamic>>? hotlines;
      if (level == InterventionLevel.high) {
        hotlines = await InterventionService.fetchHotlines(limit: 5);
      }

      return SubmitJournalResult(
        success: true,
        interventionLevel: level,
        hotlines: hotlines,
      );
    } catch (e) {
      print('Error submitting journal: $e');
      return SubmitJournalResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}

class SubmitJournalResult {
  final bool success;
  final String? errorMessage;
  final InterventionLevel? interventionLevel;
  final List<Map<String, dynamic>>? hotlines;

  SubmitJournalResult({
    required this.success,
    this.errorMessage,
    this.interventionLevel,
    this.hotlines,
  });
}
