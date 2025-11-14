import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class StudentCheckinHistoryController {
  // ValueNotifiers for reactive UI
  final checkInHistory = ValueNotifier<List<Map<String, dynamic>>>([]);
  final isLoading = ValueNotifier<bool>(true);
  final errorMessage = ValueNotifier<String?>(null);

  void init() {
    fetchCheckInHistory();
  }

  String capitalizeString(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<Map<String, dynamic>> fetchCheckInHistory() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        isLoading.value = false;
        errorMessage.value = 'User not logged in';
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      final response = await Supabase.instance.client
          .from('mood_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: false)
          .limit(30); // Get last 30 entries

      checkInHistory.value = List<Map<String, dynamic>>.from(response);
      isLoading.value = false;

      return {
        'success': true,
      };
    } catch (e) {
      print('Error fetching check-in history: $e');
      isLoading.value = false;
      errorMessage.value = 'Failed to load check-in history';
      return {
        'success': false,
        'message': 'Failed to load check-in history',
      };
    }
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final entryDate = DateTime(date.year, date.month, date.day);

      if (entryDate == today) {
        return 'Today';
      } else if (entryDate == yesterday) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  void dispose() {
    checkInHistory.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}
