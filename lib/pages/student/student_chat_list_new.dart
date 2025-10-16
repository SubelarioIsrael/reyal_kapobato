import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat_message_service.dart';
import '../../widgets/counselor_avatar.dart';

class StudentChatList extends StatefulWidget {
  const StudentChatList({super.key});

  @override
  State<StudentChatList> createState() => _StudentChatListState();
}

class _StudentChatListState extends State<StudentChatList> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _counselorChats = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Bottom navigation
  int _selectedIndex = 1; // Default to home tab

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/student-breathing-exercises');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/student-home');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/student-daily-checkin');
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCounselorChats();
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
        .channel('student_chat_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            print('StudentChatList: New message received, refreshing chat list');
            _loadCounselorChats();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            print('StudentChatList: Message updated, refreshing chat list');
            _loadCounselorChats();
          },
        )
        .subscribe();
  }

  Future<void> _loadCounselorChats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('StudentChatList: Loading chats for student user_id: ${currentUser.id}');

      // Get accepted appointments for this student first
      final acceptedAppointments = await _supabase
          .from('counseling_appointments')
          .select('appointment_id, counselor_id, user_id, appointment_date, start_time, end_time, status, notes, status_message')
          .eq('user_id', currentUser.id)
          .eq('status', 'accepted'); // Only show accepted appointments

      print('StudentChatList: Found ${acceptedAppointments.length} accepted appointments');

      if (acceptedAppointments.isEmpty) {
        setState(() {
          _counselorChats = [];
          _isLoading = false;
        });
        return;
      }

      final appointmentIds = acceptedAppointments.map((a) => a['appointment_id']).toList();

      // Get messages for accepted appointments
      final appointmentsWithMessages = await _supabase
          .from('messages')
          .select('appointment_id, sender_id, receiver_id, created_at, message, is_read')
          .inFilter('appointment_id', appointmentIds)
          .order('created_at', ascending: false);

      print('StudentChatList: Found ${appointmentsWithMessages.length} messages for appointments');

      // Create appointment groups for all accepted appointments
      Map<int, Map<String, dynamic>> appointmentGroups = {};
      Set<int> uniqueCounselorIds = {};

      // Initialize groups for all accepted appointments
      for (var appointment in acceptedAppointments) {
        final appointmentId = appointment['appointment_id'];
        final counselorId = appointment['counselor_id'];
        
        appointmentGroups[appointmentId] = {
          'appointment': appointment,
          'counselor_id': counselorId,
          'counselor_name': 'Loading...',
          'counselor_user_id': null,
          'appointment_id': appointmentId,
          'messages': [],
          'unread_count': 0,
          'last_message': null,
          'last_message_time': null,
        };
        uniqueCounselorIds.add(counselorId);
      }

      // Add messages to their respective appointment groups
      for (var message in appointmentsWithMessages) {
        final appointmentId = message['appointment_id'];
        
        if (appointmentGroups.containsKey(appointmentId)) {
          // Add message to group
          appointmentGroups[appointmentId]!['messages'].add(message);

          // Update last message if this is more recent
          final messageTime = DateTime.parse(message['created_at']);
          if (appointmentGroups[appointmentId]!['last_message_time'] == null ||
              messageTime.isAfter(appointmentGroups[appointmentId]!['last_message_time'])) {
            appointmentGroups[appointmentId]!['last_message'] = message['message'];
            appointmentGroups[appointmentId]!['last_message_time'] = messageTime;
          }

          // Count unread messages (from counselor to student)
          if (message['receiver_id'] == currentUser.id && !message['is_read']) {
            appointmentGroups[appointmentId]!['unread_count']++;
          }
        }
      }

      // Fetch counselor information for each unique counselor ID
      for (var appointmentGroup in appointmentGroups.values) {
        final counselorId = appointmentGroup['counselor_id'];

        try {
          print('StudentChatList: Fetching counselor details for counselor_id: $counselorId');
          
          // Get counselor info including user_id for avatar
          final counselorInfo = await _supabase
              .from('counselors')
              .select('first_name, last_name, user_id')
              .eq('counselor_id', counselorId)
              .maybeSingle();

          print('StudentChatList: Counselor response for ID $counselorId: $counselorInfo');

          if (counselorInfo != null &&
              counselorInfo['first_name'] != null &&
              counselorInfo['last_name'] != null &&
              counselorInfo['first_name'].isNotEmpty &&
              counselorInfo['last_name'].isNotEmpty) {
            
            final firstName = counselorInfo['first_name'];
            final lastName = counselorInfo['last_name'];
            final userId = counselorInfo['user_id'];

            // Helper function to properly capitalize names
            String formatName(String name) {
              if (name.isEmpty) return name;
              return name[0].toUpperCase() + name.substring(1);
            }

            appointmentGroup['counselor_name'] = 'Dr. ${formatName(firstName)} ${formatName(lastName)}';
            appointmentGroup['counselor_user_id'] = userId;
            
            print('StudentChatList: Set counselor name: ${appointmentGroup['counselor_name']}, user_id: $userId');
          } else {
            print('StudentChatList: No counselor found for counselor_id: $counselorId');
            appointmentGroup['counselor_name'] = 'Unknown Counselor';
            appointmentGroup['counselor_user_id'] = null;
          }
        } catch (e) {
          print('StudentChatList: Error fetching counselor info for counselor_id $counselorId: $e');
          appointmentGroup['counselor_name'] = 'Unknown Counselor';
          appointmentGroup['counselor_user_id'] = null;
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

      // Transform to final format
      final transformedChats = appointmentsList.map((appointmentData) {
        return {
          'counselor_id': appointmentData['counselor_id'],
          'counselor_name': appointmentData['counselor_name'],
          'counselor_user_id': appointmentData['counselor_user_id'],
          'appointment_id': appointmentData['appointment_id'],
          'last_message': appointmentData['last_message'] ?? 'Chat started',
          'last_message_time': appointmentData['last_message_time']?.toIso8601String(),
          'is_read': appointmentData['unread_count'] == 0,
          'unread_count': appointmentData['unread_count'],
        };
      }).toList();

      setState(() {
        _counselorChats = transformedChats;
        _isLoading = false;
      });

      print('StudentChatList: Successfully loaded ${transformedChats.length} counselor chats');
    } catch (e) {
      print('StudentChatList: Error loading counselor chats: $e');
      setState(() {
        _errorMessage = 'Error loading chats: $e';
        _isLoading = false;
      });
    }
  }

  void _openChat(Map<String, dynamic> chatData) {
    final appointmentId = chatData['appointment_id'];
    final counselorName = chatData['counselor_name'];
    final counselorId = chatData['counselor_id'];

    try {
      print('StudentChatList: Opening chat for appointment: $appointmentId, counselor: $counselorName');

      if (appointmentId == null) {
        throw Exception('Missing appointment ID');
      }

      // Mark messages as read immediately when opening chat
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        ChatMessageService.markAppointmentMessagesAsRead(appointmentId).then((_) {
          print('StudentChatList: Marked appointment $appointmentId messages as read for student');
        }).catchError((e) {
          print('StudentChatList: Error marking messages as read: $e');
        });
      }

      Navigator.pushNamed(
        context,
        '/appointment-chat',
        arguments: {
          'appointmentId': appointmentId,
          'counselorName': counselorName,
          'counselorId': counselorId,
        },
      ).then((_) {
        // Refresh the list when returning from chat
        print('StudentChatList: Returned from chat, refreshing list');
        _loadCounselorChats();
      });
    } catch (e) {
      print('StudentChatList: Error opening chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
    final counselorId = chat['counselor_id'] as int?;
    final counselorUserId = chat['counselor_user_id'] as String?;
    final counselorName = chat['counselor_name'] as String? ?? 'Unknown Counselor';
    final lastMessage = chat['last_message'] as String? ?? 'No messages yet';
    final lastMessageTime = chat['last_message_time'] as String?;
    final isRead = chat['is_read'] as bool? ?? true;
    final unreadCount = chat['unread_count'] as int? ?? 0;
    final hasUnread = unreadCount > 0;

    print('StudentChatList: Building chat card - counselor: $counselorName, user_id: $counselorUserId, has_unread: $hasUnread');

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
        onTap: () => _openChat(chat),
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
                      child: counselorUserId != null && counselorUserId.isNotEmpty
                          ? CounselorAvatar(
                              userId: counselorUserId,
                              radius: 30,
                              fallbackName: counselorName,
                            )
                          : CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFF7C83FD).withOpacity(0.2),
                              child: Text(
                                counselorName.isNotEmpty ? counselorName[0].toUpperCase() : 'C',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7C83FD),
                                ),
                              ),
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
                            counselorName,
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
                      lastMessage,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF718096),
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
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
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "My Chats",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C83FD),
              ),
            )
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
                        style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCounselorChats,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C83FD),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                    ],
                  ),
                )
              : _counselorChats.isEmpty
                  ? RefreshIndicator(
                      color: const Color(0xFF7C83FD),
                      onRefresh: _loadCounselorChats,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
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
                                'Your conversations with counselors will appear here',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF718096),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF7C83FD),
                      onRefresh: _loadCounselorChats,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: _counselorChats
                              .map((chat) => _buildChatCard(chat))
                              .toList(),
                        ),
                      ),
                    ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF7C83FD),
        unselectedItemColor: const Color(0xFFB0B0C3),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.self_improvement),
              label: 'Breathing Exercises'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_emotions), label: 'Track Mood'),
        ],
      ),
    );
  }
}