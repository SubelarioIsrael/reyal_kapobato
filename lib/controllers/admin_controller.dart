import 'package:supabase_flutter/supabase_flutter.dart';

/// Result class for dashboard statistics
class DashboardStatsResult {
  final bool success;
  final int totalUsers;
  final int activeUsers;
  final int completedAppointments;
  final String? errorMessage;

  DashboardStatsResult({
    required this.success,
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.completedAppointments = 0,
    this.errorMessage,
  });
}

/// Result class for recent activities
class RecentActivitiesResult {
  final bool success;
  final List<Map<String, dynamic>> activities;
  final String? errorMessage;

  RecentActivitiesResult({
    required this.success,
    this.activities = const [],
    this.errorMessage,
  });
}

/// Admin Controller - Handles all admin-related backend operations
class AdminController {
  final _supabase = Supabase.instance.client;

  /// Sign out the current admin user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get dashboard statistics (total users, active users, completed appointments)
  Future<DashboardStatsResult> getDashboardStats() async {
    try {
      // Execute all queries in parallel using Future.wait
      final results = await Future.wait([
        _supabase.from('users').select('user_id'),
        _supabase.from('users').select('user_id').eq('status', 'active'),
        _supabase.from('counseling_appointments').select('appointment_id').eq('status', 'completed'),
      ]);

      final totalUsersCount = results[0].length;
      final activeUsersCount = results[1].length;
      final completedAppointmentsCount = results[2].length;

      return DashboardStatsResult(
        success: true,
        totalUsers: totalUsersCount,
        activeUsers: activeUsersCount,
        completedAppointments: completedAppointmentsCount,
      );
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return DashboardStatsResult(
        success: false,
        errorMessage: 'Failed to load dashboard statistics: ${e.toString()}',
      );
    }
  }

