import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingDebugPage extends StatefulWidget {
  const MessagingDebugPage({super.key});

  @override
  State<MessagingDebugPage> createState() => _MessagingDebugPageState();
}

class _MessagingDebugPageState extends State<MessagingDebugPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<String> _debugInfo = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _debugInfo.clear();
    });

    try {
      final currentUser = _supabase.auth.currentUser;
      _debugInfo.add('=== MESSAGING SYSTEM DEBUG ===');
      _debugInfo.add('Current User: ${currentUser?.id ?? 'NOT AUTHENTICATED'}');
      
      if (currentUser == null) {
        _debugInfo.add('ERROR: User not authenticated');
        return;
      }

      // Check user type
      try {
        final userData = await _supabase
            .from('users')
            .select('user_type')
            .eq('user_id', currentUser.id)
            .single();
        _debugInfo.add('User Type: ${userData['user_type']}');
      } catch (e) {
        _debugInfo.add('ERROR getting user type: $e');
      }

      // Check messages table structure
      _debugInfo.add('\n=== MESSAGES TABLE DIAGNOSTICS ===');
      try {
        // Try to query messages table
        final messagesTest = await _supabase
            .from('messages')
            .select('message_id, sender_id, receiver_id, message, is_read, created_at')
            .limit(1);
        _debugInfo.add('✅ Messages table accessible');
        _debugInfo.add('Sample query returned ${messagesTest.length} rows');
      } catch (e) {
        _debugInfo.add('❌ ERROR accessing messages table: $e');
      }

      // Check for appointment_id references
      try {
        final testAppointmentId = await _supabase
            .from('messages')
            .select('appointment_id')
            .limit(1);
        _debugInfo.add('⚠️  WARNING: appointment_id column still exists in messages table');
      } catch (e) {
        _debugInfo.add('✅ appointment_id column not found (this is good)');
      }

      // Check user's messages
      try {
        final userMessages = await _supabase
            .from('messages')
            .select('sender_id, receiver_id, message, created_at')
            .or('sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}')
            .order('created_at', ascending: false)
            .limit(5);
        
        _debugInfo.add('\n=== USER MESSAGES ===');
        _debugInfo.add('Total messages involving user: ${userMessages.length}');
        
        for (int i = 0; i < userMessages.length && i < 3; i++) {
          final msg = userMessages[i];
          final isSentByUser = msg['sender_id'] == currentUser.id;
          _debugInfo.add('${i + 1}. ${isSentByUser ? 'SENT' : 'RECEIVED'}: "${msg['message']}" at ${msg['created_at']}');
        }
      } catch (e) {
        _debugInfo.add('❌ ERROR getting user messages: $e');
      }

      // Check if user is counselor
      if (await _isUserCounselor(currentUser.id)) {
        _debugInfo.add('\n=== COUNSELOR DIAGNOSTICS ===');
        await _checkCounselorChat();
      } else {
        _debugInfo.add('\n=== STUDENT DIAGNOSTICS ===');
        await _checkStudentChat();
      }

    } catch (e) {
      _debugInfo.add('FATAL ERROR in diagnostics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _isUserCounselor(String userId) async {
    try {
      final counselorData = await _supabase
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', userId)
          .maybeSingle();
      return counselorData != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _checkCounselorChat() async {
    try {
      final currentUser = _supabase.auth.currentUser!;
      
      // Get all messages involving this counselor
      final allMessages = await _supabase
          .from('messages')
          .select('sender_id, receiver_id, created_at, message')
          .or('sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}')
          .order('created_at', ascending: false);

      _debugInfo.add('Counselor has ${allMessages.length} total messages');

      // Find unique student user IDs
      Set<String> studentUserIds = {};
      for (var message in allMessages) {
        final senderId = message['sender_id'] as String;
        final receiverId = message['receiver_id'] as String;
        
        if (senderId == currentUser.id) {
          studentUserIds.add(receiverId);
        } else if (receiverId == currentUser.id) {
          studentUserIds.add(senderId);
        }
      }

      _debugInfo.add('Conversations with ${studentUserIds.length} students');

      // Check if these are actually students
      if (studentUserIds.isNotEmpty) {
        final studentsCheck = await _supabase
            .from('students')
            .select('user_id, first_name, last_name')
            .inFilter('user_id', studentUserIds.toList());

        _debugInfo.add('Confirmed ${studentsCheck.length} are students:');
        for (var student in studentsCheck.take(3)) {
          _debugInfo.add('  - ${student['first_name']} ${student['last_name']} (${student['user_id']})');
        }
      }

    } catch (e) {
      _debugInfo.add('ERROR in counselor chat check: $e');
    }
  }

  Future<void> _checkStudentChat() async {
    try {
      final currentUser = _supabase.auth.currentUser!;
      
      // Get all messages involving this student
      final allMessages = await _supabase
          .from('messages')
          .select('sender_id, receiver_id, created_at, message')
          .or('sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}')
          .order('created_at', ascending: false);

      _debugInfo.add('Student has ${allMessages.length} total messages');

      // Find unique counselor user IDs
      Set<String> counselorUserIds = {};
      for (var message in allMessages) {
        final senderId = message['sender_id'] as String;
        final receiverId = message['receiver_id'] as String;
        
        if (senderId == currentUser.id) {
          counselorUserIds.add(receiverId);
        } else if (receiverId == currentUser.id) {
          counselorUserIds.add(senderId);
        }
      }

      _debugInfo.add('Conversations with ${counselorUserIds.length} counselors');

      // Check if these are actually counselors
      if (counselorUserIds.isNotEmpty) {
        final counselorsCheck = await _supabase
            .from('counselors')
            .select('user_id, first_name, last_name')
            .inFilter('user_id', counselorUserIds.toList());

        _debugInfo.add('Confirmed ${counselorsCheck.length} are counselors:');
        for (var counselor in counselorsCheck.take(3)) {
          _debugInfo.add('  - ${counselor['first_name']} ${counselor['last_name']} (${counselor['user_id']})');
        }
      }

    } catch (e) {
      _debugInfo.add('ERROR in student chat check: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _debugInfo
                            .map((info) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    info,
                                    style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 12,
                                      color: info.contains('ERROR') || info.contains('❌')
                                          ? Colors.red
                                          : info.contains('WARNING') || info.contains('⚠️')
                                              ? Colors.orange
                                              : info.contains('✅')
                                                  ? Colors.green
                                                  : Colors.black87,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _runDiagnostics,
                    child: const Text('Re-run Diagnostics'),
                  ),
                ],
              ),
            ),
    );
  }
}