import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDebugPage extends StatefulWidget {
  const ChatDebugPage({super.key});

  @override
  State<ChatDebugPage> createState() => _ChatDebugPageState();
}

class _ChatDebugPageState extends State<ChatDebugPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic> _debugData = {};
  bool _isLoading = false;

  Future<void> _loadDebugData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _supabase.auth.currentUser;
      
      // Get current user info
      final userData = await _supabase
          .from('users')
          .select('*')
          .eq('user_id', currentUser!.id)
          .maybeSingle();

      // Get counselor info if user is counselor
      Map<String, dynamic>? counselorData;
      if (userData?['user_type'] == 'counselor') {
        counselorData = await _supabase
            .from('counselors')
            .select('*')
            .eq('user_id', currentUser.id)
            .maybeSingle();
      }

      // Get student info if user is student
      Map<String, dynamic>? studentData;
      if (userData?['user_type'] == 'student') {
        studentData = await _supabase
            .from('students')
            .select('*')
            .eq('user_id', currentUser.id)
            .maybeSingle();
      }

      // Get appointments for current user
      List<dynamic> appointments = [];
      if (counselorData != null) {
        appointments = await _supabase
            .from('counseling_appointments')
            .select('*')
            .eq('counselor_id', counselorData['counselor_id']);
      } else if (studentData != null) {
        appointments = await _supabase
            .from('counseling_appointments')
            .select('*')
            .eq('user_id', currentUser.id);
      }

      // Get all messages for current user
      final messages = await _supabase
          .from('messages')
          .select('*')
          .or('sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}')
          .order('created_at', ascending: false);

      setState(() {
        _debugData = {
          'current_user_id': currentUser.id,
          'user_data': userData,
          'counselor_data': counselorData,
          'student_data': studentData,
          'appointments': appointments,
          'messages': messages,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugData = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDebugData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        title: Text(
          'Chat Debug Info',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5D5D72)),
            onPressed: _loadDebugData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDebugSection('Current User ID', _debugData['current_user_id']),
                  _buildDebugSection('User Data', _debugData['user_data']),
                  _buildDebugSection('Counselor Data', _debugData['counselor_data']),
                  _buildDebugSection('Student Data', _debugData['student_data']),
                  _buildDebugSection('Appointments', _debugData['appointments']),
                  _buildDebugSection('Messages', _debugData['messages']),
                  if (_debugData['error'] != null)
                    _buildDebugSection('Error', _debugData['error']),
                ],
              ),
            ),
    );
  }

  Widget _buildDebugSection(String title, dynamic data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data?.toString() ?? 'null',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}