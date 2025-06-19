import 'package:supabase_flutter/supabase_flutter.dart';
import 'activity_service.dart';

class NotificationService {
  static final supabase = Supabase.instance.client;

  static Future<void> createActivityCompletionNotification(
      String activityType) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Get today's completions
    final completions = await ActivityService.getTodayCompletions();
    final completedCount =
        completions.values.where((completed) => completed).length;
    final totalActivities = completions.length;

    // Only create notification if all activities are completed
    if (completedCount == totalActivities) {
      await supabase.from('user_notifications').insert({
        'user_id': userId,
        'notification_type': 'all_activities_completed',
        'content':
            'Congratulations! You\'ve completed all your activities for today! 🎉',
        'is_read': false,
      });
    }
  }

  static Future<void> createAllActivitiesCompletedNotification() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('user_notifications').insert({
      'user_id': userId,
      'notification_type': 'all_activities_completed',
      'content':
          'Congratulations! You\'ve completed all your activities for today! 🎉',
      'is_read': false,
    });
  }
}
