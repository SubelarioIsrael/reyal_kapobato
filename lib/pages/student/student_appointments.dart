import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../../services/counselor_service.dart';

import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';

import '../call/call.dart';

class StudentAppointments extends StatefulWidget {
  const StudentAppointments({super.key});

  @override
  State<StudentAppointments> createState() => _StudentAppointmentsState();
}

class _StudentAppointmentsState extends State<StudentAppointments> {
  final CounselorService _counselorService = CounselorService();
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  // Filtering state
  String _selectedDateRange = 'All Appointments'; // Default to show all
  final Set<String> _selectedStatuses = {};

  List<String> get _dateRangeOptions => [
        'All Appointments',
        'Today',
        'Tomorrow',
        'This Week',
        'Next Week',
        'This Month',
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
    DateTime? startFilter, endFilter;

    // Determine date range filters
    switch (_selectedDateRange) {
      case 'Today':
        startFilter = DateTime(now.year, now.month, now.day);
        endFilter = startFilter.add(const Duration(days: 1));
        break;
      case 'Tomorrow':
        startFilter =
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        endFilter = startFilter.add(const Duration(days: 1));
        break;
      case 'This Week':
        startFilter = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1)); // Monday
        endFilter = startFilter.add(const Duration(days: 7));
        break;
      case 'Next Week':
        startFilter = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1))
            .add(const Duration(days: 7)); // Next Monday
        endFilter = startFilter.add(const Duration(days: 7));
        break;
      case 'This Month':
        startFilter = DateTime(now.year, now.month, 1);
        endFilter = DateTime(now.year, now.month + 1, 1);
        break;
      case 'Next Month':
        startFilter = DateTime(now.year, now.month + 1, 1);
        endFilter = DateTime(now.year, now.month + 2, 1);
        break;
      case 'All Appointments':
      default:
        // No date filter applied
        break;
    }

    return _appointments.where((appt) {
      // Date range filtering
      bool inDateRange = true;
      if (startFilter != null && endFilter != null) {
        final apptDateTime = DateTime(
          appt.appointmentDate.year,
          appt.appointmentDate.month,
          appt.appointmentDate.day,
          appt.startTime.hour,
          appt.startTime.minute,
        );
        inDateRange = apptDateTime
                .isAfter(startFilter.subtract(const Duration(seconds: 1))) &&
            apptDateTime.isBefore(endFilter);
      }

      // Status filtering
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
    try {
      final appointments = await _counselorService.getUserAppointments();
      // Sort appointments by date and time
      appointments.sort((a, b) {
        final DateTime dateTimeA = DateTime(
          a.appointmentDate.year,
          a.appointmentDate.month,
          a.appointmentDate.day,
          a.startTime.hour,
          a.startTime.minute,
        );
        final DateTime dateTimeB = DateTime(
          b.appointmentDate.year,
          b.appointmentDate.month,
          b.appointmentDate.day,
          b.startTime.hour,
          b.startTime.minute,
        );
        return dateTimeA.compareTo(dateTimeB);
      });

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading appointments')),
        );
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    try {
      await _counselorService.cancelAppointment(appointment.id);
      await _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error cancelling appointment')),
        );
      }
    }
  }

  void _showCancelConfirmation(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Appointment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A3A50),
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this appointment?',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment(appointment);
            },
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF5D5D72),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCallDialog() {
    final callIdController = TextEditingController();
    bool isJoiningCall = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF81C784).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.video_call, 
                color: Color(0xFF81C784), 
                size: 28
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join Video Call',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter the call code from your counselor',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Call Code',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: callIdController,
              decoration: InputDecoration(
                hintText: 'abc-def-ghi',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF81C784), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: Icon(
                  Icons.code,
                  color: Colors.grey.shade600,
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF81C784).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF81C784).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF81C784),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enter the 3-segment code shared by your counselor',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF5D5D72),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF5D5D72),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
            onPressed: isJoiningCall ? null : () async {
              setState(() {
                isJoiningCall = true;
              });
              final callCode = callIdController.text.trim();
              if (callCode.isEmpty) {
                if (mounted) {
                  _showErrorDialog('Missing Call Code', 'Please enter a call code to join the video call.');
                }
                setState(() {
                  isJoiningCall = false;
                });
                return;
              }
              
              // Get current user information
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                try {
                  // Normalize the call code (trim and convert to lowercase)
                  final normalizedCallCode = callCode.toLowerCase().trim();
                  
                  // Basic format validation (should be like "abc-def-ghi")
                  if (!RegExp(r'^[a-z]{3}-[a-z]{3}-[a-z]{3}$').hasMatch(normalizedCallCode)) {
                    if (mounted) {
                      _showErrorDialog('Invalid Format', 'Please use the correct format: abc-def-ghi\n(3 letters, dash, 3 letters, dash, 3 letters)');
                    }
                    setState(() {
                      isJoiningCall = false;
                    });
                    return;
                  }
                  
                  print('Student searching for call code: $normalizedCallCode');
                  
                  // Check if call code exists and is active
                  print('Querying database for call code: $normalizedCallCode');
                  print('User ID: ${user.id}');
                  print('User email: ${user.email}');
                  
                  // Try the regular query first
                  var existingCall = await Supabase.instance.client
                      .from('video_calls')
                      .select()
                      .eq('call_code', normalizedCallCode)
                      .eq('status', 'active')
                      .maybeSingle();

                  print('Found call with status filter: $existingCall');
                  
                  // If null, try using RPC function (if RLS is blocking access)
                  if (existingCall == null) {
                    try {
                      final rpcResult = await Supabase.instance.client
                          .rpc('find_active_video_call', params: {
                        'call_code_param': normalizedCallCode
                      });
                      print('RPC result: $rpcResult');
                      if (rpcResult != null && rpcResult.isNotEmpty) {
                        existingCall = rpcResult[0];
                      }
                    } catch (rpcError) {
                      print('RPC function not available: $rpcError');
                      // Continue with normal flow
                    }
                  }

                  if (existingCall == null) {
                    // Try to find the call without status filter to debug
                    print('Trying to find call without status filter...');
                    final anyCall = await Supabase.instance.client
                        .from('video_calls')
                        .select()
                        .eq('call_code', normalizedCallCode)
                        .maybeSingle();
                    
                    print('Found call without status filter: $anyCall');
                    
                    // Try to access any records from video_calls table to test permissions
                    try {
                      final testQuery = await Supabase.instance.client
                          .from('video_calls')
                          .select('call_code, status')
                          .limit(1);
                      print('Test query result (checking table access): $testQuery');
                    } catch (e) {
                      print('Error accessing video_calls table: $e');
                    }
                    
                    String errorMessage = 'Call code does not exist or has expired';
                    if (anyCall != null) {
                      errorMessage = 'Call code exists but is not active (Status: ${anyCall['status']})';
                    } else {
                      errorMessage = 'Call code not found. This might be due to permissions or the code may not exist.';
                    }
                    
                    if (mounted) {
                      _showErrorDialog('Call Code Not Found', errorMessage);
                    }
                    setState(() {
                      isJoiningCall = false;
                    });
                    return;
                  }

                  // Update the call to include student information
                  await Supabase.instance.client
                      .from('video_calls')
                      .update({
                        'student_user_id': user.id,
                        'student_joined_at': DateTime.now().toIso8601String(),
                      })
                      .eq('call_code', normalizedCallCode);

                  // Try to get student info for display name
                  String userName = user.email ?? 'Student';
                  final studentData = await Supabase.instance.client
                      .from('students')
                      .select('first_name, last_name')
                      .eq('user_id', user.id)
                      .maybeSingle();
                  
                  if (studentData != null && 
                      studentData['first_name'] != null && 
                      studentData['last_name'] != null) {
                    userName = '${studentData['first_name']} ${studentData['last_name']}';
                  }
                  
                  // Close dialog first, then navigate
                  Navigator.pop(context);
                  
                  // Join the video call
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallPage(
                          callID: normalizedCallCode,
                          userID: user.id,
                          userName: userName,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  // Check if widget is still mounted before showing SnackBar
                  if (mounted) {
                    _showErrorDialog('Connection Error', 'Unable to join the call. Please check your internet connection and try again.');
                  }
                  setState(() {
                    isJoiningCall = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81C784),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: isJoiningCall
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Joining...',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.video_call, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Join Call',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
              ),
            ],
          ),
        ],
      ),
        ),
    );
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
          actions: const [
            StudentNotificationButton(),
          ],

        ),
        drawer: const StudentDrawer(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
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
                    const SizedBox(height: 0), // Adjusted spacing
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_filteredAppointments.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No appointments yet',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Book an appointment with a counselor',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _filteredAppointments[index];
                            return _AppointmentCard(
                              appointment: appointment,
                              onCancel: () =>
                                  _showCancelConfirmation(appointment),
                            );
                          },
                        ),
                      ),
                ],
              ),
            ),
          ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCallDialog,
          backgroundColor: const Color(0xFF81C784),
          child: const Icon(Icons.video_call),
          tooltip: 'Join a video call',
        ),
    );
  }
}

class _AppointmentCard extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.onCancel,
  });

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard> {
  Color _getStatusColor() {
    switch (widget.appointment.status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.appointment.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
                const Spacer(),

                if (widget.appointment.status.toLowerCase() == 'pending' ||
                    widget.appointment.status.toLowerCase() == 'accepted')
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    color: Colors.red,
                    tooltip: 'Cancel appointment',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (widget.appointment.counselorName ?? '').isNotEmpty
                  ? widget.appointment.counselorName![0].toUpperCase() +
                      widget.appointment.counselorName!.substring(1)
                  : '',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            Text(
              'Date: ${widget.appointment.appointmentDate.day}/${widget.appointment.appointmentDate.month}/${widget.appointment.appointmentDate.year}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            Text(
              'Time: ' +
                  TimeOfDay(
                          hour: widget.appointment.startTime.hour,
                          minute: widget.appointment.startTime.minute)
                      .format(context) +
                  ' - ' +
                  TimeOfDay(
                          hour: widget.appointment.endTime.hour,
                          minute: widget.appointment.endTime.minute)
                      .format(context),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