  /// Fetch comprehensive recent activities from various sources
  Future<RecentActivitiesResult> fetchRecentActivities() async {
    try {
      final List<Map<String, dynamic>> allActivities = [];

      // Execute all queries in parallel
      final results = await Future.wait([
        // 1. New user registrations
        _supabase
            .from('users')
            .select('user_id, email, registration_date, user_type')
            .order('registration_date', ascending: false)
            .limit(10),
        
        // 2. Appointments with JOINs through users table to get student and counselor names
        _supabase
            .from('counseling_appointments')
            .select('''
              appointment_id,
              appointment_date,
              status,
              status_message,
              notes,
              user_id,
              counselor_id,
              users!counseling_appointments_user_id_fkey!inner(
                students!inner(first_name, last_name)
              ),
              counselors!inner(first_name, last_name)
            ''')
            .order('appointment_date', ascending: false)
            .limit(50),
        
        // 3. New counselor accounts
        _supabase
            .from('users')
            .select('user_id, email, registration_date')
            .eq('user_type', 'counselor')
            .order('registration_date', ascending: false)
            .limit(10),
      ]);

      final registrations = results[0] as List<dynamic>;
      final appointments = results[1] as List<dynamic>;
      final newCounselors = results[2] as List<dynamic>;

      // Process registrations
      for (var reg in registrations) {
        allActivities.add({
          'type': 'registration',
          'icon': 'person_add',
          'color': 'purple',
          'title': 'New ${reg['user_type']} registered',
          'subtitle': reg['email'],
          'timestamp': DateTime.parse(reg['registration_date']),
        });
      }

      // Process appointments by status
      for (var apt in appointments) {
        try {
          final status = apt['status'];
          
          // Extract student info from nested users.students relationship
          final usersData = apt['users'];
          final studentInfo = usersData != null && usersData is Map && usersData['students'] is List && (usersData['students'] as List).isNotEmpty
              ? (usersData['students'] as List)[0]
              : null;
          
          final counselorInfo = apt['counselors'];
          
          if (studentInfo == null || counselorInfo == null) continue;
          
          final studentName = '${studentInfo['first_name']} ${studentInfo['last_name']}';
          final counselorName = '${counselorInfo['first_name']} ${counselorInfo['last_name']}';
          final timestamp = DateTime.parse(apt['appointment_date']);

          switch (status) {
            case 'pending':
              allActivities.add({
                'type': 'pending',
                'icon': 'pending_actions',
                'color': 'orange',
                'title': 'Pending approval',
                'subtitle': '$studentName with $counselorName',
                'timestamp': timestamp,
              });
              break;

            case 'booked':
            case 'confirmed':
              allActivities.add({
                'type': 'appointment_booked',
                'icon': 'event',
                'color': 'green',
                'title': 'New appointment booked',
                'subtitle': '$studentName with $counselorName',
                'timestamp': timestamp,
              });
              break;

            case 'cancelled':
              final reason = apt['status_message'] ?? apt['notes'] ?? 'No reason provided';
              final cancelledBy = (apt['status_message'] != null && 
                                   apt['status_message'].toString().toLowerCase().contains('counselor'))
                  ? 'counselor'
                  : 'student';
              
              allActivities.add({
                'type': cancelledBy == 'counselor' ? 'counselor_cancelled' : 'cancelled',
                'icon': 'cancel_outlined',
                'color': cancelledBy == 'counselor' ? 'orange_dark' : 'red',
                'title': cancelledBy == 'counselor' 
                    ? 'Session cancelled by counselor'
                    : 'Session cancelled by student',
                'subtitle': cancelledBy == 'counselor'
                    ? '$counselorName cancelled session with $studentName'
                    : '$studentName cancelled session with $counselorName',
                'detail': 'Reason: $reason',
                'timestamp': timestamp,
              });
              break;

            case 'rejected':
              final reason = apt['status_message'] ?? apt['notes'] ?? 'No reason provided';
              allActivities.add({
                'type': 'rejected',
                'icon': 'block',
                'color': 'deep_orange',
                'title': 'Session rejected by counselor',
                'subtitle': '$counselorName rejected $studentName',
                'detail': 'Reason: $reason',
                'timestamp': timestamp,
              });
              break;

            case 'completed':
              allActivities.add({
                'type': 'completed',
                'icon': 'check_circle',
                'color': 'teal',
                'title': 'Session completed',
                'subtitle': '$counselorName completed session with $studentName',
                'timestamp': timestamp,
              });
              break;
          }
        } catch (e) {
          print('Error processing appointment ${apt['appointment_id']}: $e');
          continue;
        }
      }

      // Process new counselors
      for (var counselor in newCounselors) {
        allActivities.add({
          'type': 'counselor_added',
          'icon': 'supervised_user_circle',
          'color': 'deep_purple',
          'title': 'New counselor account',
          'subtitle': counselor['email'],
          'timestamp': DateTime.parse(counselor['registration_date']),
        });
      }

      // Sort all activities by timestamp (most recent first)
      allActivities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      // Return top 15 most recent activities
      return RecentActivitiesResult(
        success: true,
        activities: allActivities.take(15).toList(),
      );
    } catch (e) {
      print('Error fetching recent activities: $e');
      return RecentActivitiesResult(
        success: false,
        errorMessage: 'Failed to load recent activities: ${e.toString()}',
      );
    }
  }

  /// Generate analytics data for PDF report
  Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      // Execute all queries in parallel
      final results = await Future.wait([
        _supabase.from('users').select('user_id'),
        _supabase.from('users').select('user_id').eq('status', 'active'),
        _supabase.from('counseling_appointments').select('appointment_id').eq('status', 'completed'),
        _supabase
            .from('users')
            .select('user_id, email, registration_date')
            .gte('registration_date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
            .order('registration_date', ascending: false)
            .limit(10),
      ]);

      return {
        'totalUsers': results[0].length,
        'activeUsers': results[1].length,
        'completedSessions': results[2].length,
        'recentRegistrations': results[3] as List<dynamic>,
      };
    } catch (e) {
      print('Error getting analytics data: $e');
      throw Exception('Failed to get analytics data: ${e.toString()}');
    }
  }
}
