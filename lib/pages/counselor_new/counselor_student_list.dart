import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/counselor_student_list_controller.dart';
import '../../widgets/student_avatar.dart';
import 'counselor_student_overview.dart';

class CounselorStudentList extends StatefulWidget {
  const CounselorStudentList({super.key});

  @override
  State<CounselorStudentList> createState() => _CounselorStudentListState();
}

class _CounselorStudentListState extends State<CounselorStudentList> {
  final _controller = CounselorStudentListController();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudentHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStudentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final students = await _controller.loadStudentHistory();
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _students = [];
        _isLoading = false;
        _errorMessage = 'Error loading students: $e';
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
          'My Students',
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
                StudentAvatar(
                  userId: student['user_id'],
                  radius: 25,
                  fallbackName: displayName,
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
                      const SizedBox(height: 4),
                      if (studentCode.isNotEmpty)
                        Text(
                          'ID: $studentCode',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF5D5D72),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: Color(0xFF7C83FD),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CounselorStudentOverview(
                          userId: student['user_id'],
                          studentName: displayName,
                          studentId: studentCode,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
