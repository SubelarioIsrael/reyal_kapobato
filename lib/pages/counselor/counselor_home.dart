import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../../services/counselor_service.dart';
import '../chat/appointment_chat.dart';

class CounselorHome extends StatefulWidget {
  const CounselorHome({super.key});

  @override
  State<CounselorHome> createState() => _CounselorHomeState();
}

class _CounselorHomeState extends State<CounselorHome> {
  final CounselorService _counselorService = CounselorService();
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, Map<String, String>> _studentInfo =
      {}; // user_id -> {username, student_id}

  // Filtering state
  String _selectedDateRange = 'Today';
  final Set<String> _selectedStatuses = {};

  List<String> get _dateRangeOptions => [
        'Today',
        'Tomorrow',
        'Next Week',
        'Next Month',
      ];

  List<String> get _allStatusOptions => [
        'pending',
        'accepted',
        'cancelled',
        'rejected',
        'completed',
        'no_show',
        'rescheduled',
      ];

  List<Appointment> get _filteredAppointments {
    final now = DateTime.now();
    DateTime start, end;
    switch (_selectedDateRange) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;
      case 'Tomorrow':
        start =
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        end = start.add(const Duration(days: 1));
        break;
      case 'Next Week':
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 7));
        break;
      case 'Next Month':
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 30));
        break;
      default:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
    }
    return _appointments.where((appt) {
      final apptDate = appt.appointmentDate;
      final inDateRange =
          apptDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
              apptDate.isBefore(end);
      final statusMatch = _selectedStatuses.isEmpty ||
          _selectedStatuses.contains(appt.status.toLowerCase());
      return inDateRange && statusMatch;
    }).toList();
  }

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
      final counselorId = await _getCounselorIdForUser(user.id);
      if (counselorId == null) {
        setState(() {
          _appointments = [];
          _isLoading = false;
          _errorMessage = 'Counselor profile not set up. Please contact admin.';
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
        final usersResponse = await Supabase.instance.client
            .from('users')
            .select('user_id, username')
            .inFilter('user_id', userIds);
        final studentsResponse = await Supabase.instance.client
            .from('students')
            .select('user_id, student_code')
            .inFilter('user_id', userIds);
        print('usersResponse: $usersResponse');
        print('studentsResponse: $studentsResponse');
        for (var u in usersResponse) {
          studentInfo[u['user_id'].toString().trim()] = {
            'username': u['username'] ?? ''
          };
        }
        for (var s in studentsResponse) {
          final key = s['user_id'].toString().trim();
          if (studentInfo[key] != null) {
            studentInfo[key]!['student_id'] = s['student_code'] ?? '';
          } else {
            studentInfo[key] = {'student_id': s['student_code'] ?? ''};
          }
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

      // Send notification to user
      await Supabase.instance.client.from('user_notifications').insert({
        'user_id': appt.userId,
        'notification_type': 'Appointment Status Update',
        'content':
            'Your appointment on ${appt.appointmentDate.toString().split(' ')[0]} from ${appt.startTime.toString().split(' ')[1].substring(0, 5)} to ${appt.endTime.toString().split(' ')[1].substring(0, 5)} has been changed to ${newStatus.toUpperCase()}. ${message?.isNotEmpty == true ? "Message: $message" : ""}',
        'action_url': '/appointments'
      });

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

  void _showRescheduleDialog(Appointment appt) {
    TimeOfDay? newStart;
    TimeOfDay? newEnd;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reschedule Appointment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(newStart == null
                        ? 'Select new start time'
                        : newStart!.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(appt.startTime),
                      );
                      if (picked != null) setState(() => newStart = picked);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(newEnd == null
                        ? 'Select new end time'
                        : newEnd!.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(appt.endTime),
                      );
                      if (picked != null) setState(() => newEnd = picked);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (newStart == null || newEnd == null) return;
                    final date = appt.appointmentDate;
                    final startDateTime = DateTime(date.year, date.month,
                        date.day, newStart!.hour, newStart!.minute);
                    final endDateTime = DateTime(date.year, date.month,
                        date.day, newEnd!.hour, newEnd!.minute);
                    await Supabase.instance.client
                        .from('counseling_appointments')
                        .update({
                      'start_time':
                          '${newStart!.hour.toString().padLeft(2, '0')}:${newStart!.minute.toString().padLeft(2, '0')}:00',
                      'end_time':
                          '${newEnd!.hour.toString().padLeft(2, '0')}:${newEnd!.minute.toString().padLeft(2, '0')}:00',
                      'status': 'rescheduled',
                    }).eq('appointment_id', appt.id);
                    Navigator.pop(context);
                    await _loadAppointments();
                  },
                  child: const Text('Reschedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  final List<String> statusOptions = [
    'accepted',
    'cancelled',
    'rejected',
    'completed',
    'no_show',
    'rescheduled',
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'rejected':
      case 'no_show':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counselor Home'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF7C83FD)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_circle, size: 80, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Counselor',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, 'counselor-settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FILTER UI
                      Row(
                        children: [
                          // Date Range Dropdown
                          DropdownButton<String>(
                            value: _selectedDateRange,
                            items: _dateRangeOptions
                                .map((option) => DropdownMenuItem(
                                      value: option,
                                      child: Text(option),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDateRange = val);
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          // Status Filter Chips
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _allStatusOptions.map((status) {
                                  final selected =
                                      _selectedStatuses.contains(status);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2.0),
                                    child: FilterChip(
                                      label: Text(status.toUpperCase()),
                                      selected: selected,
                                      onSelected: (val) {
                                        setState(() {
                                          if (val) {
                                            _selectedStatuses.add(status);
                                          } else {
                                            _selectedStatuses.remove(status);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Pending Requests Section
                      const Text(
                        'Pending Requests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final pendingAppointments = _appointments
                              .where((a) => a.status.toLowerCase() == 'pending')
                              .toList();
                          if (pendingAppointments.isEmpty) {
                            return const Text(
                              'No pending requests.',
                              style: TextStyle(color: Colors.grey),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pendingAppointments.length,
                            itemBuilder: (context, index) {
                              final appt = pendingAppointments[index];
                              final studentInfo = _studentInfo[appt.userId.toString().trim()] ?? {};
                              final username = studentInfo['username'] ?? 'Unknown';
                              final studentId = studentInfo['student_id'] ?? '';
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  username.isNotEmpty
                                                      ? username[0].toUpperCase() + username.substring(1)
                                                      : 'Unknown',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (studentId.isNotEmpty)
                                                  Text(
                                                    'Student ID: $studentId',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.check_circle, color: Colors.green),
                                            tooltip: 'Accept',
                                            onPressed: () => _updateAppointmentStatusWithMessage(appt, 'accepted'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel, color: Colors.red),
                                            tooltip: 'Reject',
                                            onPressed: () => _updateAppointmentStatusWithMessage(appt, 'rejected'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.visibility),
                                            tooltip: 'View',
                                            onPressed: () {
                                              // Optionally show more details or history
                                              Navigator.pushNamed(
                                                context,
                                                '/student-history',
                                                arguments: {
                                                  'userId': appt.userId,
                                                  'username': username,
                                                  'studentId': studentId,
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Date: ${appt.appointmentDate.toString().split(' ')[0]}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        'Time: ' +
                                            TimeOfDay(
                                                    hour: appt.startTime.hour,
                                                    minute: appt.startTime.minute)
                                                .format(context) +
                                            ' - ' +
                                            TimeOfDay(
                                                    hour: appt.endTime.hour, minute: appt.endTime.minute)
                                                .format(context),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Appointments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _filteredAppointments.isEmpty
                            ? const Center(
                                child: Text('No appointments found.'))
                            : ListView.builder(
                                itemCount: _filteredAppointments.length,
                                itemBuilder: (context, index) {
                                  final appt = _filteredAppointments[index];
                                  print(
                                      'appt.userId: \'${appt.userId.toString().trim()}\'');
                                  return _buildAppointmentCard(appt);
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appt) {
    final studentInfo = _studentInfo[appt.userId.toString().trim()] ?? {};
    final username = studentInfo['username'] ?? 'Unknown';
    final studentId = studentInfo['student_id'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username.isNotEmpty
                            ? username[0].toUpperCase() + username.substring(1)
                            : 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (studentId.isNotEmpty)
                        Text(
                          'Student ID: $studentId',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                if (appt.status.toLowerCase() == 'accepted')
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
                    icon: const Icon(Icons.chat_bubble_outline),
                    color: const Color(0xFF5D5D72),
                    tooltip: 'Chat with student',
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'accept':
                        _updateAppointmentStatusWithMessage(appt, 'accepted');
                        break;
                      case 'reject':
                        _updateAppointmentStatusWithMessage(appt, 'rejected');
                        break;
                      case 'complete':
                        _updateAppointmentStatusWithMessage(appt, 'completed');
                        break;
                      case 'no_show':
                        _updateAppointmentStatusWithMessage(appt, 'no_show');
                        break;
                      case 'reschedule':
                        _showRescheduleDialog(appt);
                        break;
                      case 'view_history':
                        Navigator.pushNamed(
                          context,
                          '/student-history',
                          arguments: {
                            'userId': appt.userId,
                            'username': username,
                            'studentId': studentId,
                          },
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (appt.status.toLowerCase() == 'pending')
                      const PopupMenuItem(
                        value: 'accept',
                        child: Text('Accept'),
                      ),
                    if (appt.status.toLowerCase() == 'pending')
                      const PopupMenuItem(
                        value: 'reject',
                        child: Text('Reject'),
                      ),
                    if (appt.status.toLowerCase() == 'accepted')
                      const PopupMenuItem(
                        value: 'complete',
                        child: Text('Mark as Completed'),
                      ),
                    if (appt.status.toLowerCase() == 'accepted')
                      const PopupMenuItem(
                        value: 'no_show',
                        child: Text('Mark as No Show'),
                      ),
                    if (appt.status.toLowerCase() == 'accepted')
                      const PopupMenuItem(
                        value: 'reschedule',
                        child: Text('Reschedule'),
                      ),
                    PopupMenuItem(
                      value: 'view_history',
                      child: Row(
                        children: [
                          const Icon(Icons.history),
                          const SizedBox(width: 8),
                          const Text('View History'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${appt.appointmentDate.toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Time: ' +
                  TimeOfDay(
                          hour: appt.startTime.hour,
                          minute: appt.startTime.minute)
                      .format(context) +
                  ' - ' +
                  TimeOfDay(
                          hour: appt.endTime.hour, minute: appt.endTime.minute)
                      .format(context),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(appt.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                appt.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(appt.status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
