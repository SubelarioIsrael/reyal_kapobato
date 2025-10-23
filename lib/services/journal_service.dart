import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journal_entry.dart';

class JournalService {
  static final _supabase = Supabase.instance.client;

  static Future<List<JournalEntry>> getJournalEntries(String userId) async {
    try {
      final response = await _supabase
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_timestamp', ascending: false);

      return (response as List)
          .map((entry) => JournalEntry.fromMap(entry))
          .toList();
    } catch (e) {
      print('Error fetching journal entries: $e');
      throw Exception('Failed to fetch journal entries');
    }
  }

  static Future<JournalEntry?> getJournalEntry(int journalId) async {
    try {
      final response = await _supabase
          .from('journal_entries')
          .select()
          .eq('journal_id', journalId)
          .single();

      return JournalEntry.fromMap(response);
    } catch (e) {
      print('Error fetching journal entry: $e');
      return null;
    }
  }

  static Future<bool> updateJournalEntry(JournalEntry entry) async {
    try {
      await _supabase.from('journal_entries').update({
        if (entry.title != null) 'title': entry.title,
        'content': entry.content,
        if (entry.sentiment != null) 'sentiment': entry.sentiment,
        if (entry.insight != null) 'insight': entry.insight,
        'is_shared_with_counselor': entry.isSharedWithCounselor,
      }).eq('journal_id', entry.journalId);

      return true;
    } catch (e) {
      print('Error updating journal entry: $e');
      return false;
    }
  }

  static Future<bool> deleteJournalEntry(int journalId) async {
    try {
      await _supabase
          .from('journal_entries')
          .delete()
          .eq('journal_id', journalId);

      return true;
    } catch (e) {
      print('Error deleting journal entry: $e');
      return false;
    }
  }

  static Future<bool> updateJournalSharingStatus(String journalId, bool isShared) async {
    try {
      final response = await Supabase.instance.client
          .from('mood_journal_entries')
          .update({'is_shared_with_counselor': isShared})
          .eq('journal_id', journalId);

      return true;
    } catch (e) {
      print('Error updating journal sharing status: $e');
      return false;
    }
  }

  static Future<List<JournalEntry>> searchJournalEntries(
      String userId, String query) async {
    try {
      final response = await _supabase
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,content.ilike.%$query%,insight.ilike.%$query%')
          .order('entry_timestamp', ascending: false);

      return (response as List)
          .map((entry) => JournalEntry.fromMap(entry))
          .toList();
    } catch (e) {
      print('Error searching journal entries: $e');
      throw Exception('Failed to search journal entries');
    }
  }

  static Future<Map<String, int>> getJournalStats(String userId) async {
    try {
      final response = await _supabase
          .from('journal_entries')
          .select('sentiment, is_shared_with_counselor')
          .eq('user_id', userId);

      int totalEntries = response.length;
      int sharedEntries = response
          .where((entry) => entry['is_shared_with_counselor'] == true)
          .length;

      int positiveEntries = response
          .where((entry) =>
              (entry['sentiment'] as String?)?.toLowerCase() == 'positive')
          .length;

      return {
        'total': totalEntries,
        'shared': sharedEntries,
        'positive': positiveEntries,
      };
    } catch (e) {
      print('Error fetching journal stats: $e');
      return {'total': 0, 'shared': 0, 'positive': 0};
    }
  }
}
