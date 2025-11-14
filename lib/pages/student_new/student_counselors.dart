import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/counselor.dart';
import '../../controllers/student_counselors_controller.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../widgets/counselor_avatar.dart';
import '../student/counselor_profile_view.dart';

class StudentCounselors extends StatefulWidget {
  const StudentCounselors({super.key});

  @override
  State<StudentCounselors> createState() => _StudentCounselorsState();
}

class _StudentCounselorsState extends State<StudentCounselors> {
  final StudentCounselorsController _controller = StudentCounselorsController();
  List<Counselor> _departmentCounselors = [];
  List<Counselor> _volunteerCounselors = [];
  bool _isLoading = true;
  String? _studentDepartment;

  @override
  void initState() {
    super.initState();
    _loadCounselors();
  }

  Future<void> _loadCounselors() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _controller.loadCounselors();
      final departmentName = result['department_name'] as List<Counselor>?;
      
      setState(() {
        _departmentCounselors = result['department'] as List<Counselor>? ?? [];
        _volunteerCounselors = result['volunteer'] as List<Counselor>? ?? [];
        _studentDepartment = departmentName?.isNotEmpty == true
            ? departmentName!.first.firstName
            : null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading counselors: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showAlertDialog(
          'Error',
          'Failed to load counselors',
          Icons.error_outline,
          Colors.red,
        );
      }
    }
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

  void _showBookAppointmentDialog(Counselor counselor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppointmentBookingDialog(counselor: counselor),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Counselors",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: [
          const StudentNotificationButton(),
        ],
      ),
      drawer: const StudentDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 0),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_departmentCounselors.isEmpty && _volunteerCounselors.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Counselors Available',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _studentDepartment != null
                              ? 'There are currently no counselors available for $_studentDepartment. Please check back later or contact the administrator for assistance.'
                              : 'There are currently no counselors registered in the system. Please check back later or contact the administrator for assistance.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C83FD),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: Text(
                          'Go Back',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      // Department Counselors Section
                      if (_departmentCounselors.isNotEmpty) ...[
                        Text(
                          _studentDepartment ?? 'Department Counselors',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Counselors assigned to your department',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(_departmentCounselors.map((counselor) => _buildCounselorCard(counselor))),
                        const SizedBox(height: 24),
                      ],
                      
                      // Volunteer Counselors Section
                      if (_volunteerCounselors.isNotEmpty) ...[
                        Text(
                          'Volunteer Counselors',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Available for all students',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(_volunteerCounselors.map((counselor) => _buildCounselorCard(counselor))),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounselorCard(Counselor counselor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: () => _showBookAppointmentDialog(counselor),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CounselorAvatar(
                      counselorId: counselor.id,
                      fallbackName: '${counselor.firstName} ${counselor.lastName}',
                      radius: 30,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${counselor.firstName} ${counselor.lastName}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF7C83FD),
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CounselorProfileView(
                              counselorId: counselor.id,
                            ),
                          ),
                        );
                      },
                      tooltip: 'View Profile',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppointmentBookingDialog extends StatefulWidget {
  final Counselor counselor;

  const AppointmentBookingDialog({
    super.key,
    required this.counselor,
  });

  @override
  State<AppointmentBookingDialog> createState() =>
      _AppointmentBookingDialogState();
}

