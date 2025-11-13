import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/counselor_appointments_controller.dart';
import '../../models/appointment.dart';
import '../../widgets/student_avatar.dart';
import '../../components/video_call_dialog.dart';
import '../chat/appointment_chat.dart';

class CounselorAppointments extends StatefulWidget {
  const CounselorAppointments({super.key});

  @override
  State<CounselorAppointments> createState() => _CounselorAppointmentsState();
}

class _CounselorAppointmentsState extends State<CounselorAppointments> {
  final _controller = CounselorAppointmentsController();
  
  List<Appointment> _appointments = [];
  Map<String, Map<String, String>> _studentInfo = {};
  Map<int, int> _unreadCounts = {}; // appointmentId -> unread count
  bool _isLoading = true;
  String? _errorMessage;
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

    final result = await _controller.loadAppointments();

    if (result.success) {
      setState(() {
        _appointments = result.appointments;
        _studentInfo = result.studentInfo;
        _isLoading = false;
      });

      // Load unread counts for all appointments
      _loadUnreadCounts();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
    }
  }

  Future<void> _loadUnreadCounts() async {
    if (_appointments.isEmpty) return;

    final appointmentIds = _appointments.map((a) => a.id).toList();
    final result = await _controller.getUnreadCounts(appointmentIds);

    if (result.success) {
      setState(() {
        _unreadCounts = result.unreadCounts;
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
                                  final appointment = _filteredAppointments[index];
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
      {'key': 'cancelled', 'label': 'Cancelled'},
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
    final studentInfo = _studentInfo[appointment.userId.toString().trim()] ?? {};
    final firstName = studentInfo['first_name'] ?? '';
    final lastName = studentInfo['last_name'] ?? '';
    final studentName = '$firstName $lastName'.trim();
    final displayName = studentName.isNotEmpty
        ? studentName
        : studentInfo['student_name'] ?? 'Unknown Student';
    final unreadCount = _unreadCounts[appointment.id] ?? 0;

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
        child: Row(
          children: [
            // Student Avatar
            StudentAvatar(
              userId: appointment.userId,
              radius: 30,
              fallbackName: displayName,
            ),
            const SizedBox(width: 16),
            
            // Appointment Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Name and Status
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A3A50),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(appointment.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          appointment.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(appointment.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Date and Time Info
                  Column(
                    children: [
                      // Date Row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Time Row with Kebab Menu
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
                              '${TimeOfDay(hour: appointment.startTime.hour, minute: appointment.startTime.minute).format(context)} - ${TimeOfDay(hour: appointment.endTime.hour, minute: appointment.endTime.minute).format(context)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Kebab Menu
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Color(0xFF3A3A50),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 3,
                            itemBuilder: (context) => [
                              // Chat option
                              PopupMenuItem(
                                value: 'chat',
                                child: Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(
                                          Icons.chat,
                                          size: 18,
                                          color: Color(0xFF7C83FD),
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: -4,
                                            top: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      unreadCount > 0 ? 'Chat ($unreadCount)' : 'Chat',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: const Color(0xFF3A3A50),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Complete option
                              if (appointment.status.toLowerCase() == 'pending' ||
                                  appointment.status.toLowerCase() == 'accepted')
                                PopupMenuItem(
                                  value: 'complete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Mark as Completed',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: const Color(0xFF3A3A50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Cancel option
                              if (appointment.status.toLowerCase() == 'pending' ||
                                  appointment.status.toLowerCase() == 'accepted')
                                PopupMenuItem(
                                  value: 'cancel',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.cancel,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Mark as Cancelled',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: const Color(0xFF3A3A50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Accept option (pending only)
                              if (appointment.status.toLowerCase() == 'pending')
                                PopupMenuItem(
                                  value: 'accept',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Accept Appointment',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: const Color(0xFF3A3A50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Reject option (pending only)
                              if (appointment.status.toLowerCase() == 'pending')
                                PopupMenuItem(
                                  value: 'reject',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Reject Appointment',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: const Color(0xFF3A3A50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            onSelected: (value) async {
                              if (value == 'chat') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AppointmentChat(
                                      appointment: appointment,
                                      isCounselor: true,
                                    ),
                                  ),
                                );
                                // Reload unread counts after returning from chat
                                _loadUnreadCounts();
                              } else if (value == 'complete') {
                                await _handleCompleteAppointment(appointment);
                              } else if (value == 'cancel') {
                                await _handleStatusUpdate(appointment, 'cancelled');
                              } else if (value == 'accept') {
                                await _handleStatusUpdate(appointment, 'accepted');
                              } else if (value == 'reject') {
                                await _handleStatusUpdate(appointment, 'rejected');
                              }
                            },
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
      case 'cancelled':
        return Colors.grey[600]!;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleCompleteAppointment(Appointment appointment) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        return _buildSessionNotesDialog(appointment);
      },
    );

    if (result == true) {
      await _loadAppointments();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                // Success Title
                Text(
                  'Success',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 12),
                // Success Message
                Text(
                  'Appointment completed and session notes saved',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5D5D72),
                  ),
                ),
                const SizedBox(height: 24),
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C83FD),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
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
    }
  }

  Widget _buildSessionNotesDialog(Appointment appointment) {
    final summaryController = TextEditingController();
    final topicsController = TextEditingController();
    final recommendationsController = TextEditingController();
    final messageController = TextEditingController();
    bool isSaving = false;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
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
                          Icons.check_circle,
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
                              'Complete Appointment',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Please provide session details',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Session Summary
                        Text(
                          'Session Summary *',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: summaryController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Brief summary of the session...',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
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
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(height: 24),

                        // Topics Discussed
                        Text(
                          'Topics Discussed',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: topicsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Main topics covered...',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
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
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(height: 24),

                        // Recommendations
                        Text(
                          'Recommendations',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: recommendationsController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Recommendations for the student...',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
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
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(height: 24),

                        // Additional Message
                        Text(
                          'Additional Message (optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: messageController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Add a note for the student...',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
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
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isSaving ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: const BorderSide(color: Color(0xFF7C83FD)),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF7C83FD),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isSaving ? null : () async {
                                if (summaryController.text.trim().isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      contentPadding: const EdgeInsets.all(24),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Warning Icon
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
                                          // Warning Title
                                          Text(
                                            'Required Field',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF3A3A50),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Warning Message
                                          Text(
                                            'Please provide a session summary',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: const Color(0xFF5D5D72),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          // OK Button
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF7C83FD),
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () => Navigator.pop(ctx),
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
                                  return;
                                }

                                setModalState(() => isSaving = true);

                                final result = await _controller.saveSessionNotes(
                                  appointmentId: appointment.id,
                                  studentUserId: appointment.userId,
                                  summary: summaryController.text.trim(),
                                  topicsDiscussed: topicsController.text.trim().isNotEmpty
                                      ? topicsController.text.trim()
                                      : null,
                                  recommendations: recommendationsController.text.trim().isNotEmpty
                                      ? recommendationsController.text.trim()
                                      : null,
                                );

                                if (result.success) {
                                  // Send notification
                                  await _controller.sendStatusUpdateNotification(
                                    studentUserId: appointment.userId,
                                    appointmentDate: appointment.appointmentDate.toString().split(' ')[0],
                                    newStatus: 'completed',
                                    message: messageController.text.trim(),
                                  );
                                  Navigator.pop(context, true);
                                } else {
                                  setModalState(() => isSaving = false);
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      contentPadding: const EdgeInsets.all(24),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Error Icon
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                              size: 48,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          // Error Title
                                          Text(
                                            'Error',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF3A3A50),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Error Message
                                          Text(
                                            result.errorMessage ?? 'Error saving notes',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: const Color(0xFF5D5D72),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          // OK Button
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF7C83FD),
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () => Navigator.pop(ctx),
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
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C83FD),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Save & Complete',
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleStatusUpdate(Appointment appointment, String newStatus) async {
    String? statusMessage;
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (context) {
        final messageController = TextEditingController();
        final statusColor = _getStatusColor(newStatus);
        final IconData statusIcon = newStatus == 'cancelled'
            ? Icons.cancel
            : newStatus == 'accepted'
                ? Icons.check_circle
                : newStatus == 'rejected'
                    ? Icons.close
                    : Icons.update;
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Update Status',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                'Are you sure you want to mark this appointment as ${newStatus.toUpperCase()}?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                ),
              ),
              const SizedBox(height: 20),
              // Message Input
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message (optional)',
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5D5D72),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: statusColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Color(0xFF7C83FD)),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C83FD),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                statusMessage = messageController.text.trim();
                confirmed = true;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Update',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!confirmed) return;

    final result = await _controller.updateAppointmentStatus(
      appointmentId: appointment.id,
      newStatus: newStatus,
      statusMessage: statusMessage,
    );

    if (result.success) {
      // Send notification
      await _controller.sendStatusUpdateNotification(
        studentUserId: appointment.userId,
        appointmentDate: appointment.appointmentDate.toString().split(' ')[0],
        newStatus: newStatus,
        message: statusMessage,
      );

      await _loadAppointments();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                // Success Title
                Text(
                  'Success',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 12),
                // Success Message
                Text(
                  'Appointment status updated to ${newStatus.toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5D5D72),
                  ),
                ),
                const SizedBox(height: 24),
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C83FD),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
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
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                // Error Title
                Text(
                  'Error',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 12),
                // Error Message
                Text(
                  result.errorMessage ?? 'Error updating status',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5D5D72),
                  ),
                ),
                const SizedBox(height: 24),
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C83FD),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
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
    }
  }

  void _showVideoCallDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VideoCallDialog(),
    );
  }
}
