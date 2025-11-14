import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../services/activity_service.dart';

class StudentDailyCheckinController {
  // ValueNotifiers for reactive UI
  final currentStep = ValueNotifier<int>(0);
  final moodType = ValueNotifier<String?>(null);
  final emojiCode = ValueNotifier<String?>(null);
  final reasons = ValueNotifier<List<String>>([]);
  final noteController = TextEditingController();
  final otherReasonController = TextEditingController();
  final isSubmitting = ValueNotifier<bool>(false);
  final isComplete = ValueNotifier<bool>(false);
  final todayCheckIn = ValueNotifier<Map<String, dynamic>?>(null);

  // Mood and reason options
  final List<Map<String, String>> moodOptions = [
    {'type': 'angry', 'emoji': '😡'},
    {'type': 'sad', 'emoji': '😔'},
    {'type': 'neutral', 'emoji': '😐'},
    {'type': 'happy', 'emoji': '😃'},
    {'type': 'loved', 'emoji': '🥰'},
  ];

  final List<String> reasonOptions = [
    'Relationship',
    'School',
    'Friend',
    'Work',
    'Family',
    'Other'
  ];

  void init() {
    fetchTodayCheckIn();
  }

  String capitalizeString(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> fetchTodayCheckIn() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Convert to UTC+8 (Asia/Manila timezone)
      final now = DateTime.now().toUtc().add(const Duration(hours: 8));
      final todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final response = await Supabase.instance.client
          .from('mood_entries')
          .select()
          .eq('user_id', userId)
          .eq('entry_date', todayDate)
          .maybeSingle()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Fetching check-in timed out');
        },
      );

      todayCheckIn.value = response;
      isComplete.value = response != null;
    } catch (e) {
      print('Error fetching today\'s check-in: $e');
      isComplete.value = false;
    }
  }

  void selectMood(String type, String emoji) {
    moodType.value = type;
    emojiCode.value = emoji;
  }

  void toggleReason(String reason) {
    final currentReasons = List<String>.from(reasons.value);
    if (currentReasons.contains(reason)) {
      currentReasons.remove(reason);
      if (reason == 'Other') {
        otherReasonController.clear();
      }
    } else {
      currentReasons.add(reason);
    }
    reasons.value = currentReasons;
  }

  void nextStep() {
    if (currentStep.value < 1) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Map<String, dynamic> validateSubmission() {
    if (moodType.value == null) {
      return {
        'success': false,
        'message': 'Please select your mood',
      };
    }

    if (reasons.value.isEmpty) {
      return {
        'success': false,
        'message': 'Please select at least one reason',
      };
    }

    if (reasons.value.contains('Other') && otherReasonController.text.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Please specify your other reason',
      };
    }

    return {'success': true};
  }

  Future<Map<String, dynamic>> submitCheckIn() async {
    final validation = validateSubmission();
    if (!validation['success']) {
      return validation;
    }

    isSubmitting.value = true;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Replace "Other" with the actual text if present
      List<String> finalReasons = reasons.value.map((reason) {
        if (reason == 'Other' && otherReasonController.text.trim().isNotEmpty) {
          return otherReasonController.text.trim();
        }
        return reason;
      }).toList();

      // Get today's date in UTC+8 (Asia/Manila timezone)
      final now = DateTime.now().toUtc().add(const Duration(hours: 8));
      final todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await Supabase.instance.client.from('mood_entries').insert({
        'user_id': user.id,
        'mood_type': moodType.value,
        'emoji_code': emojiCode.value,
        'reasons': finalReasons,
        'notes': noteController.text,
        'entry_date': todayDate,
      });

      // Record activity completion
      await ActivityService.recordActivityCompletion('daily_checkin');

      // Refresh the check-in data
      await fetchTodayCheckIn();

      return {
        'success': true,
        'message': 'Check-in saved successfully!',
      };
    } catch (e) {
      print('Error saving check-in: $e');
      return {
        'success': false,
        'message': 'Error saving check-in. Please try again.',
      };
    } finally {
      isSubmitting.value = false;
    }
  }

  void dispose() {
    currentStep.dispose();
    moodType.dispose();
    emojiCode.dispose();
    reasons.dispose();
    noteController.dispose();
    otherReasonController.dispose();
    isSubmitting.dispose();
    isComplete.dispose();
    todayCheckIn.dispose();
  }
}
