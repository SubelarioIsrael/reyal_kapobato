import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../../widgets/student_avatar.dart';
import '../../services/chat_message_service.dart';

class AppointmentChat extends StatefulWidget {
  final Appointment appointment;
  final bool isCounselor;

  const AppointmentChat({
    super.key,
    required this.appointment,
    required this.isCounselor,
  });

  @override
  State<AppointmentChat> createState() => _AppointmentChatState();
}

class _AppointmentChatState extends State<AppointmentChat> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _otherUserName;
  String? _otherUserRole;
  String? _otherUserId; // Store the other user's user_id for marking messages as read

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _loadOtherUserInfo();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    if (bottomInset > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _loadOtherUserInfo() async {
    try {
      if (widget.isCounselor) {
        // If we're a counselor, get the student's info
        print(
            'Target user ID (student): ${widget.appointment.userId}'); // Debug log

        try {
          // First try to get student info directly from students table
          final studentResponse = await _supabase
              .from('students')
              .select('first_name, last_name, student_code')
              .eq('user_id', widget.appointment.userId)
              .maybeSingle();

          if (studentResponse != null &&
              studentResponse['first_name'] != null &&
              studentResponse['last_name'] != null) {
            // Helper function to properly capitalize names (keeps internal capitals)
            String formatName(String name) {
              if (name.isEmpty) return name;
              return name[0].toUpperCase() + name.substring(1);
            }
            
            setState(() {
              _otherUserId = widget.appointment.userId; // Store student's user_id
              _otherUserName =
                  '${formatName(studentResponse['first_name'])} ${formatName(studentResponse['last_name'])}';
              _otherUserRole = 'student';
            });
            return;
          }

          // Fallback to email if student info not found
          final userResponse = await _supabase
              .from('users')
              .select('email, user_type')
              .eq('user_id', widget.appointment.userId)
              .maybeSingle();

          if (userResponse != null) {
            setState(() {
              _otherUserName = userResponse['email'] ?? 'Unknown User';
              _otherUserRole = userResponse['user_type'] ?? 'student';
            });
            return;
          }
        } catch (e) {
          print('Error fetching student info: $e');
        }

        // Final fallback
        setState(() {
          _otherUserName = 'Unknown Student';
          _otherUserRole = 'student';
        });
      } else {
        // If we're a student, get the counselor's info
        print(
            'Looking for counselor with counselor_id: ${widget.appointment.counselorId}'); // Debug log

        try {
          final counselorResponse = await _supabase
              .from('counselors')
              .select('user_id, first_name, last_name')
              .eq('counselor_id', widget.appointment.counselorId)
              .single();

          print('Counselor response: $counselorResponse'); // Debug log

          setState(() {
            _otherUserId = counselorResponse['user_id']; // Store counselor's user_id
            _otherUserName =
                '${counselorResponse['first_name']} ${counselorResponse['last_name']}';
            _otherUserRole = 'counselor';
          });
        } catch (e) {
          print('Error loading counselor info: $e');

          // Fallback: use the counselor name from the appointment if available
          if (widget.appointment.counselorName != null) {
            print(
                'Using fallback counselor name: ${widget.appointment.counselorName}');
            setState(() {
              _otherUserName = widget.appointment.counselorName!;
              _otherUserRole = 'counselor';
            });
          } else {
            setState(() {
              _otherUserName = 'Unknown Counselor';
              _otherUserRole = 'counselor';
            });
          }
        }
      }
    } catch (e) {
      print('Error loading other user info: $e');
      setState(() {
        _otherUserName = 'Unknown User';
        _otherUserRole = 'user';
      });
    }
  }

  void _setupRealtimeSubscription() {
    _supabase
        .channel('messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'appointment_id',
            value: widget.appointment.id.toString(),
          ),
          callback: (payload) {
            _loadMessages();
          },
        )
        .subscribe();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print(
          'Loading messages for appointment ID: ${widget.appointment.id}'); // Debug log

      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('appointment_id', widget.appointment.id)
          .order('created_at', ascending: true);

      print('Messages response: $response'); // Debug log

      // Get all unique sender IDs
      final senderIds = response.map((msg) => msg['sender_id']).toSet().toList();
      
      // Create a map to store sender names
      Map<String, String> senderNames = {};
      
      if (senderIds.isNotEmpty) {
        // Get student names in one query
        try {
          final studentsResponse = await _supabase
              .from('students')
              .select('user_id, first_name, last_name')
              .inFilter('user_id', senderIds);
              
          for (var student in studentsResponse) {
            final firstName = student['first_name'] ?? '';
            final lastName = student['last_name'] ?? '';
            final fullName = '$firstName $lastName'.trim();
            senderNames[student['user_id']] = fullName.isNotEmpty ? fullName : 'Student';
          }
        } catch (e) {
          print('Error fetching student names: $e');
        }
        
        // Get counselor names in one query
        try {
          final counselorsResponse = await _supabase
              .from('counselors')
              .select('user_id, first_name, last_name')
              .inFilter('user_id', senderIds);
              
          for (var counselor in counselorsResponse) {
            final firstName = counselor['first_name'] ?? '';
            final lastName = counselor['last_name'] ?? '';
            final fullName = '$firstName $lastName'.trim();
            senderNames[counselor['user_id']] = fullName.isNotEmpty ? 'Dr. $fullName' : 'Counselor';
          }
        } catch (e) {
          print('Error fetching counselor names: $e');
        }
      }

      // Enrich messages with sender names
      List<Map<String, dynamic>> enrichedMessages = [];
      for (var message in response) {
        final senderId = message['sender_id'];
        String senderName;
        
        // Check if sender is current user
        if (senderId == _supabase.auth.currentUser?.id) {
          senderName = 'You';
        } else {
          senderName = senderNames[senderId] ?? 'Unknown';
        }
        
        // Add sender name to message
        Map<String, dynamic> enrichedMessage = Map<String, dynamic>.from(message);
        enrichedMessage['sender_name'] = senderName;
        enrichedMessages.add(enrichedMessage);
      }

      setState(() {
        _messages = enrichedMessages;
        _isLoading = false;
      });

      // Mark messages as read when they open the chat
      await _markMessagesAsRead();

      // Scroll to bottom after messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error loading messages: $e'); // Debug log
      setState(() {
        _errorMessage = 'Error loading messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Use the RPC function for reliable marking as read for this appointment
      final rpcResult = await _supabase.rpc('mark_messages_read', params: {
        'p_appointment_id': widget.appointment.id,
        'p_user_id': currentUserId,
      });

      if (rpcResult != null && rpcResult > 0) {
        print(
            'Marked $rpcResult messages as read for ${widget.isCounselor ? "counselor" : "student"}');
      }

      // Additionally, if we're a student and have the counselor's user_id,
      // mark ALL messages from this counselor as read (across all appointments)
      if (!widget.isCounselor && _otherUserId != null) {
        await ChatMessageService.markMessagesAsRead(_otherUserId!);
        print('Marked all messages from counselor $_otherUserId as read');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to send messages')),
        );
      }
      return;
    }

    try {
      String targetUserId;

      if (widget.isCounselor) {
        // If we're a counselor, use the student's user_id directly
        targetUserId = widget.appointment.userId;
      } else {
        // If we're a student, determine the counselor's user_id from existing messages
        // This is more reliable than querying the counselors table
        if (_messages.isNotEmpty) {
          // Find a message where the current user is NOT the sender
          final otherUserMessages = _messages
              .where(
                (msg) => msg['sender_id'] != currentUser.id,
              )
              .toList();

          if (otherUserMessages.isNotEmpty) {
            targetUserId = otherUserMessages.first['sender_id'];
          } else {
            // All messages are from current user, find receiver_id from our own messages
            final ownMessages = _messages
                .where(
                  (msg) => msg['sender_id'] == currentUser.id,
                )
                .toList();

            if (ownMessages.isNotEmpty) {
              targetUserId = ownMessages.first['receiver_id'];
            } else {
              throw Exception(
                  'Cannot determine target user from existing messages');
            }
          }
        } else {
          // No messages exist yet, try counselors table as fallback
          try {
            print(
                'Looking up counselor with ID: ${widget.appointment.counselorId}'); // Debug log

            // Try to get counselor's user_id from counselors table
            final counselorResponse = await _supabase
                .from('counselors')
                .select('user_id')
                .eq('counselor_id', widget.appointment.counselorId);

            print('Counselor query response: $counselorResponse'); // Debug log

            if (counselorResponse.isNotEmpty) {
              targetUserId = counselorResponse.first['user_id'].toString();
              print('Found counselor user_id: $targetUserId'); // Debug log
            } else {
              // Alternative: try to get counselor info through appointment with join
              print(
                  'No counselor found, trying alternative query...'); // Debug log
              final appointmentResponse = await _supabase
                  .from('counseling_appointments')
                  .select('counselor_id, counselors!inner(user_id)')
                  .eq('appointment_id', widget.appointment.id)
                  .single();

              print('Appointment response: $appointmentResponse'); // Debug log
              targetUserId =
                  appointmentResponse['counselors']['user_id'].toString();
              print(
                  'Found counselor user_id via appointment: $targetUserId'); // Debug log
            }
          } catch (e) {
            print('Error looking up counselor: $e'); // Debug log
            // If all lookups fail, we cannot send the message
            throw Exception(
                'Cannot determine counselor user ID. Please try again later. Error: $e');
          }
        }
      }

      print(
          'Sending message from ${currentUser.id} to $targetUserId for appointment ${widget.appointment.id}'); // Debug log

      await _supabase.from('messages').insert({
        'appointment_id': widget.appointment.id,
        'sender_id': currentUser.id,
        'receiver_id': targetUserId,
        'message': _messageController.text.trim(),
        'is_read': false,
        'message_type': 'text',
      });

      print('Message sent successfully'); // Debug log

      // Send push notification to receiver
      try {
        print('🔔 Preparing to send push notification...');
        print('🔔 Target user ID: $targetUserId');
        print('🔔 Sender user ID: ${currentUser.id}');
        
        // Get sender name
        String senderName = 'Someone';
        if (widget.isCounselor) {
          final counselorData = await _supabase
              .from('counselors')
              .select('first_name, last_name')
              .eq('user_id', currentUser.id)
              .maybeSingle();
          
          if (counselorData != null) {
            senderName = '${counselorData['first_name']} ${counselorData['last_name']}';
          }
          print('🔔 Sender is COUNSELOR: $senderName');
        } else {
          final studentData = await _supabase
              .from('students')
              .select('first_name, last_name')
              .eq('user_id', currentUser.id)
              .maybeSingle();
          
          if (studentData != null) {
            senderName = '${studentData['first_name']} ${studentData['last_name']}';
          }
          print('🔔 Sender is STUDENT: $senderName');
        }

        // Truncate message for preview
        final messageText = _messageController.text.trim();
        final messagePreview = messageText.length > 50
            ? '${messageText.substring(0, 50)}...'
            : messageText;

        print('🔔 Calling Edge Function send-notification...');
        print('🔔 Notification title: New message from $senderName');
        print('🔔 Notification body: $messagePreview');
        
        final response = await _supabase.functions.invoke(
          'send-notification',
          body: {
            'user_id': targetUserId,
            'title': 'New message from $senderName',
            'body': messagePreview,
            'data': {
              'type': 'chat_message',
              'appointment_id': widget.appointment.id.toString(),
              'sender_id': currentUser.id,
              'sender_name': senderName,
            },
          },
        );
        
        print('🔔 ✅ Push notification Edge Function response: ${response.data}');
        print('🔔 ✅ Push notification sent successfully!');
      } catch (e, stackTrace) {
        print('🔔 ❌ Error sending push notification: $e');
        print('🔔 ❌ Stack trace: $stackTrace');
      }

      _messageController.clear();
      // Explicitly reload messages to ensure the sent message appears immediately
      await _loadMessages();

      // Mark messages as read after sending (in case it didn't work before)
      await _markMessagesAsRead();
    } catch (e) {
      print('Error sending message: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        title: Row(
          children: [
            // Show student avatar only if counselor is viewing the chat
            if (widget.isCounselor && _otherUserRole == 'student')
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: StudentAvatar(
                  userId: widget.appointment.userId,
                  radius: 20,
                  fallbackName: _otherUserName,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUserName ?? 'Loading...',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  if (_otherUserRole != null)
                    Text(
                      _otherUserRole!.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          key: const Key('backButton'),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start the conversation',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe = message['sender_id'] ==
                                  _supabase.auth.currentUser?.id;

                              return _MessageBubble(
                                message: message['message'],
                                isMe: isMe,
                                timestamp:
                                    DateTime.parse(message['created_at']),
                                senderName: message['sender_name'] ?? 'Unknown',
                              );
                            },
                          ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
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
                  child: TextField(
                    key: const Key('chatInputField'),
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F7),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('sendMessageButton'),
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: const Color(0xFF5D5D72),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String senderName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF5D5D72) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                senderName.isNotEmpty
                    ? senderName[0].toUpperCase() + senderName.substring(1)
                    : '',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message,
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : const Color(0xFF3A3A50),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              TimeOfDay(hour: timestamp.hour, minute: timestamp.minute)
                  .format(context),
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
