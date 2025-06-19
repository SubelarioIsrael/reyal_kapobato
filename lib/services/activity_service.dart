import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';

class ActivityService {
  // Map of activity names to their IDs
  static const Map<String, int> activityIds = {
    'daily_checkin': 1,
    'mood_journal': 2,
    'track_mood': 3,
    'breathing_exercise': 4,
  };

  static final supabase = Supabase.instance.client;

  static Future<void> recordActivityCompletion(String activityName) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get activity ID from the map
      final activityId = activityIds[activityName];
      if (activityId == null) {
        throw Exception('Invalid activity name: $activityName');
      }

      // Check if activity already completed today
      final today = DateTime.now().toIso8601String().split('T')[0];
      final existingCompletions = await Supabase.instance.client
          .from('activity_completions')
          .select()
          .eq('user_id', user.id)
          .eq('activity_id', activityId)
          .gte('completed_at', today)
          .lte('completed_at', '${today}T23:59:59.999Z');

      if (existingCompletions.isNotEmpty) {
        print('Activity already completed today');
        return;
      }

      // Record new completion
      await Supabase.instance.client.from('activity_completions').insert({
        'user_id': user.id,
        'activity_id': activityId,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Send notification
      await NotificationService.createActivityCompletionNotification(
          activityName);
    } catch (e) {
      print('Error recording activity completion: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getActivityProgress() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get today's date in ISO format
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Get today's completions
      final completions = await Supabase.instance.client
          .from('activity_completions')
          .select()
          .eq('user_id', user.id)
          .gte('completed_at', today)
          .lte('completed_at', '${today}T23:59:59.999Z');

      // Calculate progress
      final totalActivities = activityIds.length;
      final completedActivities = completions.length;
      final progress =
          totalActivities > 0 ? completedActivities / totalActivities : 0.0;

      return {
        'total': totalActivities,
        'completed': completedActivities,
        'progress': progress,
        'completions': completions,
      };
    } catch (e) {
      print('Error getting activity progress: $e');
      return {
        'total': 0,
        'completed': 0,
        'progress': 0.0,
        'completions': [],
      };
    }
  }

  static Future<Map<String, bool>> getTodayCompletions() async {
    try {
      final now = DateTime.now().toUtc();
      final todayStart =
          DateTime(now.year, now.month, now.day).toIso8601String();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
          .toIso8601String();

      print(
          'Fetching completions for date range: $todayStart to $todayEnd'); // Debug log

      final response = await supabase
          .from('activity_completions')
          .select('activity_id')
          .gte('completed_at', todayStart)
          .lte('completed_at', todayEnd);

      print('Response from Supabase: $response'); // Debug log

      final completions = {
        'track_mood': false,
        'mood_journal': false,
        'daily_checkin': false,
        'breathing_exercise': false,
      };

      // Create reverse mapping of activity IDs to names
      final reverseMap = activityIds.map((key, value) => MapEntry(value, key));

      for (var record in response) {
        final activityId = record['activity_id'] as int;
        final activityName = reverseMap[activityId];
        if (activityName != null) {
          completions[activityName] = true;
        }
      }

      print('Processed completions: $completions'); // Debug log
      return completions;
    } catch (e) {
      print('Error getting today\'s completions: $e');
      // Return default completions map on error
      return {
        'track_mood': false,
        'mood_journal': false,
        'daily_checkin': false,
        'breathing_exercise': false,
      };
    }
  }

  static Future<double> getTodayProgress() async {
    final completions = await getTodayCompletions();
    final completedCount =
        completions.values.where((completed) => completed).length;
    return completedCount / completions.length;
  }
}
