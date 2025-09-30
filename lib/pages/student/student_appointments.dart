import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/appointment.dart';
import '../../services/counselor_service.dart';

import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';

import '../call/call.dart'; // Add this import (adjust path if needed)

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

  void _showCallDialog() {
    final callIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Call'),
        content: TextField(
          controller: callIdController,
          decoration: const InputDecoration(
            labelText: 'Enter Call ID',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallPage(callID: callIdController.text),
                ),
              );
            },
            child: const Text('Join Call'),
          ),
        ],
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
          child: const Icon(Icons.call),
          tooltip: 'Join a call',
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

