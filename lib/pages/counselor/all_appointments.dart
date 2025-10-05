import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../chat/appointment_chat.dart';
import 'video_call_dialog.dart';

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
        final usersResponse = await Supabase.instance.client
            .from('users')
            .select('user_id, username')
            .inFilter('user_id', userIds);

        final studentsResponse = await Supabase.instance.client
            .from('students')
            .select('user_id, student_code, first_name, last_name')
            .inFilter('user_id', userIds);

        for (var u in usersResponse) {
          studentInfo[u['user_id'].toString().trim()] = {
            'username': u['username'] ?? '',
          };
        }

        for (var s in studentsResponse) {
          final key = s['user_id'].toString().trim();
          if (studentInfo[key] != null) {
            studentInfo[key]!.addAll({
              'student_code': s['student_code'] ?? '',
              'first_name': s['first_name'] ?? '',
              'last_name': s['last_name'] ?? '',
            });
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
        : studentInfo['username'] ?? 'Unknown Student';
    final studentCode = studentInfo['student_code'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.person,
                    color: _getStatusColor(appointment.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      if (studentCode.isNotEmpty)
                        Text(
                          'ID: $studentCode',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF5D5D72),
                          ),
                        ),
                      Text(
                        '${appointment.appointmentDate.toString().split(' ')[0]} • ${TimeOfDay.fromDateTime(appointment.startTime).format(context)} - ${TimeOfDay.fromDateTime(appointment.endTime).format(context)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Notes: ${appointment.notes}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to student history
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Student history coming soon')),
                      );
                    },
                    icon: const Icon(Icons.history, size: 16),
                    label: Text(
                      'History',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C83FD),
                      side: const BorderSide(color: Color(0xFF7C83FD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentChat(
                            appointment: appointment,
                            isCounselor: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: Text(
                      'Message',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C83FD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
      default:
        return Colors.grey;
    }
  }

  void _showVideoCallDialog() {
    showDialog(
      context: context,
      builder: (context) => const VideoCallDialog(),
    );
  }
}