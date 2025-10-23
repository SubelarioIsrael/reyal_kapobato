import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/counselor.dart';
import '../../services/counselor_service.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../widgets/counselor_avatar.dart';

class StudentCounselors extends StatefulWidget {
  const StudentCounselors({super.key});

  @override
  State<StudentCounselors> createState() => _StudentCounselorsState();
}

class _StudentCounselorsState extends State<StudentCounselors> {
  final CounselorService _counselorService = CounselorService();
  List<Counselor> _counselors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounselors();
  }

  Future<void> _loadCounselors() async {
    try {
      final counselors = await _counselorService.getCounselors();
      setState(() {
        _counselors = counselors;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading counselors')),
        );
      }
    }
  }

  void _showBookAppointmentDialog(Counselor counselor) {
    showDialog(
      context: context,
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
              else if (_counselors.isEmpty)
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
                          'There are currently no counselors registered in the system. Please check back later or contact the administrator for assistance.',
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
                  child: ListView.builder(
                    itemCount: _counselors.length,
                    itemBuilder: (context, index) {
                      final counselor = _counselors[index];
                      return _CounselorCard(
                        counselor: counselor,
                        onBookAppointment: () =>
                            _showBookAppointmentDialog(counselor),
                        onViewProfile: () {
                          Navigator.pushNamed(
                            context,
                            '/counselor-profile-view',
                            arguments: {
                              'counselorId': counselor.id,
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounselorCard extends StatefulWidget {
  final Counselor counselor;
  final VoidCallback onBookAppointment;
  final VoidCallback? onViewProfile;

  const _CounselorCard({
    required this.counselor,
    required this.onBookAppointment,
    this.onViewProfile,
  });

  @override
  State<_CounselorCard> createState() => _CounselorCardState();
}

class _CounselorCardState extends State<_CounselorCard> {

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onBookAppointment,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CounselorAvatar(
                  counselorId: widget.counselor.id,
                  radius: 30,
                  fallbackName: widget.counselor.fullName,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (widget.counselor.fullName.isNotEmpty
                            ? widget.counselor.fullName
                                .split(' ')
                                .map((part) => part.isNotEmpty
                                    ? part[0].toUpperCase() +
                                        part.substring(1).toLowerCase()
                                    : '')
                                .join(' ')
                            : ''),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.counselor.specialization,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.counselor.availabilityStatus.toLowerCase() ==
                                  'available'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.counselor.availabilityStatus,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: widget.counselor.availabilityStatus.toLowerCase() ==
                                    'available'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: widget.onViewProfile,
                      icon: const Icon(Icons.person_outline),
                      color: const Color(0xFF7C83FD),
                      tooltip: 'View Profile',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF7C83FD).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
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
      if (mounted) {
        String errorMessage = 'Error booking appointment';
        String title = 'Error';
        if (e.toString().contains('pending or accepted appointment')) {
          errorMessage = 'You already have a pending or accepted appointment. Please wait for it to be completed or cancelled before booking another one.';
          title = 'Limit Reached';
        }
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                ],
              ),
              content: Text(
                errorMessage,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7C83FD),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
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
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C83FD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Color(0xFF7C83FD),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Book Appointment',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            Text(
                              'with ${widget.counselor.fullName}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Duration Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'All appointments are scheduled for exactly 1 hour',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Date Selection
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C83FD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today, color: Color(0xFF7C83FD), size: 20),
                      ),
                      title: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _selectedDate == null
                              ? Colors.grey[600]
                              : const Color(0xFF3A3A50),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF7C83FD)),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Start Time Selection
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C83FD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.access_time, color: Color(0xFF7C83FD), size: 20),
                      ),
                      title: Text(
                        _selectedStartTime == null
                            ? 'Select Start Time'
                            : 'Start: ${_selectedStartTime!.format(context)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _selectedStartTime == null
                              ? Colors.grey[600]
                              : const Color(0xFF3A3A50),
                        ),
                      ),
                      subtitle: _selectedEndTime != null
                          ? Text(
                              'End: ${_selectedEndTime!.format(context)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF7C83FD)),
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notes Section
                  Text(
                    'Additional Notes (Optional)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Describe your concerns or what you\'d like to discuss...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF7C83FD)),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF7C83FD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7C83FD),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C83FD),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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
                                    const SizedBox(width: 8),
                                    Text(
                                      'Booking...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Book',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
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
          ),
        ),
      ),
    );
  }
}
