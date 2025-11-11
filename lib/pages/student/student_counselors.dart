import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/counselor.dart';
import '../../services/counselor_service.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../widgets/counselor_avatar.dart';
import '../../utils/department_mapping.dart';
import 'counselor_profile_view.dart';

class StudentCounselors extends StatefulWidget {
  const StudentCounselors({super.key});

  @override
  State<StudentCounselors> createState() => _StudentCounselorsState();
}

class _StudentCounselorsState extends State<StudentCounselors> {
  final CounselorService _counselorService = CounselorService();
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
    try {
      // Get current user
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get student's education info to determine department
      final studentData = await Supabase.instance.client
          .from('students')
          .select('education_level, course, strand')
          .eq('user_id', userId)
          .maybeSingle();

      if (studentData != null) {
        _studentDepartment = DepartmentMapping.getStudentDepartment(
          educationLevel: studentData['education_level'],
          course: studentData['course'],
          strand: studentData['strand'],
        );
      }

      // Get all counselors
      final allCounselors = await _counselorService.getCounselors();
      
      // Filter counselors by department
      final departmentCounselors = <Counselor>[];
      final volunteerCounselors = <Counselor>[];

      for (final counselor in allCounselors) {
        if (counselor.departmentAssigned == 'Volunteer') {
          volunteerCounselors.add(counselor);
        } else if (_studentDepartment != null && 
                   counselor.departmentAssigned == _studentDepartment) {
          departmentCounselors.add(counselor);
        }
      }

      setState(() {
        _departmentCounselors = departmentCounselors;
        _volunteerCounselors = volunteerCounselors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading counselors: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading counselors')),
        );
      }
    }
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

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null ||
        _selectedStartTime == null ||
        _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
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

      final duration = endDateTime.difference(startDateTime);
      if (duration.inMinutes != 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Appointment duration must be exactly 1 hour')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Check for time conflicts with existing appointments
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final existingAppointments = await Supabase.instance.client
            .from('counseling_appointments')
            .select('appointment_date, start_time, end_time')
            .eq('user_id', userId)
            .inFilter('status', ['pending', 'accepted']);

        // Check for conflicts
        for (final appointment in existingAppointments) {
          // Parse the date and time
          final appointmentDate = appointment['appointment_date'] as String;
          final startTimeStr = appointment['start_time'] as String;
          final endTimeStr = appointment['end_time'] as String;
          
          // Combine date with time to create DateTime objects
          final dateParts = appointmentDate.split('-');
          final startTimeParts = startTimeStr.split(':');
          final endTimeParts = endTimeStr.split(':');
          
          final existingStart = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(startTimeParts[0]),
            int.parse(startTimeParts[1]),
          );
          
          final existingEnd = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(endTimeParts[0]),
            int.parse(endTimeParts[1]),
          );

          // Check if the new appointment overlaps with existing one
          bool hasConflict = (startDateTime.isBefore(existingEnd) && 
                             endDateTime.isAfter(existingStart));

          if (hasConflict) {
            setState(() => _isSubmitting = false);
            
            if (mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.all(24),
                    title: Row(
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
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Time Conflict',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'The selected time slot conflicts with an existing appointment.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF3A3A50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You already have an appointment scheduled from ${DateFormat('MMM d, h:mm a').format(existingStart)} to ${DateFormat('h:mm a').format(existingEnd)}.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF5D5D72),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please choose a different time slot.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF5D5D72),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C83FD),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Choose Different Time',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }
            return;
          }
        }
      }

      await CounselorService().createAppointment(
        counselorId: widget.counselor.id,
        appointmentDate: _selectedDate!,
        startTime: startDateTime,
        endTime: endDateTime,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully')),
        );
      }
    } catch (e) {
      print('ERROR BOOKING APPOINTMENT: $e');
      print('ERROR TYPE: ${e.runtimeType}');
      
      if (mounted) {
        String errorMessage = 'Error booking appointment';
        String title = 'Error';
        
        // Check for specific error types
        if (e.toString().contains('pending or accepted appointment')) {
          errorMessage = 'You already have a pending or accepted appointment. Please wait for it to be completed or cancelled before booking another one.';
          title = 'Limit Reached';
        } else if (e.toString().contains('duplicate key') || e.toString().contains('unique constraint')) {
          errorMessage = 'An appointment with this time slot already exists. Please choose a different time.';
          title = 'Time Slot Taken';
        } else if (e.toString().contains('not authenticated')) {
          errorMessage = 'You must be logged in to book an appointment.';
          title = 'Authentication Required';
        } else {
          // Show the actual error for debugging
          errorMessage = 'Unable to book appointment. ${e.toString()}';
          title = 'Booking Error';
        }
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              title: Row(
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
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF3A3A50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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
