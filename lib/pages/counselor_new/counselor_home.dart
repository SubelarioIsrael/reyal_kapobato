import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/counselor_home_controller.dart';
import '../../models/appointment.dart';
import '../chat/direct_chat.dart';
import '../../widgets/student_avatar.dart';
import '../../components/counselor_drawer.dart';
import '../../components/counselor_notification_button.dart';
import '../../components/video_call_dialog.dart';
import 'counselor_appointments.dart';

class CounselorHome extends StatefulWidget {
  const CounselorHome({super.key});

  @override
  State<CounselorHome> createState() => _CounselorHomeState();
}

class _CounselorHomeState extends State<CounselorHome> {
  final _controller = CounselorHomeController();

  List<Appointment> _appointments = [];
  Map<String, Map<String, String>> _studentInfo = {};
  Map<String, int> _unreadCounts = {}; // userId -> unread count
  bool _isLoading = true;
  String? _errorMessage;
  String? _counselorName;

  // Stats
  int _totalStudents = 0;
  int _completedSessions = 0;
  int _upcomingSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _controller.loadAppointments();

    if (result.success) {
      setState(() {
        _appointments = result.appointments;
        _studentInfo = result.studentInfo;
        _totalStudents = result.totalStudents;
        _completedSessions = result.completedSessions;
        _upcomingSessions = result.upcomingSessions;
        _counselorName = result.counselorName;
        _isLoading = false;
      });

      // Load unread message counts for today's appointments
      _loadUnreadMessages();

      // New: possibly show weekly intervention analysis dialog
      _maybeShowWeeklyAnalysis();
    } else {
      // Handle special error codes
      if (result.errorMessage == 'PROFILE_NOT_FOUND' || result.errorMessage == 'PROFILE_INCOMPLETE') {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCounselorWelcomeDialog();
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage ?? 'Error loading appointments';
      });
    }
  }

  Future<void> _loadUnreadMessages() async {
    final today = DateTime.now();
    
    final todayAppointments = _appointments.where((appt) {
      final apptDate = appt.appointmentDate;
      final isToday = apptDate.year == today.year &&
          apptDate.month == today.month &&
          apptDate.day == today.day;
      final isAccepted = appt.status.toLowerCase() == 'accepted';
      return isToday && isAccepted;
    }).toList();

    if (todayAppointments.isEmpty) {
      return;
    }

    final todayAppointmentIds = todayAppointments.map((a) => a.id).toList();
    final result = await _controller.getUnreadMessageCounts(todayAppointmentIds);
    if (result.success) {
      // Map appointment IDs to user IDs for the unread counts
      Map<String, int> userUnreadCounts = {};
      for (var appt in todayAppointments) {
        final count = result.unreadCounts[appt.id] ?? 0;
        userUnreadCounts[appt.userId] = count;
      }
      setState(() {
        _unreadCounts = userUnreadCounts;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey[600]!;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateAppointmentStatus(
      Appointment appt, String newStatus) async {
    String? statusMessage;
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (context) {
        final messageController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(newStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  newStatus.toLowerCase() == 'accepted'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: _getStatusColor(newStatus),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${newStatus.toUpperCase()} Appointment',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to ${newStatus.toLowerCase()} this appointment?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message (optional)',
                  hintText: 'Add a note for this status change',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3A3A50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        statusMessage = messageController.text.trim();
                        confirmed = true;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getStatusColor(newStatus),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        newStatus == 'accepted' ? 'Accept' : 'Reject',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _controller.updateAppointmentStatus(
      appointmentId: appt.id,
      userId: appt.userId,
      newStatus: newStatus,
      appointmentDate: appt.appointmentDate,
      startTime: appt.startTime,
      endTime: appt.endTime,
      statusMessage: statusMessage,
    );

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      _showSuccessDialog(
          'Appointment status updated to ${newStatus.toUpperCase()}');
      _loadAppointments();
    } else {
      _showErrorDialog(result.errorMessage ?? 'Failed to update appointment');
    }
  }

  void _showStudentNoteDialog(Appointment appointment) {
    final hasNote =
        appointment.notes != null && appointment.notes!.trim().isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C83FD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.note_outlined,
                color: Color(0xFF7C83FD),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Student Note',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasNote
                    ? const Color(0xFF7C83FD).withOpacity(0.05)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasNote
                      ? const Color(0xFF7C83FD).withOpacity(0.2)
                      : Colors.grey[300]!,
                ),
              ),
              child: hasNote
                  ? SingleChildScrollView(
                      child: Text(
                        appointment.notes!.trim(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF3A3A50),
                          height: 1.5,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Student didn\'t attach a note',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Success',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCounselorWelcomeDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C83FD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology,
                    color: Color(0xFF7C83FD), size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, Counselor!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome to BreatheBetter! Let\'s set up your professional profile to help students connect with you effectively. This will only take a few minutes.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.4,
                  color: const Color(0xFF5D5D72),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(
                        context, '/counselor-first-setup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Set Up Profile',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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

  // New helper: check SharedPreferences and show AI analysis at most once every 7 days
  Future<void> _maybeShowWeeklyAnalysis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShownStr = prefs.getString('last_weekly_analysis_shown');
      if (lastShownStr != null) {
        final lastShown = DateTime.tryParse(lastShownStr);
        if (lastShown != null && DateTime.now().difference(lastShown) < Duration(days: 7)) {
          return; // already shown this week
        }
      }

      // Show a small loading dialog while analysis runs
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SizedBox(
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Analyzing recent intervention logs...')
              ],
            ),
          ),
        ),
      );

      final analysisResult = await _controller.getWeeklyInterventionAnalysis();

      // Dismiss loading dialog
      if (mounted) Navigator.pop(context);

      if (!analysisResult.success) {
        return;
      }

      final analysisText = (analysisResult.analysis ?? '').trim();
      if (analysisText.isEmpty) {
        await prefs.setString('last_weekly_analysis_shown', DateTime.now().toIso8601String());
        return;
      }

      // Prepare compact bullets
      final lines = analysisText.split(RegExp(r'\n+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      // Show formatted modern dialog
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C83FD).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics_outlined, color: Color(0xFF7C83FD)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Weekly Intervention Analysis',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: lines.map((line) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 18)),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: GoogleFonts.poppins(fontSize: 14, height: 1.4, color: const Color(0xFF3A3A50)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C83FD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Close', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Mark as shown now
      await prefs.setString('last_weekly_analysis_shown', DateTime.now().toIso8601String());
    } catch (e) {
      // ignore failures silently to avoid breaking UI; could log
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('counselorHomeScreen'),
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
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
        actions: const [
          CounselorNotificationButton(),
        ],
      ),
      drawer: const CounselorDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          const SizedBox(height: 32),
                          _buildStatsCards(),
                          const SizedBox(height: 32),
                          _buildPendingRequestsSection(),
                          const SizedBox(height: 32),
                          _buildTodayAppointmentsSection(),
                          const SizedBox(height: 32),
                          _buildQuickActionsSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Back",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5D5D72),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _counselorName != null ? "Dr. $_counselorName" : "Counselor",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Help students on their mental health journey",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF5D5D72),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Students',
            _totalStudents.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Completed Sessions',
            _completedSessions.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Upcoming Sessions',
            _upcomingSessions.toString(),
            Icons.schedule,
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
        padding: const EdgeInsets.all(10),
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

  Widget _buildPendingRequestsSection() {
    final pendingAppointments = _appointments
        .where((a) => a.status.toLowerCase() == 'pending')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pending Requests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(width: 8),
            if (pendingAppointments.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pendingAppointments.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (pendingAppointments.isEmpty)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No pending requests',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...pendingAppointments
              .take(3)
              .map((appt) => _buildPendingAppointmentCard(appt)),
        if (pendingAppointments.length > 3)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CounselorAppointments(),
                ),
              );
            },
            child: Text(
              'View all ${pendingAppointments.length} pending requests',
              style: GoogleFonts.poppins(color: const Color(0xFF7C83FD)),
            ),
          ),
      ],
    );
  }

  Widget _buildPendingAppointmentCard(Appointment appt) {
    final studentInfo = _studentInfo[appt.userId.toString().trim()] ?? {};
    final studentName = studentInfo['student_name'] ?? 'Unknown Student';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StudentAvatar(
                  userId: appt.userId,
                  radius: 28,
                  fallbackName: studentName,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Date and time with icon
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Color(0xFF7C83FD),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            appt.appointmentDate.toString().split(' ')[0],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF5D5D72),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Start and End Time
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFF7C83FD),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${TimeOfDay.fromDateTime(appt.startTime).format(context)} - ${TimeOfDay.fromDateTime(appt.endTime).format(context)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF5D5D72),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Kebab menu for view note, accept, and reject
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF3A3A50),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view_note',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.note_outlined,
                            size: 18,
                            color: Color(0xFF7C83FD),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'View Note',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'accept',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Accept',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reject',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cancel_outlined,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Reject',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'view_note') {
                      _showStudentNoteDialog(appt);
                    } else if (value == 'accept') {
                      await _updateAppointmentStatus(appt, 'accepted');
                    } else if (value == 'reject') {
                      await _updateAppointmentStatus(appt, 'rejected');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAppointmentsSection() {
    final today = DateTime.now();
    
    final todayAppointments = _appointments.where((appt) {
      final apptDate = appt.appointmentDate;
      final isToday = apptDate.year == today.year &&
          apptDate.month == today.month &&
          apptDate.day == today.day;
      final isAccepted = appt.status.toLowerCase() == 'accepted';
      return isToday && isAccepted;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Schedule',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A3A50),
          ),
        ),
        const SizedBox(height: 16),
        if (todayAppointments.isEmpty)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No appointments today',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...todayAppointments.map((appt) => _buildTodayAppointmentCard(appt)),
      ],
    );
  }

  Widget _buildTodayAppointmentCard(Appointment appt) {
    final studentInfo = _studentInfo[appt.userId.toString().trim()] ?? {};
    final studentName = studentInfo['student_name'] ?? 'Unknown Student';
    final unreadCount = _unreadCounts[appt.userId] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            StudentAvatar(
              userId: appt.userId,
              radius: 24,
              fallbackName: studentName,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Name (Horizontally Scrollable)
                  SizedBox(
                    height: 22,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        studentName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFF7C83FD),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${TimeOfDay.fromDateTime(appt.startTime).format(context)} - ${TimeOfDay.fromDateTime(appt.endTime).format(context)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Chat icon button with unread badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () async {
                    final studentKey = appt.userId.toString().trim();
                    final studentName = _studentInfo[studentKey]?['student_name'] ?? 'Student';
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DirectChat(
                          otherUserId: appt.userId,
                          otherUserName: studentName,
                          isCounselor: true,
                          studentUserId: appt.userId,
                        ),
                      ),
                    );
                    // Reload unread counts after returning from chat
                    _loadUnreadMessages();
                  },
                  icon: const Icon(Icons.chat, color: Color(0xFF7C83FD)),
                  tooltip: 'Chat',
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
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
                'Appointments',
                Icons.calendar_today,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CounselorAppointments(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              key: const Key('my_students_card'),
              child: _buildQuickActionCard(
                'Students',
                Icons.people,
                Colors.purple,
                () {
                  Navigator.pushNamed(context, '/student-history-list');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Student Chats',
                Icons.chat,
                Colors.green,
                () {
                  Navigator.pushNamed(context, '/counselor-chat-list');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                'Video Call',
                Icons.video_call,
                Colors.orange,
                () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const VideoCallDialog(userRole: 'counselor'),
                  );
                },
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

}
