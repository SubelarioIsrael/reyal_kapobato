import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';
import '../services/activity_service.dart';
import '../services/chat_message_service.dart';

class StudentHomeController {
  final ValueNotifier<String?> studentName = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<Map<String, dynamic>?> todayCheckIn = ValueNotifier(null);
  final ValueNotifier<bool> isCheckInLoading = ValueNotifier(true);

  final ValueNotifier<List<Map<String, dynamic>>> weeklyMood = ValueNotifier([]);
  final ValueNotifier<bool> isWeeklyMoodLoading = ValueNotifier(true);

  final ValueNotifier<double> todayProgress = ValueNotifier(0.0);
  final ValueNotifier<Map<String, bool>> todayCompletions = ValueNotifier({
    'mood_journal': false,
    'daily_checkin': false,
    'breathing_exercise': false,
  });
  final ValueNotifier<bool> isProgressLoading = ValueNotifier(true);

  final ValueNotifier<int> unreadMessagesCount = ValueNotifier(0);

  final ValueNotifier<Map<String, dynamic>?> dailyUplift = ValueNotifier(null);
  final ValueNotifier<bool> isDailyUpliftLoading = ValueNotifier(true);

  StreamSubscription? _studentNameSubscription;

  void init() {
    loadStudentName();
    listenToStudentNameChanges();
    fetchTodayCheckIn();
    fetchWeeklyMood();
    loadTodayProgress();
    loadUnreadMessagesCount();
    loadDailyUplift();
  }

  void dispose() {
    _studentNameSubscription?.cancel();
  }

  void listenToStudentNameChanges() {
    _studentNameSubscription = UserService.studentNameStream.listen((newName) {
      studentName.value = newName;
      isLoading.value = false;
    });
  }

  Future<void> loadStudentName() async {
    try {
      final name = await UserService.getStudentName();
      studentName.value = name;
      isLoading.value = false;
    } catch (e) {
      print('Error loading student name: $e');
      isLoading.value = false;
    }
  }

  Future<void> fetchTodayCheckIn() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final today = DateTime.now();
      final response = await Supabase.instance.client
          .from('mood_entries')
          .select()
          .eq('user_id', userId)
          .eq(
            'entry_date',
            "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}",
          )
          .maybeSingle();
      todayCheckIn.value = response;
      isCheckInLoading.value = false;
    } catch (e) {
      print('Error fetching today check-in: $e');
      isCheckInLoading.value = false;
    }
  }

  Future<void> fetchWeeklyMood() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final today = DateTime.now();
      final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final response = await Supabase.instance.client
          .from('mood_entries')
          .select()
          .eq('user_id', userId)
          .gte('entry_date', startOfWeek.toIso8601String().substring(0, 10))
          .lte('entry_date', endOfWeek.toIso8601String().substring(0, 10));
      weeklyMood.value = List<Map<String, dynamic>>.from(response);
      isWeeklyMoodLoading.value = false;
    } catch (e) {
      print('Error fetching weekly mood: $e');
      isWeeklyMoodLoading.value = false;
    }
  }

  List<Map<String, dynamic>> getWeekDaysWithMood() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    return List.generate(7, (i) {
      final date = startOfWeek.add(Duration(days: i));
      final entry = weeklyMood.value.firstWhere(
        (e) =>
            DateTime.parse(e['entry_date']).year == date.year &&
            DateTime.parse(e['entry_date']).month == date.month &&
            DateTime.parse(e['entry_date']).day == date.day,
        orElse: () => {},
      );
      return {
        'date': date,
        'isToday': date.day == today.day &&
            date.month == today.month &&
            date.year == today.year,
        'checkedIn': entry.isNotEmpty,
        'emoji': entry['emoji_code'],
      };
    });
  }

  Future<void> loadTodayProgress() async {
    try {
      isProgressLoading.value = true;
      todayCompletions.value = await ActivityService.getTodayCompletions();
      todayProgress.value = await ActivityService.getTodayProgress();
      isProgressLoading.value = false;
    } catch (e) {
      print('Error loading today progress: $e');
      isProgressLoading.value = false;
    }
  }

  Future<void> loadUnreadMessagesCount() async {
    try {
      unreadMessagesCount.value =
          await ChatMessageService.getUnreadMessagesFromCounselors();
    } catch (e) {
      print('Error loading unread messages count: $e');
    }
  }

  Future<void> loadDailyUplift() async {
    isDailyUpliftLoading.value = true;
    try {
      final idsResponse = await Supabase.instance.client
          .from('uplifts')
          .select('uplift_id')
          .order('uplift_id', ascending: true);
      if (idsResponse.isEmpty) {
        dailyUplift.value = null;
        isDailyUpliftLoading.value = false;
        return;
      }
      final availableIds =
          idsResponse.map((i) => i['uplift_id'] as int).toList();
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % availableIds.length;
      final selectedId = availableIds[randomIndex];
      final response = await Supabase.instance.client
          .from('uplifts')
          .select('*')
          .eq('uplift_id', selectedId)
          .single();
      dailyUplift.value = response;
      isDailyUpliftLoading.value = false;
    } catch (e) {
      print('Error loading daily uplift: $e');
      dailyUplift.value = null;
      isDailyUpliftLoading.value = false;
    }
  }

  Future<bool> checkEmergencyContacts() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await Supabase.instance.client
          .from('emergency_contacts')
          .select('contact_id')
          .eq('user_id', userId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking emergency contacts: $e');
      return false;
    }
  }
}
