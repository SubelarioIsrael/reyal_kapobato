import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../../services/counselor_service.dart';
import '../../widgets/student_avatar.dart';
import '../call/call.dart';
import 'dart:math';

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
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A3A50),
          ),
        ),
        
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
    final studentInfo =
        _studentInfo[appointment.userId.toString().trim()] ?? {};
    final firstName = studentInfo['first_name'] ?? '';
    final lastName = studentInfo['last_name'] ?? '';
    final studentName = '$firstName $lastName'.trim();
    final displayName = studentName.isNotEmpty
        ? studentName
        : studentInfo['student_name'] ?? 'Unknown Student';

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
            // Main appointment info row
            Row(
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
                            child: Text(
                              displayName,
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
                          
                          // Time Row with Status Dropdown
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
                              // Status Dropdown (only show for pending/accepted appointments)
                              if (appointment.status.toLowerCase() == 'pending' ||
                                  appointment.status.toLowerCase() == 'accepted')
                                PopupMenuButton<String>(
                                  onSelected: (String value) => _updateAppointmentStatus(appointment, value),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    child: Text(
                                      'UPDATE',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF7C83FD),
                                      ),
                                    ),
                                  ),
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    if (appointment.status.toLowerCase() != 'completed')
                                      const PopupMenuItem<String>(
                                        value: 'completed',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 18),
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
                                            Icon(Icons.cancel, color: Colors.red, size: 18),
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
                                            Icon(Icons.check, color: Colors.blue, size: 18),
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
                                            Icon(Icons.close, color: Colors.orange, size: 18),
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

  void _showVideoCallDialog() {
    final callIdController = TextEditingController();
    bool isGeneratingCode = false;
    bool isJoiningCall = false;
    String selectedOption = 'generate'; // 'generate' or 'enter'
    String? generatedCallCode;
    
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
                  color: const Color(0xFF7C83FD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.video_call, 
                  color: Color(0xFF7C83FD), 
                  size: 28
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video Call',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose an option to start your session',
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
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Option 1: Generate New Code
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedOption == 'generate' 
                            ? const Color(0xFF7C83FD) 
                            : Colors.grey.shade300,
                        width: selectedOption == 'generate' ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RadioListTile<String>(
                      value: 'generate',
                      groupValue: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                          callIdController.clear();
                          generatedCallCode = null;
                        });
                      },
                      title: Text(
                        'Generate New Call Code',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      subtitle: Text(
                        'Create a new room for students to join',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                      activeColor: const Color(0xFF7C83FD),
                    ),
                  ),
                  
                  if (selectedOption == 'generate') ...[
                    const SizedBox(height: 16),
                    if (generatedCallCode != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C83FD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF7C83FD).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.code, color: Color(0xFF7C83FD)),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Call Code:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3A3A50),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    generatedCallCode!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: const Color(0xFF7C83FD),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () {
                                      // Copy to clipboard logic here
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Call code copied to clipboard!'),
                                          backgroundColor: const Color(0xFF7C83FD),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C83FD).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.copy, size: 16, color: Color(0xFF7C83FD)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Share this code with your student to join the call',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF5D5D72),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isGeneratingCode ? null : () async {
                            setState(() {
                              isGeneratingCode = true;
                            });
                            
                            try {
                              // Generate call code
                              final code = await _generateCallCode();
                              setState(() {
                                generatedCallCode = code;
                                isGeneratingCode = false;
                              });
                            } catch (e) {
                              setState(() {
                                isGeneratingCode = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error generating code: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C83FD),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: isGeneratingCode 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(
                            isGeneratingCode ? 'Generating...' : 'Generate Call Code',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Option 2: Enter Existing Code
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedOption == 'enter' 
                            ? const Color(0xFF7C83FD) 
                            : Colors.grey.shade300,
                        width: selectedOption == 'enter' ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RadioListTile<String>(
                      value: 'enter',
                      groupValue: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                          generatedCallCode = null;
                        });
                      },
                      title: Text(
                        'Join Existing Call',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      subtitle: Text(
                        'Enter a call code to join an existing room',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                      activeColor: const Color(0xFF7C83FD),
                    ),
                  ),
                  
                  if (selectedOption == 'enter') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: callIdController,
                      decoration: InputDecoration(
                        hintText: 'Enter call code (abc-def-ghi)',
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
                          borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
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
                      onSubmitted: (value) {
                        if (value.isNotEmpty && !isJoiningCall) {
                          _joinVideoCall(value.trim());
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF5D5D72),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: (isGeneratingCode || isJoiningCall) ? null : () async {
                if (selectedOption == 'generate' && generatedCallCode != null) {
                  // Join the generated call
                  await _joinVideoCall(generatedCallCode!);
                } else if (selectedOption == 'enter' && callIdController.text.isNotEmpty) {
                  // Join the entered call code
                  await _joinVideoCall(callIdController.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        selectedOption == 'generate' 
                            ? 'Please generate a call code first'
                            : 'Please enter a call code',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C83FD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isJoiningCall
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Start Call',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateRandomCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    final random = Random();
    
    String generateGroup() {
      return String.fromCharCodes(
        Iterable.generate(3, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
      );
    }
    
    return '${generateGroup()}-${generateGroup()}-${generateGroup()}';
  }

  Future<String> _generateCallCode() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Get counselor info
      final counselorData = await Supabase.instance.client
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', user.id)
          .single();

      final counselorId = counselorData['counselor_id'] as int;
      final callCode = _generateRandomCode();

      // Insert video call record
      await Supabase.instance.client.from('video_calls').insert({
        'call_code': callCode,
        'counselor_id': counselorId,
        'created_by': 'counselor',
        'status': 'active',
        'counselor_joined_at': DateTime.now().toIso8601String(),
      });

      return callCode;
    } catch (e) {
      throw Exception('Failed to generate call code: $e');
    }
  }

  Future<void> _joinVideoCall(String callCode) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Get counselor data
      final counselorData = await Supabase.instance.client
          .from('counselors')
          .select('first_name, last_name, counselor_id')
          .eq('user_id', user.id)
          .single();

      final counselorId = counselorData['counselor_id'] as int;
      String userName = user.email ?? 'Counselor';

      if (counselorData['first_name'] != null && counselorData['last_name'] != null) {
        userName = '${counselorData['first_name']} ${counselorData['last_name']}';
      }

      // Check if call exists and update counselor info
      final videoCallData = await Supabase.instance.client
          .from('video_calls')
          .select('*')
          .eq('call_code', callCode)
          .eq('status', 'active')
          .single();

      // Update counselor joined time
      await Supabase.instance.client
          .from('video_calls')
          .update({
            'counselor_joined_at': DateTime.now().toIso8601String(),
          })
          .eq('call_code', callCode);

      // Close dialog
      if (mounted) Navigator.pop(context);

      // Navigate to call page
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallPage(
              callID: callCode,
              userID: user.id,
              userName: userName,
              counselorId: counselorId,
              studentUserId: videoCallData['student_user_id'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }




  Future<void> _updateAppointmentStatus(Appointment appointment, String newStatus) async {
    // If status is completed, show session notes dialog
    if (newStatus.toLowerCase() == 'completed') {
      await _updateAppointmentStatusCompleted(appointment);
      return;
    }

    // Show confirmation dialog with optional message for other statuses
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

  Future<void> _updateAppointmentStatusCompleted(Appointment appointment) async {
    // Show session notes modal bottom sheet for completed appointments
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        final messageController = TextEditingController();
        final summaryController = TextEditingController();
        final topicsController = TextEditingController();
        final recommendationsController = TextEditingController();
        bool isSaving = false;

        return StatefulBuilder(
          builder: (builderContext, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(builderContext).size.height * 0.9,
                minHeight: MediaQuery.of(builderContext).size.height * 0.5,
              ),
              width: MediaQuery.of(builderContext).size.width,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(builderContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Complete Appointment',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalContext),
                        icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                      ),
                    ],
                  ),
                  Text(
                    'Please provide session details to complete the appointment',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                  const Divider(),
                  
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Session Summary
                          Row(
                            children: [
                              Icon(
                                Icons.summarize,
                                size: 18,
                                color: const Color(0xFF7C83FD),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Session Summary *',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: summaryController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Provide a brief summary of the session...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 20),

                          // Topics Discussed
                          Row(
                            children: [
                              Icon(
                                Icons.topic,
                                size: 18,
                                color: const Color(0xFF7C83FD),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Topics Discussed',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: topicsController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'List the main topics covered during the session...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 20),

                          // Recommendations
                          Row(
                            children: [
                              Icon(
                                Icons.recommend,
                                size: 18,
                                color: const Color(0xFF7C83FD),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recommendations',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: recommendationsController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Provide recommendations for the student...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 20),

                          // Additional Message
                          Row(
                            children: [
                              Icon(
                                Icons.message,
                                size: 18,
                                color: const Color(0xFF7C83FD),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Additional Message (optional)',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: messageController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Add a note for the stasdasdudent...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: isSaving ? null : () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.grey[300]!),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF5D5D72),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isSaving ? null : () async {
                                    if (summaryController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Please provide a session summary',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    setModalState(() => isSaving = true);

                                    try {
                                      final user = Supabase.instance.client.auth.currentUser;
                                      if (user == null) throw Exception('Not logged in');

                                      // Get counselor profile
                                      final counselorProfile = await Supabase.instance.client
                                          .from('counselors')
                                          .select('counselor_id')
                                          .eq('user_id', user.id)
                                          .single();

                                      final counselorId = counselorProfile['counselor_id'] as int;

                                      // Save session notes
                                      await Supabase.instance.client.from('counseling_session_notes').insert({
                                        'appointment_id': appointment.id,
                                        'counselor_id': counselorId,
                                        'student_user_id': appointment.userId,
                                        'summary': summaryController.text.trim(),
                                        'topics_discussed': topicsController.text.trim().isNotEmpty 
                                            ? topicsController.text.trim() 
                                            : null,
                                        'recommendations': recommendationsController.text.trim().isNotEmpty 
                                            ? recommendationsController.text.trim() 
                                            : null,
                                        'created_at': DateTime.now().toIso8601String(),
                                        'updated_at': DateTime.now().toIso8601String(),
                                      });

                                      // Update appointment status
                                      await Supabase.instance.client
                                          .from('counseling_appointments')
                                          .update({
                                            'status': 'completed',
                                          })
                                          .eq('appointment_id', appointment.id);

                                      final statusMessage = messageController.text.trim().isNotEmpty 
                                          ? messageController.text.trim() 
                                          : 'Your appointment has been completed. Session notes have been saved.';

                                      // Send notification to student
                                      await _sendStatusUpdateNotification(appointment, 'completed', statusMessage);

                                      Navigator.pop(modalContext, true); // Return true to indicate success
                                    } catch (e) {
                                      if (modalContext.mounted) {
                                        ScaffoldMessenger.of(modalContext).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error completing appointment: $e',
                                              style: GoogleFonts.poppins(),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (modalContext.mounted) {
                                        setModalState(() => isSaving = false);
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C83FD),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Complete',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Appointment completed and session notes saved',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the appointments list
        _loadAppointments();
      }
    });
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
