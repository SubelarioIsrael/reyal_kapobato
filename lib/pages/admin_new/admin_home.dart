import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:breathe_better/controllers/admin_controller.dart';
import 'package:breathe_better/components/admin_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF3D5A99)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Manage your system from here',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showDownloadConfirmation(
                    'Analytics Report',
                    'Do you want to download the Admin Analytics Report?',
                    _generateAnalyticsReportPdf),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A237E),
                  padding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  minimumSize: const Size(40, 40),
                ),
                child: const Icon(Icons.download_rounded, size: 20),
              ),
            ],
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          top: BorderSide(color: color, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF8888A0),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 20,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3A3A50),
              ),
            ),
          ],
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF7C83FD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3A3A50),
              ),
            ),
          ],
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
      final reportRef = 'BB-ADM-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final generatedOn = DateTime.now();
      final formattedGenDate =
          '${generatedOn.day.toString().padLeft(2, '0')} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][generatedOn.month - 1]} ${generatedOn.year}  ${generatedOn.hour.toString().padLeft(2, '0')}:${generatedOn.minute.toString().padLeft(2, '0')}';

      // ── colour palette ──────────────────────────────────────────────────────
      const headerBg      = PdfColor.fromInt(0xFF1A237E); // deep indigo
      const accentBlue    = PdfColor.fromInt(0xFF1565C0);
      const accentGreen   = PdfColor.fromInt(0xFF2E7D32);
      const accentOrange  = PdfColor.fromInt(0xFFE65100);
      const accentPurple  = PdfColor.fromInt(0xFF6A1B9A);
      const tableHeader   = PdfColor.fromInt(0xFF3949AB);
      const rowAlt        = PdfColor.fromInt(0xFFF3F4FF);
      const borderGrey    = PdfColor.fromInt(0xFFCFD8DC);
      const textDark      = PdfColor.fromInt(0xFF1A1A2E);
      const textMid       = PdfColor.fromInt(0xFF424242);
      const textLight     = PdfColor.fromInt(0xFF757575);
      const white         = PdfColors.white;

      // ── helper: section title bar ───────────────────────────────────────────
      pw.Widget sectionTitle(String title, PdfColor accent) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: white,
              letterSpacing: 0.5,
            ),
          ),
        );
      }

      // ── helper: table header row ─────────────────────────────────────────────
      pw.Widget tableHeaderRow(List<String> cols, List<int> flex) {
        return pw.Container(
          color: tableHeader,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Row(
            children: List.generate(cols.length, (i) => pw.Expanded(
              flex: flex[i],
              child: pw.Text(
                cols[i].toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: white,
                  letterSpacing: 0.4,
                ),
              ),
            )),
          ),
        );
      }

      // ── helper: table data row ───────────────────────────────────────────────
      pw.Widget tableDataRow(List<String> cells, List<int> flex, bool isAlt) {
        return pw.Container(
          color: isAlt ? rowAlt : white,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Row(
            children: List.generate(cells.length, (i) => pw.Expanded(
              flex: flex[i],
              child: pw.Text(
                cells[i],
                style: pw.TextStyle(fontSize: 10, color: textMid),
              ),
            )),
          ),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          header: (pw.Context ctx) {
            if (ctx.pageNumber == 1) return pw.SizedBox();
            // continuation header on subsequent pages
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const pw.BoxDecoration(
                color: headerBg,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('BREATHE BETTER — Admin Analytics Report',
                      style: pw.TextStyle(fontSize: 9, color: white, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Ref: $reportRef  |  Page ${ctx.pageNumber}',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.indigo100)),
                ],
              ),
            );
          },
          footer: (pw.Context ctx) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderGrey, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('CONFIDENTIAL — FOR AUTHORISED PERSONNEL ONLY',
                    style: pw.TextStyle(fontSize: 7.5, color: textLight, letterSpacing: 0.3)),
                pw.Text('© ${generatedOn.year} Breathe Better  |  Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    style: pw.TextStyle(fontSize: 7.5, color: textLight)),
              ],
            ),
          ),
          build: (pw.Context context) {
            return [
              // ── COVER HEADER ─────────────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                decoration: const pw.BoxDecoration(
                  color: headerBg,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('BREATHE BETTER',
                                style: pw.TextStyle(
                                    fontSize: 26, fontWeight: pw.FontWeight.bold, color: white, letterSpacing: 2)),
                            pw.SizedBox(height: 6),
                            pw.Text('Admin Analytics Report',
                                style: pw.TextStyle(fontSize: 15, color: PdfColors.indigo100, letterSpacing: 0.5)),
                          ],
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.red700,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text('CONFIDENTIAL',
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold, color: white, letterSpacing: 1.2)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 18),
                    pw.Container(height: 0.8, color: PdfColors.indigo300),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      children: [
                        _buildHeaderMeta('Generated', formattedGenDate, white),
                        pw.SizedBox(width: 40),
                        _buildHeaderMeta('Reference No.', reportRef, white),
                        pw.SizedBox(width: 40),
                        _buildHeaderMeta('Prepared By', 'System Administrator', white),
                        pw.SizedBox(width: 40),
                        _buildHeaderMeta('Classification', 'Internal Use Only', white),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ── SYSTEM OVERVIEW ───────────────────────────────────────────────
              sectionTitle('System Overview', accentBlue),
              pw.Row(
                children: [
                  pw.Expanded(child: _buildPdfStatCard('Total Users', totalUsers.toString(), accentBlue)),
                  pw.SizedBox(width: 14),
                  pw.Expanded(child: _buildPdfStatCard('Active Users (30 days)', activeUsers.toString(), accentGreen)),
                  pw.SizedBox(width: 14),
                  pw.Expanded(child: _buildPdfStatCard('Completed Sessions', completedSessions.toString(), accentOrange)),
                  pw.SizedBox(width: 14),
                  pw.Expanded(child: _buildPdfStatCard('New Registrations (30 days)', recentRegistrations.length.toString(), accentPurple)),
                ],
              ),

              pw.SizedBox(height: 24),

              // ── RECENT REGISTRATIONS ──────────────────────────────────────────
              if (recentRegistrations.isNotEmpty) ...[
                sectionTitle('Recent User Registrations  (last 30 days)', accentGreen),
                pw.ClipRect(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderGrey, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      children: [
                        tableHeaderRow(['#', 'Email Address', 'Registration Date'], [1, 6, 3]),
                        ...recentRegistrations.take(10).toList().asMap().entries.map((e) {
                          final idx = e.key;
                          final user = e.value;
                          final regDate = DateTime.parse(user['registration_date']);
                          final fd = '${regDate.day.toString().padLeft(2,'0')}/${regDate.month.toString().padLeft(2,'0')}/${regDate.year}';
                          return tableDataRow(
                            ['${idx + 1}', user['email'] ?? '—', fd],
                            [1, 6, 3],
                            idx.isOdd,
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 24),
              ],

              // ── RECENT USER ACTIVITIES ────────────────────────────────────────
              if (recentActivities.isNotEmpty) ...[
                sectionTitle('Recent User Activities', accentBlue),
                pw.ClipRect(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderGrey, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      children: [
                        tableHeaderRow(['#', 'User', 'Activity', 'Date & Time'], [1, 4, 4, 3]),
                        ...recentActivities.take(15).toList().asMap().entries.map((e) {
                          final idx = e.key;
                          final activity = e.value;
                          final userEmail = activity['users']?['email'] ?? 'Unknown';
                          final activityName = activity['activities']?['name'] ?? 'Unknown';
                          final completedAt = DateTime.parse(activity['completed_at']);
                          final fd = '${completedAt.day.toString().padLeft(2,'0')}/${completedAt.month.toString().padLeft(2,'0')}/${completedAt.year}  ${completedAt.hour.toString().padLeft(2,'0')}:${completedAt.minute.toString().padLeft(2,'0')}';
                          String label;
                          switch (activityName.toLowerCase()) {
                            case 'daily_checkin': label = 'Daily Check-in'; break;
                            case 'mood_journal': label = 'Mood Journal'; break;
                            case 'breathing_exercise': label = 'Breathing Exercise'; break;
                            case 'weekly_mood': label = 'Weekly Mood'; break;
                            case 'mental_health_assessment': label = 'MH Assessment'; break;
                            default:
                              label = activityName.replaceAll('_', ' ').split(' ').map(
                                (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
                          }
                          return tableDataRow(
                            ['${idx + 1}', userEmail, label, fd],
                            [1, 4, 4, 3],
                            idx.isOdd,
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 24),
              ],

              // ── COUNSELING SESSIONS ───────────────────────────────────────────
              if (counselingSessions.isNotEmpty) ...[
                sectionTitle('Recent Counseling Sessions', accentPurple),
                pw.ClipRect(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderGrey, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      children: [
                        tableHeaderRow(['#', 'Student', 'Counselor', 'Date', 'Status'], [1, 4, 3, 2, 2]),
                        ...counselingSessions.take(12).toList().asMap().entries.map((e) {
                          final idx = e.key;
                          final session = e.value;
                          final counselor = session['counselors'] as Map<String, dynamic>?;
                          final counselorName = (counselor?['first_name'] != null && counselor?['last_name'] != null)
                              ? '${counselor!['first_name']} ${counselor['last_name']}'
                              : 'N/A';
                          final studentEmail = session['users']?['email'] ?? '—';
                          final apptDate = DateTime.parse(session['appointment_date']);
                          final fd = '${apptDate.day.toString().padLeft(2,'0')}/${apptDate.month.toString().padLeft(2,'0')}/${apptDate.year}';
                          return tableDataRow(
                            ['${idx + 1}', studentEmail, counselorName, fd, 'Completed'],
                            [1, 4, 3, 2, 2],
                            idx.isOdd,
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 24),
              ],

              // ── REPORT METADATA ───────────────────────────────────────────────
              sectionTitle('Report Details', textDark),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: rowAlt,
                  border: pw.Border.all(color: borderGrey, width: 0.8),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    _buildPdfDetailRow('Report Reference', reportRef),
                    _buildPdfDetailRow('Report Type', 'Administrative Analytics'),
                    _buildPdfDetailRow('Data Scope', 'All-time records; 30-day window for activity metrics'),
                    _buildPdfDetailRow('Generated By', 'System Administrator'),
                    _buildPdfDetailRow('Generated On', formattedGenDate),
                    _buildPdfDetailRow('Classification', 'Confidential — Internal Use Only'),
                    _buildPdfDetailRow('System Status', 'Operational'),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ── DISCLAIMER ────────────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.orange700, width: 3),
                  ),
                  color: PdfColor.fromInt(0xFFFFF8E1),
                ),
                child: pw.Text(
                  'This report is generated automatically by the Breathe Better platform and is '
                  'intended solely for authorised administrative personnel. The data contained herein '
                  'is confidential and must not be disclosed to unauthorised parties.',
                  style: pw.TextStyle(fontSize: 9, color: textMid, lineSpacing: 3),
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF to file
      String? savedPath;
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final fileName = 'breathe_better_analytics_report_$timestamp.pdf';
      final pdfBytes = await pdf.save();

      // Request storage permissions at runtime (Android ≤ 10 needs WRITE_EXTERNAL_STORAGE;
      // Android 11+ ignores it, but we still attempt — the internal docs fallback always works).
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (status.isDenied) {
          await Permission.storage.request();
        }
      }

      // Ordered list of locations to attempt
      final locations = <String>[];

      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          locations.add(extDir.path);
        }
      } catch (_) {}

      // Public Downloads folder (works on Android ≤ 9 with permission or Android 10 scoped storage)
      locations.addAll([
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ]);

      for (String path in locations) {
        try {
          final directory = Directory(path);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          final file = File('$path/$fileName');
          await file.writeAsBytes(pdfBytes);
          savedPath = file.path;
          break;
        } catch (e) {
          print('Failed to save to $path: $e');
        }
      }

      // Guaranteed fallback — internal app documents directory
      if (savedPath == null) {
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          final file = File('${docsDir.path}/$fileName');
          await file.writeAsBytes(pdfBytes);
          savedPath = file.path;
        } catch (e) {
          print('Failed to save to documents directory: $e');
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          left: pw.BorderSide(color: color, width: 4),
          top: pw.BorderSide(color: const PdfColor.fromInt(0xFFCFD8DC), width: 0.8),
          right: pw.BorderSide(color: const PdfColor.fromInt(0xFFCFD8DC), width: 0.8),
          bottom: pw.BorderSide(color: const PdfColor.fromInt(0xFFCFD8DC), width: 0.8),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              color: const PdfColor.fromInt(0xFF616161),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeaderMeta(String label, String value, PdfColor textColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 7,
            color: PdfColors.indigo200,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9.5,
            color: textColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 180,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF3949AB),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                color: const PdfColor.fromInt(0xFF212121),
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
