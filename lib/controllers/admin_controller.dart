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
      // Get total users count
      final totalUsersResponse = await _supabase.from('users').select('user_id');
      final totalUsersCount = totalUsersResponse.length;

      // Get active users
      final activeUsersResponse = await _supabase
          .from('users')
          .select('user_id')
          .eq('status', 'active');
      final activeUsersCount = activeUsersResponse.length;

      // Get completed appointments count
      final completedAppointmentsResponse = await _supabase
          .from('counseling_appointments')
          .select('appointment_id')
          .eq('status', 'completed');
      final completedAppointmentsCount = completedAppointmentsResponse.length;

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

      // 1. New user registrations
      final registrations = await _supabase
          .from('users')
          .select('user_id, email, registration_date, user_type')
          .order('registration_date', ascending: false)
          .limit(10);

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

      // 2. New appointments booked (all statuses)
      final appointments = await _supabase
          .from('counseling_appointments')
          .select('''
            appointment_id,
            appointment_date,
            status,
            user_id,
            counselor_id
          ''')
          .order('appointment_date', ascending: false)
          .limit(50);

      for (var apt in appointments) {
        try {
          // Fetch student details
          final studentData = await _supabase
              .from('users')
              .select('user_id')
              .eq('user_id', apt['user_id'])
              .single();
          
          final studentInfo = await _supabase
              .from('students')
              .select('first_name, last_name')
              .eq('user_id', studentData['user_id'])
              .maybeSingle();
          
          // Fetch counselor details
          final counselorData = await _supabase
              .from('counselors')
              .select('first_name, last_name')
              .eq('counselor_id', apt['counselor_id'])
              .single();
          
          if (studentInfo != null) {
            final studentName = '${studentInfo['first_name']} ${studentInfo['last_name']}';
            final counselorName = '${counselorData['first_name']} ${counselorData['last_name']}';
            
            allActivities.add({
              'type': 'appointment_booked',
              'icon': 'event',
              'color': 'green',
              'title': 'New appointment booked',
              'subtitle': '$studentName with $counselorName',
              'timestamp': DateTime.parse(apt['appointment_date']),
            });
          }
        } catch (e) {
          print('Error processing appointment ${apt['appointment_id']}: $e');
          continue;
        }
      }

      // 3. Cancelled sessions
      final counselorCancelled = await _supabase
          .from('counseling_appointments')
          .select('''
            appointment_id,
            appointment_date,
            status_message,
            notes,
            user_id,
            counselor_id
          ''')
          .eq('status', 'cancelled')
          .order('appointment_date', ascending: false)
          .limit(10);

      for (var cancel in counselorCancelled) {
        try {
          // Fetch student details
          final studentInfo = await _supabase
              .from('students')
              .select('first_name, last_name')
              .eq('user_id', cancel['user_id'])
              .maybeSingle();
          
          // Fetch counselor details
          final counselorData = await _supabase
              .from('counselors')
              .select('first_name, last_name')
              .eq('counselor_id', cancel['counselor_id'])
              .single();
          
          if (studentInfo != null) {
            final studentName = '${studentInfo['first_name']} ${studentInfo['last_name']}';
            final counselorName = '${counselorData['first_name']} ${counselorData['last_name']}';
            final reason = cancel['status_message'] ?? cancel['notes'] ?? 'No reason provided';
            
            // Check if cancellation was by counselor
            final cancelledBy = (cancel['status_message'] != null && 
                                 cancel['status_message'].toString().toLowerCase().contains('counselor'))
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
              'timestamp': DateTime.parse(cancel['appointment_date']),
            });
          }
        } catch (e) {
          print('Error processing cancelled appointment ${cancel['appointment_id']}: $e');
          continue;
        }
      }

      // 4. Rejected sessions (by counselor)
      final rejected = await _supabase
          .from('counseling_appointments')
          .select('''
            appointment_id,
            appointment_date,
            status_message,
            notes,
            user_id,
            counselor_id
          ''')
          .eq('status', 'rejected')
          .order('appointment_date', ascending: false)
          .limit(10);

      for (var reject in rejected) {
        try {
          // Fetch student details
          final studentInfo = await _supabase
              .from('students')
              .select('first_name, last_name')
              .eq('user_id', reject['user_id'])
              .maybeSingle();
          
          // Fetch counselor details
          final counselorData = await _supabase
              .from('counselors')
              .select('first_name, last_name')
              .eq('counselor_id', reject['counselor_id'])
              .single();
          
          if (studentInfo != null) {
            final studentName = '${studentInfo['first_name']} ${studentInfo['last_name']}';
            final counselorName = '${counselorData['first_name']} ${counselorData['last_name']}';
            final reason = reject['status_message'] ?? reject['notes'] ?? 'No reason provided';
            
            allActivities.add({
              'type': 'rejected',
              'icon': 'block',
              'color': 'deep_orange',
              'title': 'Session rejected by counselor',
              'subtitle': '$counselorName rejected $studentName',
              'detail': 'Reason: $reason',
              'timestamp': DateTime.parse(reject['appointment_date']),
            });
          }
        } catch (e) {
          print('Error processing rejected appointment ${reject['appointment_id']}: $e');
          continue;
        }
      }

      // 5. Completed sessions
      final completed = await _supabase
          .from('counseling_appointments')
          .select('''
            appointment_id,
            appointment_date,
            user_id,
            counselor_id
          ''')
          .eq('status', 'completed')
          .order('appointment_date', ascending: false)
          .limit(10);

      for (var comp in completed) {
        try {
          // Fetch student details
          final studentInfo = await _supabase
              .from('students')
              .select('first_name, last_name')
              .eq('user_id', comp['user_id'])
              .maybeSingle();
          
          // Fetch counselor details
          final counselorData = await _supabase
              .from('counselors')
              .select('first_name, last_name')
              .eq('counselor_id', comp['counselor_id'])
              .single();
          
          if (studentInfo != null) {
            final studentName = '${studentInfo['first_name']} ${studentInfo['last_name']}';
            final counselorName = '${counselorData['first_name']} ${counselorData['last_name']}';
            
            allActivities.add({
              'type': 'completed',
              'icon': 'check_circle',
              'color': 'teal',
              'title': 'Session completed',
              'subtitle': '$counselorName completed session with $studentName',
              'timestamp': DateTime.parse(comp['appointment_date']),
            });
          }
        } catch (e) {
          print('Error processing completed appointment ${comp['appointment_id']}: $e');
          continue;
        }
      }

      // 6. Pending appointment approvals
      final pending = await _supabase
          .from('counseling_appointments')
          .select('''
            appointment_id,
            appointment_date,
            user_id,
            counselor_id
          ''')
          .eq('status', 'pending')
          .order('appointment_date', ascending: false)
          .limit(10);

      for (var pend in pending) {
        try {
          // Fetch student details
          final studentInfo = await _supabase
              .from('students')
              .select('first_name, last_name')
              .eq('user_id', pend['user_id'])
              .maybeSingle();
          
          // Fetch counselor details
          final counselorData = await _supabase
              .from('counselors')
              .select('first_name, last_name')
              .eq('counselor_id', pend['counselor_id'])
              .single();
          
          if (studentInfo != null) {
            final studentName = '${studentInfo['first_name']} ${studentInfo['last_name']}';
            final counselorName = '${counselorData['first_name']} ${counselorData['last_name']}';
            
            allActivities.add({
              'type': 'pending',
              'icon': 'pending_actions',
              'color': 'orange',
              'title': 'Pending approval',
              'subtitle': '$studentName with $counselorName',
              'timestamp': DateTime.parse(pend['appointment_date']),
            });
          }
        } catch (e) {
          print('Error processing pending appointment ${pend['appointment_id']}: $e');
          continue;
        }
      }

      // 7. New counselor accounts
      final newCounselors = await _supabase
          .from('users')
          .select('user_id, email, registration_date')
          .eq('user_type', 'counselor')
          .order('registration_date', ascending: false)
          .limit(10);

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
      // Fetch analytics data
      final totalUsersResult = await _supabase
          .from('users')
          .select('user_id');
      
      final activeUsersResult = await _supabase
          .from('users')
          .select('user_id')
          .eq('status', 'active');
      
      final completedSessionsResult = await _supabase
          .from('counseling_appointments')
          .select('appointment_id')
          .eq('status', 'completed');
      
      final recentRegistrationsResult = await _supabase
          .from('users')
          .select('user_id, email, registration_date')
          .gte('registration_date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .order('registration_date', ascending: false)
          .limit(10);

      return {
        'totalUsers': totalUsersResult.length,
        'activeUsers': activeUsersResult.length,
        'completedSessions': completedSessionsResult.length,
        'recentRegistrations': recentRegistrationsResult as List<dynamic>,
      };
    } catch (e) {
      print('Error getting analytics data: $e');
      throw Exception('Failed to get analytics data: ${e.toString()}');
    }
  }
}
