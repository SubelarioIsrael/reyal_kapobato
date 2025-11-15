import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:breathe_better/controllers/admin_controller.dart';
import 'package:breathe_better/components/admin_drawer.dart';
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
  final _adminController = AdminController();

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
      // Get dashboard statistics using controller
      final statsResult = await _adminController.getDashboardStats();

      if (!statsResult.success) {
        _showErrorDialog(statsResult.errorMessage ?? 'Failed to load statistics');
        return;
      }

      // Get recent activities using controller
      final activitiesResult = await _adminController.fetchRecentActivities();

      if (!activitiesResult.success) {
        _showErrorDialog(activitiesResult.errorMessage ?? 'Failed to load activities');
        return;
      }

      if (mounted) {
        setState(() {
          totalUsers = statsResult.totalUsers;
          activeUsers = statsResult.activeUsers;
          completedAppointments = statsResult.completedAppointments;
          recentActivities = activitiesResult.activities;
          isLoadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingActivities = false;
        });
        _showErrorDialog('An unexpected error occurred: ${e.toString()}');
      }
    }
  }

  // Helper method to show error dialog
  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Error Title
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              // Error Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                ),
              ),
              const SizedBox(height: 24),
              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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

  // Helper to get icon from string name
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'person_add':
        return Icons.person_add;
      case 'event':
        return Icons.event;
      case 'cancel_outlined':
        return Icons.cancel_outlined;
      case 'block':
        return Icons.block;
      case 'check_circle':
        return Icons.check_circle;
      case 'pending_actions':
        return Icons.pending_actions;
      case 'supervised_user_circle':
        return Icons.supervised_user_circle;
      default:
        return Icons.info;
    }
  }

  // Helper to get color from string name
  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'purple':
        return const Color(0xFF7C83FD);
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'orange_dark':
        return Colors.orange[700]!;
      case 'orange':
        return Colors.orange;
      case 'deep_orange':
        return Colors.deepOrange;
      case 'teal':
        return Colors.teal;
      case 'deep_purple':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('adminHomeScreen'),
      drawer: const AdminDrawer(),
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
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Color(0xFF7C83FD),
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
                              backgroundColor: _getColorFromString(activity['color']),
                              child: Icon(
                                _getIconFromString(activity['icon']),
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
      // Get analytics data from controller
      final analyticsData = await _adminController.getAnalyticsData();
      
      final totalUsers = analyticsData['totalUsers'] as int;
      final activeUsers = analyticsData['activeUsers'] as int;
      final completedSessions = analyticsData['completedSessions'] as int;
      final recentRegistrations = analyticsData['recentRegistrations'] as List<dynamic>;

      // Fetch recent activities (daily check-ins, mood journals, breathing exercises)
      final recentActivitiesResponse = await Supabase.instance.client
          .from('activity_completions')
          .select('*, users(email), activities(name)')
          .order('completed_at', ascending: false)
          .limit(20);
      final recentActivities = List<Map<String, dynamic>>.from(recentActivitiesResponse);

      // Fetch recent counseling sessions with details
      final counselingSessionsResponse = await Supabase.instance.client
          .from('counseling_appointments')
          .select('*, counselors(first_name, last_name), users(email)')
          .eq('status', 'completed')
          .order('appointment_date', ascending: false)
          .limit(15);
      final counselingSessions = List<Map<String, dynamic>>.from(counselingSessionsResponse);

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
              
              // Recent Activities Section
              if (recentActivities.isNotEmpty)
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
                        'Recent User Activities',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      ...recentActivities.take(15).map((activity) {
                        final userEmail = activity['users']?['email'] ?? 'Unknown User';
                        final activityName = activity['activities']?['name'] ?? 'Unknown Activity';
                        final completedAt = DateTime.parse(activity['completed_at']);
                        final formattedDate = '${completedAt.day}/${completedAt.month}/${completedAt.year} ${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')}';
                        
                        // Create descriptive activity text
                        String activityDescription = '';
                        switch (activityName.toLowerCase()) {
                          case 'daily_checkin':
                            activityDescription = 'Completed daily mental health check-in';
                            break;
                          case 'mood_journal':
                            activityDescription = 'Recorded mood entry in journal';
                            break;
                          case 'breathing_exercise':
                            activityDescription = 'Completed breathing exercise session';
                            break;
                          case 'weekly_mood':
                            activityDescription = 'Submitted weekly mood assessment';
                            break;
                          case 'mental_health_assessment':
                            activityDescription = 'Completed mental health questionnaire';
                            break;
                          default:
                            activityDescription = activityName.replaceAll('_', ' ').split(' ').map((word) => 
                              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
                            ).join(' ');
                        }
                        
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
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
                                      userEmail,
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.grey800,
                                      ),
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 2,
                                    child: pw.Text(
                                      formattedDate,
                                      style: pw.TextStyle(
                                        fontSize: 10,
                                        color: PdfColors.grey600,
                                      ),
                                      textAlign: pw.TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(left: 12, top: 2),
                                child: pw.Text(
                                  activityDescription,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                    fontStyle: pw.FontStyle.italic,
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
                
              if (recentActivities.isNotEmpty)
                pw.SizedBox(height: 30),
              
              // Counseling Sessions Section
              if (counselingSessions.isNotEmpty)
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
                        'Recent Counseling Sessions',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      ...counselingSessions.take(12).map((session) {
                        final counselor = session['counselors'] as Map<String, dynamic>?;
                        final counselorName = counselor != null && 
                                              counselor['first_name'] != null && 
                                              counselor['last_name'] != null
                            ? '${counselor['first_name']} ${counselor['last_name']}'
                            : 'Unknown Counselor';
                        final studentEmail = session['users']?['email'] ?? 'Unknown Student';
                        final appointmentDate = DateTime.parse(session['appointment_date']);
                        final formattedDate = '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
                        
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 4,
                                height: 4,
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.purple,
                                  shape: pw.BoxShape.circle,
                                ),
                                margin: const pw.EdgeInsets.only(right: 8, top: 4),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  studentEmail,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  counselorName,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  formattedDate,
                                  style: pw.TextStyle(
                                    fontSize: 10,
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
                
              if (counselingSessions.isNotEmpty)
                pw.SizedBox(height: 30),
              
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
          _showSuccessDialog('PDF saved successfully!\n\nLocation: $savedPath');
        } else {
          _showErrorDialog('Failed to save PDF to any location. Please check storage permissions.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error generating PDF: ${e.toString()}');
      }
    }
  }

  // Helper method to show success dialog
  void _showSuccessDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Success Title
              Text(
                'Success',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              // Success Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                ),
              ),
              const SizedBox(height: 24),
              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C83FD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download,
                color: Color(0xFF7C83FD),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFF7C83FD)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C83FD),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C83FD),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Text(
                      'Download',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
