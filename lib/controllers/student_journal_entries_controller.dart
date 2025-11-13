import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';

class StudentJournalEntriesController {
  // ValueNotifiers for reactive UI
  final journalEntries = ValueNotifier<List<JournalEntry>>([]);
  final filteredEntries = ValueNotifier<List<JournalEntry>>([]);
  final isLoading = ValueNotifier<bool>(true);
  final searchQuery = ValueNotifier<String>('');
  final selectedFilter = ValueNotifier<String>('all');

  void init() {
    loadJournalEntries();
  }

  Future<Map<String, dynamic>> loadJournalEntries() async {
    isLoading.value = true;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        isLoading.value = false;
        return {
          'success': false,
          'message': 'Not logged in',
        };
      }

      final entries = await JournalService.getJournalEntries(userId);

      journalEntries.value = entries;
      filteredEntries.value = entries;
      isLoading.value = false;

      return {
        'success': true,
      };
    } catch (e) {
      print('Error loading journal entries: $e');
      isLoading.value = false;
      return {
        'success': false,
        'message': 'Failed to load journal entries',
      };
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    filterEntries();
  }

  void updateFilter(String filter) {
    selectedFilter.value = filter;
    filterEntries();
  }

  void filterEntries() {
    final query = searchQuery.value.toLowerCase();
    final filter = selectedFilter.value;

    filteredEntries.value = journalEntries.value.where((entry) {
      // Search filter
      bool matchesSearch = query.isEmpty ||
          (entry.title?.toLowerCase().contains(query) ?? false) ||
          entry.content.toLowerCase().contains(query);

      // Category filter
      bool matchesFilter = true;
      switch (filter) {
        case 'shared':
          matchesFilter = entry.isSharedWithCounselor;
          break;
        case 'positive':
          matchesFilter = entry.sentiment?.toLowerCase() == 'positive';
          break;
        case 'negative':
          matchesFilter = entry.sentiment?.toLowerCase() == 'negative';
          break;
        case 'neutral':
          matchesFilter = entry.sentiment?.toLowerCase() == 'neutral';
          break;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<Map<String, dynamic>> deleteEntry(JournalEntry entry) async {
    try {
      final success = await JournalService.deleteJournalEntry(entry.journalId);
      
      if (success) {
        await loadJournalEntries();
        return {
          'success': true,
          'message': 'Entry deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete entry',
        };
      }
    } catch (e) {
      print('Error deleting entry: $e');
      return {
        'success': false,
        'message': 'Failed to delete entry',
      };
    }
  }

  Future<Map<String, dynamic>> updateSharingStatus(JournalEntry entry, bool newValue) async {
    try {
      final success = await JournalService.updateJournalSharingStatus(
        entry.journalId.toString(),
        newValue,
      );
      
      if (success) {
        await loadJournalEntries();
        return {
          'success': true,
          'message': newValue 
              ? 'Entry is now shared with counselor' 
              : 'Entry is now private',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update sharing status',
        };
      }
    } catch (e) {
      print('Error updating sharing status: $e');
      return {
        'success': false,
        'message': 'Failed to update sharing status',
      };
    }
  }

  void dispose() {
    journalEntries.dispose();
    filteredEntries.dispose();
    isLoading.dispose();
    searchQuery.dispose();
    selectedFilter.dispose();
  }
}