class _AppointmentBookingDialogState extends State<AppointmentBookingDialog> {
  final StudentCounselorsController _controller = StudentCounselorsController();
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isSubmitting = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
          final endHour = (picked.hour + 1) % 24;
          _selectedEndTime = TimeOfDay(hour: endHour, minute: picked.minute);
        } else {
          _selectedEndTime = picked;
          final startHour = (picked.hour - 1 + 24) % 24;
          _selectedStartTime =
              TimeOfDay(hour: startHour, minute: picked.minute);
        }
      });
    }
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

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null ||
        _selectedStartTime == null ||
        _selectedEndTime == null) {
      _showAlertDialog(
        'Missing Information',
        'Please select date and time',
        Icons.warning_amber_rounded,
        Colors.orange,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );

      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedEndTime!.hour,
        _selectedEndTime!.minute,
      );

      // Check if selected date/time is in the past
      final now = DateTime.now();
      if (startDateTime.isBefore(now)) {
        _showAlertDialog(
          'Invalid Time',
          'Cannot book appointments in the past. Please select a present or future date and time.',
          Icons.warning_amber_rounded,
          Colors.orange,
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final duration = endDateTime.difference(startDateTime);
      if (duration.inMinutes != 60) {
        _showAlertDialog(
          'Invalid Duration',
          'Appointment duration must be exactly 1 hour',
          Icons.warning_amber_rounded,
          Colors.orange,
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Check for time conflicts with ANY existing appointments for this counselor
      // This prevents overlapping bookings across all students
      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      
      final existingAppointments = await Supabase.instance.client
          .from('counseling_appointments')
          .select('appointment_date, start_time, end_time, user_id')
          .eq('counselor_id', widget.counselor.id)
          .eq('appointment_date', dateStr)
          .inFilter('status', ['pending', 'accepted']);

      // Check for overlapping time slots
      for (final appointment in existingAppointments) {
        final startTimeStr = appointment['start_time'] as String;
        final endTimeStr = appointment['end_time'] as String;
        
        final startTimeParts = startTimeStr.split(':');
        final endTimeParts = endTimeStr.split(':');
        
        final existingStart = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          int.parse(startTimeParts[0]),
          int.parse(startTimeParts[1]),
        );
        
        final existingEnd = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          int.parse(endTimeParts[0]),
          int.parse(endTimeParts[1]),
        );

        // Check if time slots overlap
        // Two time slots overlap if one starts before the other ends
        bool hasConflict = (startDateTime.isBefore(existingEnd) && 
                           endDateTime.isAfter(existingStart));

        if (hasConflict) {
          setState(() => _isSubmitting = false);
          if (mounted) {
            _showAlertDialog(
              'Time Slot Unavailable',
              'This time slot (${TimeOfDay.fromDateTime(startDateTime).format(context)} - ${TimeOfDay.fromDateTime(endDateTime).format(context)}) overlaps with an existing appointment (${TimeOfDay.fromDateTime(existingStart).format(context)} - ${TimeOfDay.fromDateTime(existingEnd).format(context)}). Please choose a different time.',
              Icons.event_busy,
              Colors.orange,
            );
          }
          return;
        }
      }

      // Book appointment using controller
      final result = await _controller.bookAppointment(
        counselorId: widget.counselor.id,
        appointmentDate: _selectedDate!,
        startTime: startDateTime,
        endTime: endDateTime,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (result.success) {
          Navigator.pop(context);
          _showAlertDialog(
            'Success',
            'Appointment booked successfully',
            Icons.check_circle_outline,
            Colors.green,
          );
        } else {
          String errorMessage = result.errorMessage ?? 'Error booking appointment';
          String title = 'Error';
          
          if (errorMessage.contains('pending or accepted appointment')) {
            errorMessage = 'You already have a pending or accepted appointment. Please wait for it to be completed or cancelled before booking another one.';
            title = 'Limit Reached';
          } else if (errorMessage.contains('duplicate key') || errorMessage.contains('unique constraint')) {
            errorMessage = 'An appointment with this time slot already exists. Please choose a different time.';
            title = 'Time Slot Taken';
          } else if (errorMessage.contains('not authenticated')) {
            errorMessage = 'You must be logged in to book an appointment.';
            title = 'Authentication Required';
          }
          
          _showAlertDialog(title, errorMessage, Icons.error_outline, Colors.red);
        }
      }
    } catch (e) {
      print('ERROR BOOKING APPOINTMENT: $e');
      if (mounted) {
        _showAlertDialog(
          'Booking Error',
          'Unable to book appointment. $e',
          Icons.error_outline,
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF7C83FD).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C83FD).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Color(0xFF7C83FD),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key: const Key('bookAppointmentDialogTitle'),
                        'Book Appointment',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      Text(
                        'with ${widget.counselor.fullName}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Duration Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'All appointments are scheduled for exactly 1 hour',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF5D5D72),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Appointment Details',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Selection
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C83FD).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calendar_today, 
                                color: Color(0xFF7C83FD), size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Appointment Date',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDate == null
                                        ? 'Select a date'
                                        : '${DateFormat('EEEE, MMMM d, y').format(_selectedDate!)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedDate == null
                                          ? Colors.grey[500]
                                          : const Color(0xFF3A3A50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, 
                              size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Start Time Selection
                    InkWell(
                      onTap: () => _selectTime(context, true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C83FD).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.access_time, 
                                color: Color(0xFF7C83FD), size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time Slot',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedStartTime == null
                                        ? 'Select time'
                                        : '${_selectedStartTime!.format(context)} - ${_selectedEndTime?.format(context) ?? ""}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedStartTime == null
                                          ? Colors.grey[500]
                                          : const Color(0xFF3A3A50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, 
                              size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Notes Section
                    Text(
                      'Additional Notes (Optional)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Describe your concerns or what you\'d like to discuss...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5D5D72),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C83FD),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Booking...',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                          key: const Key('submitAppointmentButton'),
                            'Book Appointment',
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
        ],
      ),
    );
  }
}
