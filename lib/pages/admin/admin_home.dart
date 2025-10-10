import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pdf/widgets.dart' as pw;
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
  List<Map<String, dynamic>> recentRegistrations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final supabase = Supabase.instance.client;

      // Get total users count
      final totalUsersResponse = await supabase.from('users').select('user_id');
      final totalUsersCount = totalUsersResponse.length;

      // Get active users (users who have logged in within the last 24 hours)
      final activeUsersResponse = await supabase
          .from('students')
          .select('user_id')
          .gte(
              'last_login',
              DateTime.now()
                  .subtract(const Duration(hours: 24))
                  .toIso8601String());
      final activeUsersCount = activeUsersResponse.length;

      // Get completed appointments count
      final completedAppointmentsResponse = await supabase
          .from('counseling_appointments')
          .select('appointment_id')
          .eq('status', 'completed');
      final completedAppointmentsCount = completedAppointmentsResponse.length;

      // Get recent user registrations (last 5) with email instead of username
      final recentRegistrationsResponse = await supabase
          .from('users')
          .select('email, registration_date')
          .order('registration_date', ascending: false)
          .limit(5);

      final recentRegistrationsList = recentRegistrationsResponse.map((user) {
        final registrationDate = DateTime.parse(user['registration_date']);
        final now = DateTime.now();
        final difference = now.difference(registrationDate);

        String timeAgo;
        if (difference.inHours < 24) {
          timeAgo = '${difference.inHours} hours ago';
        } else if (difference.inDays < 7) {
          timeAgo = '${difference.inDays} days ago';
        } else {
          timeAgo = '${difference.inDays ~/ 7} weeks ago';
        }

        return {
          'name': user['email'],
          'time': timeAgo,
        };
      }).toList();

      if (mounted) {
        setState(() {
          totalUsers = totalUsersCount;
          activeUsers = activeUsersCount;
          completedAppointments = completedAppointmentsCount;
          recentRegistrations = recentRegistrationsList;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
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
                    'Admin Portal',
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
              leading: const Icon(Icons.settings, color: Color(0xFF7C83FD)),
              title: Text('Settings', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, 'admin-settings');
              },
            ),
            const Divider(),
            ListTile(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFF5D5D72)),
            onPressed: () => _showDownloadConfirmation(
                'Analytics Report',
                'Do you want to download the Admin Analytics Report?',
                _generateAnalyticsReportPdf),
            tooltip: 'Download Analytics Report',
          ),
        ],
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
                  const SizedBox(height: 20),
                  _buildStatsCards(),
                  const SizedBox(height: 32),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 32),
                  _buildRecentActivitySection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
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
                'Questionnaire',
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
            const Expanded(child: SizedBox()), // Empty space for symmetry
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent User Registrations",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A50),
            ),
          ),
          const SizedBox(height: 16),
          ...recentRegistrations.map((registration) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF7C83FD),
                      child:
                          Icon(Icons.person_add, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            registration['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          Text(
                            registration['time'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAnalyticsReportPdf() async {
    try {
      final supabase = Supabase.instance.client;

      // Generate PDF content
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(level: 0, text: 'BreatheBetter Admin Analytics Report'),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'User Statistics'),
            pw.Text('Total Users: $totalUsers'),
            pw.Text('Active Users (last 24h): $activeUsers'),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'Recent Registrations'),
            if (recentRegistrations.isEmpty)
              pw.Text('No recent registrations.')
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: recentRegistrations.map((user) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Text('- ${user['name']} (${user['time']})'),
                  );
                }).toList(),
              ),
          ],
        ),
      );

      // Save PDF to file
      final directory =
          await getExternalStorageDirectory(); // This typically points to .../Android/data/com.example.breathe_better/files
      if (directory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access external storage.')),
          );
        }
        print('Error: Could not access external storage.');
        return;
      }

      final customDownloadsPath = '${directory.path}/downloads';
      final customDownloadsDir = Directory(customDownloadsPath);

      if (!await customDownloadsDir.exists()) {
        await customDownloadsDir.create(recursive: true);
      }

      final file = File(
          '$customDownloadsPath/breathe_better_analytics_report_${DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-')}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to Downloads: ${file.path}')),
        );
      }
      print('Report saved to Downloads: ${file.path}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
      print('Error generating PDF: $e');
    }
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
