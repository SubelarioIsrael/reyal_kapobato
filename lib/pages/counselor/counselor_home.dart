import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../chat/appointment_chat.dart';
import 'student_overview.dart';
import 'video_call_dialog.dart';

import '../../widgets/student_avatar.dart';
import '../../components/counselor_drawer.dart';
import '../../services/notification_service.dart';

class CounselorHome extends StatefulWidget {
  const CounselorHome({super.key});

  @override
  State<CounselorHome> createState() => _CounselorHomeState();
}

class _CounselorHomeState extends State<CounselorHome> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _counselorName;
  Map<String, Map<String, String>> _studentInfo = {};

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
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Check user_type in users table
      final userRow = await Supabase.instance.client
          .from('users')
          .select('user_type')
          .eq('user_id', user.id)
          .maybeSingle();
      if (userRow == null || userRow['user_type'] != 'counselor') {
        setState(() {
          _appointments = [];
          _isLoading = false;
          _errorMessage = 'You are not authorized to view this page.';
        });
        return;
      }

      // Check if counselor profile exists and is complete
      final counselorProfile = await Supabase.instance.client
          .from('counselors')
          .select('counselor_id, first_name, last_name, specialization, bio')
          .eq('user_id', user.id)
          .maybeSingle();

      if (counselorProfile == null) {
        // No counselor profile exists, redirect to setup
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/counselor-profile-first-setup');
        }
        return;
      }

      // Check if profile is incomplete
      final firstName = counselorProfile['first_name'] as String?;
      final lastName = counselorProfile['last_name'] as String?;
      final specialization = counselorProfile['specialization'] as String?;
      final bio = counselorProfile['bio'] as String?;

      final isProfileIncomplete = (firstName?.trim().isEmpty ?? true) ||
          (lastName?.trim().isEmpty ?? true) ||
          (specialization?.trim().isEmpty ?? true) ||
          (bio?.trim().isEmpty ?? true);

      if (isProfileIncomplete) {
        // Show welcome dialog for first-time counselor setup
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCounselorWelcomeDialog();
        });
        return;
      }

      final counselorId = counselorProfile['counselor_id'] as int?;
      if (counselorId == null) {
        setState(() {
          _appointments = [];
          _isLoading = false;
          _errorMessage = 'Error with counselor profile. Please contact admin.';
        });
        return;
      }
      final response = await Supabase.instance.client
          .from('counseling_appointments')
          .select()
          .eq('counselor_id', counselorId)
          .order('appointment_date');
      final appointments =
          (response as List).map((json) => Appointment.fromJson(json)).toList();
      // Fetch student info for all unique user_ids
      final userIds =
          appointments.map((a) => a.userId.toString().trim()).toSet().toList();
      print('userIds: $userIds');
      Map<String, Map<String, String>> studentInfo = {};
      if (userIds.isNotEmpty) {
        final studentsResponse = await Supabase.instance.client
            .from('students')
            .select('user_id, student_code, first_name, last_name')
            .inFilter('user_id', userIds);
        print('studentsResponse: $studentsResponse');
        for (var s in studentsResponse) {
          final key = s['user_id'].toString().trim();
          final firstName = s['first_name'] ?? '';
          final lastName = s['last_name'] ?? '';
          final fullName = '$firstName $lastName'.trim();
          studentInfo[key] = {
            'student_name': fullName.isNotEmpty ? fullName : 'Unknown Student',
            'student_id': s['student_code'] ?? ''
          };
        }
      }
      // Calculate statistics
      final uniqueStudents = appointments.map((a) => a.userId).toSet().length;
      final completed = appointments
          .where((a) => a.status.toLowerCase() == 'completed')
          .length;
      final upcoming = appointments
          .where((a) =>
              a.status.toLowerCase() == 'accepted' &&
              a.appointmentDate.isAfter(DateTime.now()))
          .length;

      // Get counselor name from existing profile data
      final nameFirst = counselorProfile['first_name'] as String? ?? '';
      final nameLast = counselorProfile['last_name'] as String? ?? '';
      final fullName = '$nameFirst $nameLast'.trim();

      setState(() {
        _appointments = appointments;
        _studentInfo = studentInfo;
        _totalStudents = uniqueStudents;
        _completedSessions = completed;
        _upcomingSessions = upcoming;
        _counselorName = fullName.isNotEmpty ? fullName : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _appointments = [];
        _isLoading = false;
        _errorMessage = 'Error loading appointments.';
      });
    }
  }

  Future<int?> _getCounselorIdForUser(String userId) async {
    final result = await Supabase.instance.client
        .from('counselors')
        .select('counselor_id')
        .eq('user_id', userId)
        .maybeSingle();
    return result != null ? result['counselor_id'] as int : null;
  }

  Future<void> _updateAppointmentStatusWithMessage(
      Appointment appt, String newStatus) async {
    String? message;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Change Status to ${newStatus.toUpperCase()}'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Message (optional)',
              hintText: 'Add a reason or note for this status change',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                message = controller.text.trim();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (message == null) return; // Cancelled

    try {
      // Update appointment status
      await Supabase.instance.client
          .from('counseling_appointments')
          .update({'status': newStatus, 'status_message': message}).eq(
              'appointment_id', appt.id);

      // Check if notifications are enabled before sending
      if (await NotificationService.areNotificationsEnabled()) {
        // Send in-app notification
        await Supabase.instance.client.from('user_notifications').insert({
          'user_id': appt.userId,
          'notification_type': 'Appointment Status Update',
          'content':
              'Your appointment on ${appt.appointmentDate.toString().split(' ')[0]} from ${appt.startTime.toString().split(' ')[1].substring(0, 5)} to ${appt.endTime.toString().split(' ')[1].substring(0, 5)} has been changed to ${newStatus.toUpperCase()}. ${message?.isNotEmpty == true ? "Message: $message" : ""}',
          'action_url': '/appointments'
        });

        // Send push notification
        await NotificationService.sendPushNotification(
          userId: appt.userId,
          title: 'Appointment Status Update',
          body: 'Your appointment on ${appt.appointmentDate.toString().split(' ')[0]} from ${appt.startTime.toString().split(' ')[1].substring(0, 5)} to ${appt.endTime.toString().split(' ')[1].substring(0, 5)} has been changed to ${newStatus.toUpperCase()}.',
          data: {
            'action': 'appointment_status_changed',
            'appointment_id': appt.id,
            'route': '/appointments'
          },
        );
      }

      // If status is completed, show session notes dialog
      if (newStatus.toLowerCase() == 'completed') {
        await _showSessionNotesDialog(appt);
      }

      await _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating appointment status')),
        );
      }
    }
  }

  Future<void> _showSessionNotesDialog(Appointment appt) async {
    final summaryController = TextEditingController();
    final topicsController = TextEditingController();
    final recommendationsController = TextEditingController();
    bool? dialogResult;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Session Notes'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: summaryController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Session Summary *',
                    hintText: 'Brief summary of the counseling session',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: topicsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Topics Discussed',
                    hintText: 'Key topics covered during the session',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: recommendationsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Recommendations',
                    hintText: 'Recommendations or next steps for the student',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                dialogResult = false;
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (summaryController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Summary is required')),
                  );
                  return;
                }
                dialogResult = true;
                Navigator.pop(context);
              },
              child: const Text('Save Notes'),
            ),
          ],
        );
      },
    );

    if (dialogResult == true) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw Exception('Not logged in');

        final counselorId = await _getCounselorIdForUser(user.id);
        if (counselorId == null) throw Exception('Counselor profile not found');

        await Supabase.instance.client.from('counseling_session_notes').insert({
          'appointment_id': appt.id,
          'counselor_id': counselorId,
          'student_user_id': appt.userId,
          'summary': summaryController.text.trim(),
          'topics_discussed': topicsController.text.trim(),
          'recommendations': recommendationsController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session notes saved successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error saving session notes')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
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
              // Navigate to full appointments view
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
    final studentCode = studentInfo['student_id'] ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                      const SizedBox(height: 4),
                      
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${appt.appointmentDate.toString().split(' ')[0]} • ${TimeOfDay.fromDateTime(appt.startTime).format(context)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C83FD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentOverview(
                            userId: appt.userId,
                            studentName: studentName,
                            studentId: studentCode,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility,
                          size: 16,
                          color: Color(0xFF7C83FD),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C83FD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _updateAppointmentStatusWithMessage(appt, 'accepted'),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text(
                      'Accept',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _updateAppointmentStatusWithMessage(appt, 'rejected'),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildTodayAppointmentsSection() {
    final today = DateTime.now();
    final todayAppointments = _appointments.where((appt) {
      final apptDate = appt.appointmentDate;
      return apptDate.year == today.year &&
          apptDate.month == today.month &&
          apptDate.day == today.day &&
          appt.status.toLowerCase() == 'accepted';
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 8),
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
                  Text(
                    studentName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  Text(
                    '${TimeOfDay.fromDateTime(appt.startTime).format(context)} - ${TimeOfDay.fromDateTime(appt.endTime).format(context)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentChat(
                          appointment: appt,
                          isCounselor: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: Color(0xFF7C83FD)),
                  tooltip: 'Chat',
                ),
                IconButton(
                  onPressed: () =>
                      _updateAppointmentStatusWithMessage(appt, 'completed'),
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.green),
                  tooltip: 'Mark Complete',
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
                'View All Appointments',
                Icons.calendar_today,
                Colors.blue,
                () {
                  Navigator.pushNamed(context, '/all-appointments');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                'My \nStudents',
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
                Icons.chat_bubble_outline,
                Colors.green,
                () {
                  Navigator.pushNamed(context, '/counselor-chat-list');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                'Video Calls',
                Icons.video_call,
                Colors.orange,
                () {
                  showDialog(
                    context: context,
                    builder: (context) => const VideoCallDialog(),
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

  // Show welcome dialog for first-time counselor
  void _showCounselorWelcomeDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF7C83FD), size: 28),
              const SizedBox(width: 12),
              Text(
                'Welcome, Counselor!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
            ],
          ),
          content: Text(
            'Welcome to BreatheBetter! Let\'s set up your professional profile to help students connect with you effectively. This will only take a few minutes.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              height: 1.4,
              color: const Color(0xFF5D5D72),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(
                    context, '/counselor-profile-first-setup');
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF7C83FD),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
          ],
        ),
      );
    }
  }
}
