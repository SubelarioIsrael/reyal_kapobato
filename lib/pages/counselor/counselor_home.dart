import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../../services/counselor_service.dart';

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
      await Supabase.instance.client
          .from('counseling_appointments')
          .update({'status': newStatus, 'status_message': message}).eq(
              'appointment_id', appt.id);
      await _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating appointment status')),
        );
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
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _studentInfo[appt.userId
                                                                .toString()
                                                                .trim()]
                                                            ?['username'] ??
                                                        'Unknown',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if ((_studentInfo[appt.userId
                                                                  .toString()
                                                                  .trim()]
                                                              ?['student_id'] ??
                                                          '')
                                                      .isNotEmpty)
                                                    Text(
                                                      'Student ID: ${_studentInfo[appt.userId.toString().trim()]?['student_id']}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(
                                                        Icons.more_vert),
                                                    onSelected: (value) {
                                                      if (value ==
                                                          'view_history') {
                                                        Navigator.pushNamed(
                                                          context,
                                                          '/student-history',
                                                          arguments: {
                                                            'userId':
                                                                appt.userId,
                                                            'username': _studentInfo[appt
                                                                        .userId
                                                                        .toString()
                                                                        .trim()]
                                                                    ?[
                                                                    'username'] ??
                                                                'Unknown',
                                                            'studentId': _studentInfo[appt
                                                                        .userId
                                                                        .toString()
                                                                        .trim()]
                                                                    ?[
                                                                    'student_id'] ??
                                                                '',
                                                          },
                                                        );
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(
                                                        value: 'view_history',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.history),
                                                            SizedBox(width: 8),
                                                            Text(
                                                                'View History'),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Chip(
                                                    label: Text(appt.status
                                                        .toUpperCase()),
                                                    backgroundColor:
                                                        Colors.blue.shade50,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                              'Date: ${appt.appointmentDate.day}/${appt.appointmentDate.month}/${appt.appointmentDate.year}'),
                                          Text(
                                              'Time: ${appt.startTime.hour.toString().padLeft(2, '0')}:${appt.startTime.minute.toString().padLeft(2, '0')} - ${appt.endTime.hour.toString().padLeft(2, '0')}:${appt.endTime.minute.toString().padLeft(2, '0')}'),
                                          if (appt.notes != null &&
                                              appt.notes!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text('Notes: ${appt.notes!}'),
                                          ],
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            children:
                                                statusOptions.map((status) {
                                              if (status == 'rescheduled') {
                                                return ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        appt.status == status
                                                            ? Colors.blue
                                                            : Colors
                                                                .grey.shade200,
                                                    foregroundColor:
                                                        appt.status == status
                                                            ? Colors.white
                                                            : Colors.black,
                                                  ),
                                                  onPressed: appt.status ==
                                                          status
                                                      ? null
                                                      : () =>
                                                          _showRescheduleDialog(
                                                              appt),
                                                  child:
                                                      const Text('RESCHEDULE'),
                                                );
                                              }
                                              return ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      appt.status == status
                                                          ? Colors.blue
                                                          : Colors
                                                              .grey.shade200,
                                                  foregroundColor:
                                                      appt.status == status
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                                onPressed: appt.status == status
                                                    ? null
                                                    : () =>
                                                        _updateAppointmentStatusWithMessage(
                                                            appt, status),
                                                child: Text(status
                                                    .replaceAll('_', ' ')
                                                    .toUpperCase()),
                                              );
                                            }).toList(),
                                          ),
                                          if (appt.statusMessage != null &&
                                              appt.statusMessage!
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Status Message: ${appt.statusMessage!}',
                                              style: const TextStyle(
                                                  color: Colors.deepPurple),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
