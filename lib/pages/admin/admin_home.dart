import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {

  int totalUsers = 0;
  int activeUsers = 0;
  int completedAppointments = 0;
  List<Map<String, dynamic>> recentActivities = [];
  bool isLoadingActivities = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoadingActivities = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // Get total users count
      final totalUsersResponse = await supabase.from('users').select('user_id');
      final totalUsersCount = totalUsersResponse.length;

      // Get active users
      final activeUsersResponse = await supabase
          .from('users')
          .select('user_id')
          .eq('status', 'active');
      final activeUsersCount = activeUsersResponse.length;

      // Get completed appointments count
      final completedAppointmentsResponse = await supabase
          .from('counseling_appointments')
          .select('appointment_id')
          .eq('status', 'completed');
      final completedAppointmentsCount = completedAppointmentsResponse.length;

      // Fetch comprehensive activities
      final activities = await _fetchRecentActivities();

      if (mounted) {
        setState(() {
          totalUsers = totalUsersCount;
          activeUsers = activeUsersCount;
          completedAppointments = completedAppointmentsCount;
          recentActivities = activities;
          isLoadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingActivities = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentActivities() async {
    final supabase = Supabase.instance.client;
    final List<Map<String, dynamic>> allActivities = [];

    try {
      // 1. New user registrations
      final registrations = await supabase
          .from('users')
          .select('user_id, email, registration_date, user_type')
          .order('registration_date', ascending: false)
          .limit(10);

      for (var reg in registrations) {
        allActivities.add({
          'type': 'registration',
          'icon': Icons.person_add,
          'color': const Color(0xFF7C83FD),
          'title': 'New ${reg['user_type']} registered',
          'subtitle': reg['email'],
          'timestamp': DateTime.parse(reg['registration_date']),
        });
      }

      // 2. New appointments booked (all statuses)
      final appointments = await supabase
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
        // Fetch student details
        final studentData = await supabase
            .from('users')
            .select('user_id')
            .eq('user_id', apt['user_id'])
            .single();
        
        final studentInfo = await supabase
            .from('students')
            .select('first_name, last_name')
            .eq('user_id', studentData['user_id'])
            .maybeSingle();
        
        // Fetch counselor details
        final counselorData = await supabase
            .from('counselors')
            .select('first_name, last_name')
            .eq('counselor_id', apt['counselor_id'])
            .single();
        
        if (studentInfo != null) {
          final studentName = '${studentInfo['first_name']} ${studentInfo['last_name']}';
          final counselorName = '${counselorData['first_name']} ${counselorData['last_name']}';
          
          allActivities.add({
            'type': 'appointment_booked',
            'icon': Icons.event,
            'color': Colors.green,
            'title': 'New appointment booked',
            'subtitle': '$studentName with $counselorName',
            'timestamp': DateTime.parse(apt['appointment_date']),
          });
        }
      }

      // 3. Cancelled sessions (student or counselor)
      // Note: We differentiate between student and counselor cancellations
      // by checking the status_message content
      final counselorCancelled = await supabase
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
        // Fetch student details
        final studentInfo = await supabase
            .from('students')
            .select('first_name, last_name')
            .eq('user_id', cancel['user_id'])
            .maybeSingle();
        
        // Fetch counselor details
        final counselorData = await supabase
            .from('counselors')
            .select('first_name, last_name')
            .eq('counselor_id', cancel['counselor_id'])
            .single();
        
        if (studentInfo != null) {
          final studentName = '${studentInfo['first_name']} ${studentInfo['last_name']}';
          final counselorName = '${counselorData['first_name']} ${counselorData['last_name']}';
          final reason = cancel['status_message'] ?? cancel['notes'] ?? 'No reason provided';
          
          // Check if cancellation was by counselor (you can customize this logic)
          // For now, we'll show as "Session cancelled by counselor" if status_message exists
          final cancelledBy = (cancel['status_message'] != null && 
                               cancel['status_message'].toString().toLowerCase().contains('counselor'))
              ? 'counselor'
              : 'student';
          
          allActivities.add({
            'type': cancelledBy == 'counselor' ? 'counselor_cancelled' : 'cancelled',
            'icon': Icons.cancel_outlined,
            'color': cancelledBy == 'counselor' ? Colors.orange[700]! : Colors.red,
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
      }

      // 4. Rejected sessions (by counselor - before accepting)
      final rejected = await supabase
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
        // Fetch student details
        final studentInfo = await supabase
            .from('students')
            .select('first_name, last_name')
            .eq('user_id', reject['user_id'])
            .maybeSingle();
        
        // Fetch counselor details
        final counselorData = await supabase
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
            'icon': Icons.block,
            'color': Colors.deepOrange,
            'title': 'Session rejected by counselor',
            'subtitle': '$counselorName rejected $studentName',
            'detail': 'Reason: $reason',
            'timestamp': DateTime.parse(reject['appointment_date']),
          });
        }
      }

      // 5. Completed sessions
      final completed = await supabase
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
        // Fetch student details
        final studentInfo = await supabase
            .from('students')
            .select('first_name, last_name')
            .eq('user_id', comp['user_id'])
            .maybeSingle();
        
        // Fetch counselor details
        final counselorData = await supabase
            .from('counselors')
            .select('first_name, last_name')
            .eq('counselor_id', comp['counselor_id'])
            .single();
        
        if (studentInfo != null) {
          final studentName = '${studentInfo['first_name']} ${studentInfo['last_name']}';
          final counselorName = '${counselorData['first_name']} ${counselorData['last_name']}';
          
          allActivities.add({
            'type': 'completed',
            'icon': Icons.check_circle,
            'color': Colors.teal,
            'title': 'Session completed',
            'subtitle': '$counselorName completed session with $studentName',
            'timestamp': DateTime.parse(comp['appointment_date']),
          });
        }
      }

      // 7. Pending appointment approvals
      final pending = await supabase
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
        // Fetch student details
        final studentInfo = await supabase
            .from('students')
            .select('first_name, last_name')
            .eq('user_id', pend['user_id'])
            .maybeSingle();
        
        // Fetch counselor details
        final counselorData = await supabase
            .from('counselors')
            .select('first_name, last_name')
            .eq('counselor_id', pend['counselor_id'])
            .single();
        
        if (studentInfo != null) {
          final studentName = '${studentInfo['first_name']} ${studentInfo['last_name']}';
          final counselorName = '${counselorData['first_name']} ${counselorData['last_name']}';
          
          allActivities.add({
            'type': 'pending',
            'icon': Icons.pending_actions,
            'color': Colors.orange,
            'title': 'Pending approval',
            'subtitle': '$studentName with $counselorName',
            'timestamp': DateTime.parse(pend['appointment_date']),
          });
        }
      }

      // 8. New counselor accounts (recent counselor type users)
      final newCounselors = await supabase
          .from('users')
          .select('user_id, email, registration_date')
          .eq('user_type', 'counselor')
          .order('registration_date', ascending: false)
          .limit(10);

      for (var counselor in newCounselors) {
        allActivities.add({
          'type': 'counselor_added',
          'icon': Icons.supervised_user_circle,
          'color': const Color(0xFF9C27B0),
          'title': 'New counselor account',
          'subtitle': counselor['email'],
          'timestamp': DateTime.parse(counselor['registration_date']),
        });
      }

      // Sort all activities by timestamp (most recent first)
      allActivities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      // Return top 15 most recent activities
      return allActivities.take(15).toList();
    } catch (e) {
      print('Error fetching activities: $e');
      return [];
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays ~/ 7} week${difference.inDays ~/ 7 > 1 ? 's' : ''} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('adminHomeScreen'),
      drawer: Drawer(
        key: const Key('drawer_button'),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF7C83FD)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 60, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    'Admin',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              key: const Key('logout_button'),
              leading: const Icon(Icons.logout, color: Color(0xFF7C83FD)),
              title: Text('Logout', style: GoogleFonts.poppins()),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            key: const Key('drawer_button'),
            icon: const Icon(Icons.menu, color: Color(0xFF5D5D72)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          "BreatheBetter",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: const [],
      ),
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [                  
                  _buildWelcomeSection(),
                  const SizedBox(height: 20),
                  _buildStatsCards(),
                  const SizedBox(height: 20),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 20),
                  _buildRecentActivitySection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        
            Text(
              "Dashboard",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A3A50),
              ),
            ),
            
         
        ElevatedButton(
          onPressed: () => _showDownloadConfirmation(
              'Analytics Report',
              'Do you want to download the Admin Analytics Report?',
              _generateAnalyticsReportPdf),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C83FD),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
            minimumSize: const Size(40, 40),
          ),
          child: const Icon(Icons.download, size: 20),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Users',
            totalUsers.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Active Users',
            activeUsers.toString(),
            Icons.person,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Completed',
            completedAppointments.toString(),
            Icons.check_circle,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A3A50),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF5D5D72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A3A50),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'User Management',
                Icons.people,
                Colors.blue,
                () => Navigator.pushNamed(context, 'admin-users'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                'Mental Health Resources',
                Icons.psychology,
                Colors.purple,
                () => Navigator.pushNamed(context, 'admin-resources'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Breathing Exercises',
                Icons.self_improvement,
                Colors.green,
                () => Navigator.pushNamed(context, 'admin-exercises'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                'Bi-Weekly Questionnaire',
                Icons.quiz,
                Colors.orange,
                () => Navigator.pushNamed(context, '/admin-questionnaire'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Manage Hotlines',
                Icons.support_agent,
                Colors.red,
                () => Navigator.pushNamed(context, 'admin-hotlines'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                'Daily\n Uplifts',
                Icons.format_quote,
                Colors.teal,
                () => Navigator.pushNamed(context, 'admin-daily-uplifts'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A3A50),
          ),
        ),
        const SizedBox(height: 16),
        _buildRecentActivityCard(),
      ],
    );
  }



  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoadingActivities
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: const Color(0xFF7C83FD),
                ),
              ),
            )
          : recentActivities.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "No recent activities",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 300, // Fixed height to show ~5 items
                  child: ListView.builder(
                    itemCount: recentActivities.length,
                    itemBuilder: (context, index) {
                      final activity = recentActivities[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: activity['color'],
                              child: Icon(
                                activity['icon'],
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['title'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF3A3A50),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    activity['subtitle'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  if (activity['detail'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      activity['detail'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTimeAgo(activity['timestamp']),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }



  Future<void> _generateAnalyticsReportPdf() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Fetch analytics data
      final totalUsersResult = await supabase
          .from('users')
          .select('user_id');
      
      final activeUsersResult = await supabase
          .from('users')
          .select('user_id')
          .eq('status', 'active');
      
      final completedSessionsResult = await supabase
          .from('counseling_appointments')
          .select('appointment_id')
          .eq('status', 'completed');
      
      final recentRegistrationsResult = await supabase
          .from('users')
          .select('user_id, email, registration_date')
          .gte('registration_date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .order('registration_date', ascending: false)
          .limit(10);

      final totalUsers = totalUsersResult.length;
      final activeUsers = activeUsersResult.length;
      final completedSessions = completedSessionsResult.length;
      final recentRegistrations = recentRegistrationsResult as List<dynamic>;

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(bottom: 30),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'BREATHE BETTER',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Admin Analytics Report',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.normal,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on ${DateTime.now().toString().split('.')[0]}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Divider line
              pw.Container(
                height: 2,
                color: PdfColors.indigo,
                margin: const pw.EdgeInsets.only(bottom: 30),
              ),
              
              // Analytics Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'System Overview',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    
                    // Statistics Grid
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPdfStatCard('Total Users', totalUsers.toString(), PdfColors.blue),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: _buildPdfStatCard('Active Users (30 days)', activeUsers.toString(), PdfColors.green),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 15),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPdfStatCard('Completed Sessions', completedSessions.toString(), PdfColors.orange),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: _buildPdfStatCard('Recent Registrations (30 days)', recentRegistrations.length.toString(), PdfColors.purple),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Recent Registrations Details
              if (recentRegistrations.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Recent Registrations Details',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      ...recentRegistrations.take(5).map((user) {
                        final registrationDate = DateTime.parse(user['registration_date']);
                        final formattedDate = '${registrationDate.day}/${registrationDate.month}/${registrationDate.year}';
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 4,
                                height: 4,
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.indigo,
                                  shape: pw.BoxShape.circle,
                                ),
                                margin: const pw.EdgeInsets.only(right: 8, top: 4),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  user['email'] ?? 'Unknown User',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  formattedDate,
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
              ],
              
              // Additional Information Section
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Report Details',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    _buildPdfDetailRow('Report Type', 'Administrative Analytics'),
                    _buildPdfDetailRow('Data Period', 'All time (with 30-day filters for specific metrics)'),
                    _buildPdfDetailRow('Generated By', 'System Administrator'),
                    _buildPdfDetailRow('Status', 'Active'),
                  ],
                ),
              ),
              
              // Footer
              pw.Spacer(),
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '© 2024 Breathe Better - Confidential Administrative Report',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF to file - try multiple locations
      String? savedPath;
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final fileName = 'breathe_better_analytics_report_$timestamp.pdf';
      
      // Try different locations in order of preference
      final locations = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads', 
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];
      
      // Also try using path_provider
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          locations.add('${extDir.path}/Download');
          locations.add(extDir.path);
        }
      } catch (e) {
        print('Could not get external storage directory: $e');
      }
      
      for (String path in locations) {
        try {
          final directory = Directory(path);
          
          // Try to create directory if it doesn't exist
          if (!await directory.exists()) {
            try {
              await directory.create(recursive: true);
            } catch (e) {
              continue; // Try next location
            }
          }
          
          final file = File('$path/$fileName');
          await file.writeAsBytes(await pdf.save());
          savedPath = file.path;
          break; // Success! Exit the loop
        } catch (e) {
          print('Failed to save to $path: $e');
          continue; // Try next location
        }
      }

      if (mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PDF saved successfully!'),
                  SizedBox(height: 4),
                  Text(
                    'Location: $savedPath',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF7C83FD),
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save PDF to any location. Please check storage permissions.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfStatCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDownloadConfirmation(
      String title, String message, Function onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Dismiss dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dismiss dialog
              onConfirm(); // Proceed with download
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}
