import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../../services/counselor_service.dart';
import '../chat/appointment_chat.dart';
import 'video_call_dialog.dart';
import 'student_overview.dart';

class AllAppointments extends StatefulWidget {
  const AllAppointments({super.key});

  @override
  State<AllAppointments> createState() => _AllAppointmentsState();
}

class _AllAppointmentsState extends State<AllAppointments> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, Map<String, String>> _studentInfo = {};
  String _selectedFilter = 'all'; // all, pending, accepted, completed, rejected

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

      // Get counselor ID
      final counselorProfile = await Supabase.instance.client
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', user.id)
          .single();

      final counselorId = counselorProfile['counselor_id'] as int;

      // Load appointments
      final response = await Supabase.instance.client
          .from('counseling_appointments')
          .select()
          .eq('counselor_id', counselorId)
          .order('appointment_date', ascending: false);

      final appointments =
          (response as List).map((json) => Appointment.fromJson(json)).toList();

      // Fetch student info
      final userIds =
          appointments.map((a) => a.userId.toString().trim()).toSet().toList();
      Map<String, Map<String, String>> studentInfo = {};

      if (userIds.isNotEmpty) {
        final studentsResponse = await Supabase.instance.client
            .from('students')
            .select('user_id, student_code, first_name, last_name')
            .inFilter('user_id', userIds);

        for (var s in studentsResponse) {
          final key = s['user_id'].toString().trim();
          final firstName = s['first_name'] ?? '';
          final lastName = s['last_name'] ?? '';
          final fullName = '$firstName $lastName'.trim();
          studentInfo[key] = {
            'student_code': s['student_code'] ?? '',
            'first_name': firstName,
            'last_name': lastName,
            'student_name': fullName.isNotEmpty ? fullName : 'Unknown Student'
          };
        }
      }

      setState(() {
        _appointments = appointments;
        _studentInfo = studentInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _appointments = [];
        _isLoading = false;
        _errorMessage = 'Error loading appointments: $e';
      });
    }
  }

  List<Appointment> get _filteredAppointments {
    if (_selectedFilter == 'all') return _appointments;
    return _appointments
        .where((appt) => appt.status.toLowerCase() == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Appointments',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7C83FD),
        onPressed: () => _showVideoCallDialog(),
        child: const Icon(Icons.video_call, color: Colors.white),
        tooltip: 'Start Video Call',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    _buildFilterTabs(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadAppointments,
                        child: _filteredAppointments.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredAppointments.length,
                                itemBuilder: (context, index) {
                                  final appointment =
                                      _filteredAppointments[index];
                                  return _buildAppointmentCard(appointment);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'accepted', 'label': 'Accepted'},
      {'key': 'completed', 'label': 'Completed'},
      {'key': 'rejected', 'label': 'Rejected'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  filter['label']!,
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : const Color(0xFF5D5D72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF7C83FD),
                backgroundColor: Colors.white,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter['key']!;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'You don\'t have any appointments yet'
                : 'No ${_selectedFilter} appointments',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final studentInfo =
        _studentInfo[appointment.userId.toString().trim()] ?? {};
    final firstName = studentInfo['first_name'] ?? '';
    final lastName = studentInfo['last_name'] ?? '';
    final studentName = '$firstName $lastName'.trim();
    final displayName = studentName.isNotEmpty
        ? studentName
        : studentInfo['student_name'] ?? 'Unknown Student';
    final studentCode = studentInfo['student_code'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.person,
                    color: _getStatusColor(appointment.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      if (studentCode.isNotEmpty)
                        Text(
                          'ID: $studentCode',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF5D5D72),
                          ),
                        ),
                      Text(
                        '${appointment.appointmentDate.toString().split(' ')[0]} • ${TimeOfDay.fromDateTime(appointment.startTime).format(context)} - ${TimeOfDay.fromDateTime(appointment.endTime).format(context)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Notes: ${appointment.notes}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentOverview(
                            userId: appointment.userId,
                            studentName: displayName,
                            studentId: studentCode,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person, size: 16),
                    label: Text(
                      'Overview',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C83FD),
                      side: const BorderSide(color: Color(0xFF7C83FD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentChat(
                            appointment: appointment,
                            isCounselor: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: Text(
                      'Chat',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C83FD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (String value) => _updateAppointmentStatus(appointment, value),
                  icon: const Icon(Icons.more_vert, color: Color(0xFF5D5D72)),
                  tooltip: 'Update Status',
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    if (appointment.status.toLowerCase() != 'completed')
                      const PopupMenuItem<String>(
                        value: 'completed',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Mark as Completed'),
                          ],
                        ),
                      ),
                    if (appointment.status.toLowerCase() != 'cancelled')
                      const PopupMenuItem<String>(
                        value: 'cancelled',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Mark as Cancelled'),
                          ],
                        ),
                      ),
                    if (appointment.status.toLowerCase() == 'pending')
                      const PopupMenuItem<String>(
                        value: 'accepted',
                        child: Row(
                          children: [
                            Icon(Icons.check, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('Accept Appointment'),
                          ],
                        ),
                      ),
                    if (appointment.status.toLowerCase() == 'pending')
                      const PopupMenuItem<String>(
                        value: 'rejected',
                        child: Row(
                          children: [
                            Icon(Icons.close, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text('Reject Appointment'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      default:
        return Colors.grey;
    }
  }

  void _showVideoCallDialog() {
    showDialog(
      context: context,
      builder: (context) => const VideoCallDialog(),
    );
  }

  Future<void> _updateAppointmentStatus(Appointment appointment, String newStatus) async {
    // Show confirmation dialog with optional message
    String? statusMessage;
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (context) {
        final messageController = TextEditingController();
        return AlertDialog(
          title: Text('Update Status to ${newStatus.toUpperCase()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to mark this appointment as $newStatus?'),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  hintText: 'Add a note for this status change',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                statusMessage = messageController.text.trim();
                confirmed = true;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(newStatus),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (!confirmed) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Update appointment status using the service
      final counselorService = CounselorService();
      await counselorService.updateAppointmentStatus(
        appointment.id,
        newStatus,
        statusMessage: statusMessage,
      );

      // Send notification to student
      await _sendStatusUpdateNotification(appointment, newStatus, statusMessage);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload appointments to reflect changes
      await _loadAppointments();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating appointment status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendStatusUpdateNotification(Appointment appointment, String newStatus, String? message) async {
    try {
      // Create notification content
      final notificationContent = 'Your appointment on ${appointment.appointmentDate.toString().split(' ')[0]} has been ${newStatus.toUpperCase()}.'
          '${message != null && message.isNotEmpty ? ' Message: $message' : ''}';

      // Insert notification into database
      await Supabase.instance.client.from('user_notifications').insert({
        'user_id': appointment.userId,
        'notification_type': 'Appointment Status Update',
        'content': notificationContent,
        'action_url': '/appointments'
      });

      // Try to send push notification via Edge Function
      try {
        await Supabase.instance.client.functions.invoke(
          'send-notification',
          body: {
            'user_id': appointment.userId,
            'title': 'Appointment Status Update',
            'body': notificationContent,
            'data': {
              'action': 'appointment_status_changed',
              'appointment_id': appointment.id,
              'route': '/appointments'
            }
          },
        );
      } catch (pushError) {
        print('Push notification failed: $pushError');
        // Continue even if push notification fails
      }
    } catch (e) {
      print('Error sending notification: $e');
      // Don't throw error - notification failure shouldn't block status update
    }
  }
}
