import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../../controllers/student_appointments_controller.dart';
import '../../widgets/counselor_avatar.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../components/video_call_dialog.dart';

class StudentAppointments extends StatefulWidget {
  const StudentAppointments({super.key});

  @override
  State<StudentAppointments> createState() => _StudentAppointmentsState();
}

class _StudentAppointmentsState extends State<StudentAppointments> {
  final StudentAppointmentsController _controller = StudentAppointmentsController();
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  RealtimeChannel? _appointmentsChannel;

  // Filtering state
  String _selectedDateRange = 'All Appointments';
  String _selectedStatus = 'All Statuses';

  List<String> get _dateRangeOptions => [
        'All Appointments',
        'Today',
        'Tomorrow',
        'This Week',
        'Next Week',
        'This Month',
        'Next Month',
      ];

  List<String> get _statusOptions => [
        'All Statuses',
        'Pending',
        'Accepted',
        'Cancelled',
        'Rejected',
        'Completed',
        'No Show',
        'Rescheduled',
      ];

  List<Appointment> get _filteredAppointments {
    final now = DateTime.now();
    DateTime? startFilter, endFilter;

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
            .subtract(Duration(days: now.weekday - 1));
        endFilter = startFilter.add(const Duration(days: 7));
        break;
      case 'Next Week':
        startFilter = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1))
            .add(const Duration(days: 7));
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
        break;
    }

    return _appointments.where((appt) {
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

      final statusMatch = _selectedStatus == 'All Statuses' ||
          _selectedStatus.toLowerCase() == appt.status.toLowerCase() ||
          (_selectedStatus == 'No Show' && appt.status.toLowerCase() == 'no_show');

      return inDateRange && statusMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      _appointmentsChannel = supabase
          .channel('student_appointments_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'counseling_appointments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              if (mounted) {
                _loadAppointments();
              }
            },
          )
          .subscribe();
    }
  }

  @override
  void dispose() {
    _appointmentsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    
    final result = await _controller.loadAppointments();
    
    if (result.success) {
      final appointments = result.appointments;
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
        return dateTimeB.compareTo(dateTimeA);
      });

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        _showAlertDialog(
          'Error',
          result.errorMessage ?? 'Failed to load appointments',
          Icons.error_outline,
          Colors.red,
        );
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final result = await _controller.cancelAppointment(
      appointment.id,
      'Cancelled by student',
    );
    
    if (result.success) {
      await _loadAppointments();
      if (mounted) {
        _showAlertDialog(
          'Success',
          'Appointment cancelled successfully',
          Icons.check_circle_outline,
          Colors.green,
        );
      }
    } else {
      if (mounted) {
        _showAlertDialog(
          'Error',
          result.errorMessage ?? 'Failed to cancel appointment',
          Icons.error_outline,
          Colors.red,
        );
      }
    }
  }

  void _showCancelConfirmation(Appointment appointment) {
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cancel Appointment',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to cancel this appointment?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'No',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5D5D72),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _cancelAppointment(appointment);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Yes, Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
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

  void _showAlertDialog(String title, String message, IconData icon, Color color) {
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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

  void _showVideoCallDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VideoCallDialog(userRole: 'student'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5D5D72)),
          onPressed: () {
            Navigator.pushReplacementNamed(context, 'student-home');
          },
        ),
        title: Text(
          "Appointments",
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
              const SizedBox(height: 8),
              
              // FILTER UI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Appointments',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date Range:',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedDateRange,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: _dateRangeOptions
                                      .map((option) => DropdownMenuItem(
                                            value: option,
                                            child: Text(
                                              option,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: const Color(0xFF3A3A50),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedDateRange = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status:',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedStatus,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: _statusOptions
                                      .map((option) => DropdownMenuItem(
                                            value: option,
                                            child: Text(
                                              option,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: const Color(0xFF3A3A50),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedStatus = val);
                                    }
                                  },
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
              const SizedBox(height: 24),
              
              if (_isLoading)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C83FD)),
                      ),
                    ),
                  ),
                )
              else if (_filteredAppointments.isEmpty)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C83FD).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.event_note,
                              size: 48,
                              color: Color(0xFF7C83FD),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _selectedDateRange == 'All Appointments'
                                ? 'No appointments yet'
                                : 'No appointments found',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedDateRange == 'All Appointments'
                                ? 'Book your first appointment with a counselor'
                                : 'Try adjusting your filters or date range',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_selectedDateRange == 'All Appointments') ...[
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/student-counselors');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C83FD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Book Appointment',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_filteredAppointments.length} appointment${_filteredAppointments.length != 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Sorted by date',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _filteredAppointments[index];
                            return _AppointmentCard(
                              appointment: appointment,
                              onCancel: () => _showCancelConfirmation(appointment),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showVideoCallDialog,
        backgroundColor: const Color(0xFF7C83FD),
        tooltip: 'Join a video call',
        child: const Icon(Icons.video_call),
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
          children: [
            Row(
              children: [
                CounselorAvatar(
                  counselorId: widget.appointment.counselorId,
                  radius: 30,
                  fallbackName: widget.appointment.counselorName,
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (widget.appointment.counselorName ?? '').isNotEmpty
                                  ? widget.appointment.counselorName![0].toUpperCase() +
                                      widget.appointment.counselorName!.substring(1)
                                  : 'Unknown Counselor',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3A3A50),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.appointment.status.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.appointment.appointmentDate.day}/${widget.appointment.appointmentDate.month}/${widget.appointment.appointmentDate.year}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${TimeOfDay(hour: widget.appointment.startTime.hour, minute: widget.appointment.startTime.minute).format(context)} - ${TimeOfDay(hour: widget.appointment.endTime.hour, minute: widget.appointment.endTime.minute).format(context)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.appointment.status.toLowerCase() == 'pending' ||
                                  widget.appointment.status.toLowerCase() == 'accepted')
                                TextButton(
                                  onPressed: widget.onCancel,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'CANCEL',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
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
}
