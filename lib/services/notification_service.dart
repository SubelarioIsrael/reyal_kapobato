import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'activity_service.dart';

class NotificationService {
  static final supabase = Supabase.instance.client;

  /// Check if notifications are enabled for the current user
  static Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notifications_enabled') ?? true;
    } catch (e) {
      print('Error checking notification settings: $e');
      return true; // Default to enabled
    }
  }

  /// Send push notification via Supabase Edge Function (only if notifications are enabled)
  static Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if notifications are enabled
      if (!await areNotificationsEnabled()) {
        print('Push notifications are disabled, skipping notification');
        return;
      }

      await supabase.functions.invoke(
        'send-notification',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  static Future<void> createActivityCompletionNotification(
      String activityType) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Check if notifications are enabled
    if (!await areNotificationsEnabled()) {
      return;
    }

    // Get today's completions
    final completions = await ActivityService.getTodayCompletions();
    final completedCount =
        completions.values.where((completed) => completed).length;
    final totalActivities = completions.length;

    // Only create notification if all activities are completed
    if (completedCount == totalActivities) {
      // Create in-app notification
      await supabase.from('user_notifications').insert({
        'user_id': userId,
        'notification_type': 'all_activities_completed',
        'content':
            'Congratulations! You\'ve completed all your activities for today! 🎉',
        'is_read': false,
      });

      // Send push notification
      await sendPushNotification(
        userId: userId,
        title: 'Activities Completed!',
        body: 'You\'ve completed all your activities for today! 🎉',
        data: {'type': 'all_activities_completed'},
      );
    }
  }

  static Future<void> createAllActivitiesCompletedNotification() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Check if notifications are enabled
    if (!await areNotificationsEnabled()) {
      return;
    }

    // Create in-app notification
    await supabase.from('user_notifications').insert({
      'user_id': userId,
      'notification_type': 'all_activities_completed',
      'content':
          'Congratulations! You\'ve completed all your activities for today! 🎉',
      'is_read': false,
    });

    // Send push notification
    await sendPushNotification(
      userId: userId,
      title: 'All Activities Complete!',
      body: 'Congratulations! You\'ve completed all your activities for today! 🎉',
      data: {'type': 'all_activities_completed'},
    );
  }
}
