import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_history.dart';

class StudentHistoryList extends StatefulWidget {
  const StudentHistoryList({super.key});

  @override
  State<StudentHistoryList> createState() => _StudentHistoryListState();
}

class _StudentHistoryListState extends State<StudentHistoryList> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudentHistory();
  }

  Future<void> _loadStudentHistory() async {
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

      // Get all students who have had appointments with this counselor
      final appointmentsResponse = await Supabase.instance.client
          .from('counseling_appointments')
          .select('user_id')
          .eq('counselor_id', counselorId);

      final uniqueUserIds = (appointmentsResponse as List)
          .map((appt) => appt['user_id'] as String)
          .toSet()
          .toList();

      if (uniqueUserIds.isEmpty) {
        setState(() {
          _students = [];
          _isLoading = false;
        });
        return;
      }

      // Get student details
      final studentsResponse = await Supabase.instance.client
          .from('students')
          .select('user_id, student_code, first_name, last_name')
          .inFilter('user_id', uniqueUserIds);

      final usersResponse = await Supabase.instance.client
          .from('users')
          .select('user_id, email')
          .inFilter('user_id', uniqueUserIds);

      // Combine data
      Map<String, Map<String, dynamic>> studentsMap = {};
      
      for (var student in studentsResponse) {
        studentsMap[student['user_id']] = {
          'user_id': student['user_id'],
          'student_code': student['student_code'] ?? '',
          'first_name': student['first_name'] ?? '',
          'last_name': student['last_name'] ?? '',
        };
      }

      for (var user in usersResponse) {
        if (studentsMap[user['user_id']] != null) {
          studentsMap[user['user_id']]!.addAll({
            'username': user['username'] ?? '',
            'email': user['email'] ?? '',
          });
        }
      }

      // Get appointment counts for each student
      for (var userId in uniqueUserIds) {
        final appointmentCountResponse = await Supabase.instance.client
            .from('counseling_appointments')
            .select('appointment_id, status')
            .eq('counselor_id', counselorId)
            .eq('user_id', userId);

        final totalAppointments = appointmentCountResponse.length;
        final completedAppointments = appointmentCountResponse
            .where((appt) => appt['status'] == 'completed')
            .length;

        if (studentsMap[userId] != null) {
          studentsMap[userId]!.addAll({
            'total_appointments': totalAppointments,
            'completed_appointments': completedAppointments,
          });
        }
      }

      setState(() {
        _students = studentsMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _students = [];
        _isLoading = false;
        _errorMessage = 'Error loading student history: $e';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    
    return _students.where((student) {
      final firstName = student['first_name']?.toLowerCase() ?? '';
      final lastName = student['last_name']?.toLowerCase() ?? '';
      final username = student['username']?.toLowerCase() ?? '';
      final studentCode = student['student_code']?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return firstName.contains(query) ||
             lastName.contains(query) ||
             username.contains(query) ||
             studentCode.contains(query);
    }).toList();
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
          'Student History',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadStudentHistory,
                        child: _filteredStudents.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = _filteredStudents[index];
                                  return _buildStudentCard(student);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search students...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF7C83FD)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        style: GoogleFonts.poppins(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            _searchQuery.isEmpty 
                ? 'No student history found'
                : 'No students match your search',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Students will appear here after appointments'
                : 'Try searching with different keywords',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final firstName = student['first_name'] ?? '';
    final lastName = student['last_name'] ?? '';
    final studentName = '$firstName $lastName'.trim();
    final displayName = studentName.isNotEmpty 
        ? studentName 
        : student['username'] ?? 'Unknown Student';
    final studentCode = student['student_code'] ?? '';
    final totalAppointments = student['total_appointments'] ?? 0;
    final completedAppointments = student['completed_appointments'] ?? 0;

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
                    color: const Color(0xFF7C83FD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.person,
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
                        student['email'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$completedAppointments/$totalAppointments Sessions',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentHistory(
                            userId: student['user_id'],
                            studentName: displayName,
                            studentId: studentCode,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history, size: 16),
                    label: Text(
                      'View History',
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
                      // TODO: Start new appointment or message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact student coming soon')),
                      );
                    },
                    icon: const Icon(Icons.message, size: 16),
                    label: Text(
                      'Contact',
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
}