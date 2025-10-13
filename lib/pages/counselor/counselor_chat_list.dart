import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../chat/appointment_chat.dart';
import '../../widgets/student_avatar.dart';

class CounselorChatList extends StatefulWidget {
  const CounselorChatList({super.key});

  @override
  State<CounselorChatList> createState() => _CounselorChatListState();
}

class _CounselorChatListState extends State<CounselorChatList> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _appointmentsWithMessages = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppointmentsWithMessages();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _supabase.removeAllChannels();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    // Listen for new messages to update the chat list
    _supabase
        .channel('counselor_chat_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            print('New message received, refreshing chat list'); // Debug log
            _loadAppointmentsWithMessages();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            print('Message updated, refreshing chat list'); // Debug log
            _loadAppointmentsWithMessages();
          },
        )
        .subscribe();
  }

  Future<void> _loadAppointmentsWithMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get counselor ID
      final counselorResponse = await _supabase
          .from('counselors')
          .select('counselor_id')
          .eq('user_id', currentUser.id)
          .single();

      final counselorId = counselorResponse['counselor_id'];

      // Get all appointments that have messages - use separate query for student info since
      // there's no direct FK between counseling_appointments and students
      final appointmentsWithMessages = await _supabase
          .from('messages')
          .select('''
            appointment_id,
            sender_id,
            receiver_id,
            created_at,
            message,
            is_read,
            counseling_appointments!inner(
              appointment_id,
              counselor_id,
              user_id,
              appointment_date,
              start_time,
              end_time,
              status,
              notes
            )
          ''')
          .eq('counseling_appointments.counselor_id', counselorId)
          .order('created_at', ascending: false);

      // Group messages by appointment_id first
      Map<int, Map<String, dynamic>> appointmentGroups = {};
      Set<String> uniqueUserIds = {};

      for (var message in appointmentsWithMessages) {
        final appointmentId = message['appointment_id'];
        final appointment = message['counseling_appointments'];

        if (!appointmentGroups.containsKey(appointmentId)) {
          appointmentGroups[appointmentId] = {
            'appointment': appointment,
            'user_name': 'Unknown User',
            'user_initials': 'UU',
            'messages': [],
            'unread_count': 0,
            'last_message': null,
            'last_message_time': null,
          };
          uniqueUserIds.add(appointment['user_id']);
        }

        // Add message to group
        appointmentGroups[appointmentId]!['messages'].add(message);

        // Update last message if this is more recent
        final messageTime = DateTime.parse(message['created_at']);
        if (appointmentGroups[appointmentId]!['last_message_time'] == null ||
            messageTime.isAfter(
                appointmentGroups[appointmentId]!['last_message_time'])) {
          appointmentGroups[appointmentId]!['last_message'] =
              message['message'];
          appointmentGroups[appointmentId]!['last_message_time'] = messageTime;
        }

        // Count unread messages (from student to counselor)
        if (message['receiver_id'] == currentUser.id && !message['is_read']) {
          appointmentGroups[appointmentId]!['unread_count']++;
        }
      }

      // Fetch student information for each unique user ID
      for (var appointmentGroup in appointmentGroups.values) {
        final userId = appointmentGroup['appointment']['user_id'];

        try {
          // First try to get student info
          final studentInfo = await _supabase
              .from('students')
              .select('user_id, first_name, last_name, student_code')
              .eq('user_id', userId)
              .maybeSingle();

          if (studentInfo != null &&
              studentInfo['first_name'] != null &&
              studentInfo['last_name'] != null &&
              studentInfo['first_name'].isNotEmpty &&
              studentInfo['last_name'].isNotEmpty) {
            final firstName = studentInfo['first_name'];
            final lastName = studentInfo['last_name'];

            // Helper function to properly capitalize names (keeps internal capitals)
            String formatName(String name) {
              if (name.isEmpty) return name;
              return name[0].toUpperCase() + name.substring(1);
            }

            appointmentGroup['user_name'] =
                '${formatName(firstName)} ${formatName(lastName)}';
            appointmentGroup['user_initials'] =
                '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}';
          } else {
            // Fallback to username if student info not found
            try {
              final userInfo = await _supabase
                  .from('users')
                  .select('email')
                  .eq('user_id', userId)
                  .maybeSingle();

              if (userInfo != null && userInfo['email'] != null) {
                final email = userInfo['email'];
                appointmentGroup['user_name'] = email;
                appointmentGroup['user_initials'] = email.length >= 2
                    ? email.substring(0, 2).toUpperCase()
                    : email[0].toUpperCase();
              }
            } catch (e) {
              print('Error fetching username for user_id $userId: $e');
            }
          }
        } catch (e) {
          print('Error fetching student info for user_id $userId: $e');
        }
      }

      // Convert to list and sort by last message time
      final appointmentsList = appointmentGroups.values.toList();
      appointmentsList.sort((a, b) {
        final timeA = a['last_message_time'] as DateTime?;
        final timeB = b['last_message_time'] as DateTime?;
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); // Most recent first
      });

      setState(() {
        _appointmentsWithMessages = appointmentsList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading appointments with messages: $e');
      setState(() {
        _errorMessage = 'Error loading chats: $e';
        _isLoading = false;
      });
    }
  }

  void _openChat(Map<String, dynamic> appointmentData) {
    final appointmentInfo = appointmentData['appointment'];

    final appointment = Appointment.fromJson({
      ...appointmentInfo,
      'user_id': appointmentInfo['user_id'],
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentChat(
          appointment: appointment,
          isCounselor: true,
        ),
      ),
    ).then((_) {
      // Refresh the list when returning from chat
      _loadAppointmentsWithMessages();
    });
  }

  Widget _buildChatCard(Map<String, dynamic> appointmentData) {
    final unreadCount = appointmentData['unread_count'] as int;
    final lastMessage = appointmentData['last_message'] as String?;
    final lastMessageTime = appointmentData['last_message_time'] as DateTime?;
    final userName = appointmentData['user_name'] as String;
    final hasUnread = unreadCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openChat(appointmentData),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Profile Avatar with unread indicator
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C83FD).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: StudentAvatar(
                        userId: appointmentData['appointment']['user_id'],
                        radius: 30,
                        fallbackName: userName,
                      ),
                    ),
                  ),
                  // Unread indicator
                  if (hasUnread)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Chat Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessageTime != null)
                          Text(
                            _formatTime(lastMessageTime),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF718096),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastMessage ?? 'Appointment chat started',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF718096),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Arrow Icon with unread count
              const SizedBox(width: 12),
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C83FD).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF7C83FD),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${(difference.inDays / 7).floor()}w ago';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        title: Text(
          'Student Chats',
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Chats',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAppointmentsWithMessages,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D5D72),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                )
              : _appointmentsWithMessages.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C83FD).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Color(0xFF7C83FD),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Conversations Yet',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Student conversations will appear here when they send messages',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF718096),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAppointmentsWithMessages,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: _appointmentsWithMessages
                              .map((appointmentData) =>
                                  _buildChatCard(appointmentData))
                              .toList(),
                        ),
                      ),
                    ),
    );
  }
}
