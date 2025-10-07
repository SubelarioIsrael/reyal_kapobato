import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchCounselorChats();
  }

  Future<void> _fetchCounselorChats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Start with all accepted appointments for this student
      final acceptedAppointments = await _supabase
          .from('counseling_appointments')
          .select('appointment_id, counselor_id, appointment_date')
          .eq('user_id', user.id)
          .eq('status', 'accepted')
          .order('appointment_date', ascending: false);

      if (acceptedAppointments.isEmpty) {
        setState(() {
          _counselorChats = [];
          _isLoading = false;
        });
        return;
      }

      // Get appointment IDs for message lookup
      final appointmentIds =
          acceptedAppointments.map((a) => a['appointment_id'] as int).toList();

      // Fetch messages for these appointments
      final messages = await _supabase
          .from('messages')
          .select(
              'id, message, created_at, is_read, appointment_id, sender_id, receiver_id')
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
          .inFilter('appointment_id', appointmentIds)
          .order('created_at', ascending: false);

      // Group by counselor and create chat entries
      Map<int, Map<String, dynamic>> counselorChatsMap = {};

      for (var appointment in acceptedAppointments) {
        final appointmentId = appointment['appointment_id'] as int;
        final counselorId = appointment['counselor_id'] as int;

        // Skip if we already processed this counselor
        if (counselorChatsMap.containsKey(counselorId)) {
          continue;
        }

        try {
          // Get counselor details
          final counselorResponse = await _supabase
              .from('counselors')
              .select('first_name, last_name')
              .eq('counselor_id', counselorId)
              .single();

          // Find the latest message for this appointment (if any)
          final appointmentMessages = messages
              .where((m) => m['appointment_id'] == appointmentId)
              .toList();

          String lastMessage;
          String? lastMessageTime;
          bool isRead = true;

          if (appointmentMessages.isNotEmpty) {
            final latestMessage = appointmentMessages.first;
            lastMessage = latestMessage['message'];
            lastMessageTime = latestMessage['created_at'];
            // Check if latest message is unread and received by student
            isRead = (latestMessage['is_read'] ?? true) ||
                latestMessage['receiver_id'] != user.id;
          } else {
            // No messages yet - show default message
            lastMessage = 'Appointment accepted - Start chatting!';
            lastMessageTime = appointment[
                'appointment_date']; // Use appointment date as fallback
          }

          counselorChatsMap[counselorId] = {
            'counselor_id': counselorId,
            'counselor_name':
                '${counselorResponse['first_name']} ${counselorResponse['last_name']}',
            'appointment_id': appointmentId,
            'last_message': lastMessage,
            'last_message_time': lastMessageTime,
            'is_read': isRead,
          };
        } catch (e) {
          // Skip this counselor if we can't fetch their details
          print(
              'Error fetching counselor details for counselor_id $counselorId: $e');
        }
      }

      setState(() {
        _counselorChats = counselorChatsMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching chats: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
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
        onTap: () {
          Navigator.pushNamed(
            context,
            '/appointment-chat',
            arguments: {
              'appointmentId': chat['appointment_id'],
              'counselorName': chat['counselor_name'] ?? 'Unknown Counselor',
            },
          ).then((_) => _fetchCounselorChats());
        },
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C83FD), Color(0xFF9B59B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C83FD).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        chat['counselor_name']?[0]?.toUpperCase() ?? 'C',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Unread indicator
                  if (!(chat['is_read'] ?? true))
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
                            chat['counselor_name'] ?? 'Unknown Counselor',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat['last_message_time'] != null)
                          Text(
                            _formatTime(chat['last_message_time']),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF718096),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      chat['last_message'] ?? 'No messages yet',
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

              // Arrow Icon
              const SizedBox(width: 12),
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
          : RefreshIndicator(
              color: const Color(0xFF7C83FD),
              onRefresh: _fetchCounselorChats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7C83FD).withOpacity(0.1),
                            const Color(0xFFBCF5BC).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF7C83FD).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C83FD).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
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
                                  'Your Conversations',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Connect with your counselors',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF718096),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                  color: Colors.red[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Empty State
                    if (_counselorChats.isEmpty && _errorMessage == null)
                      Container(
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

                    // Chat List
                    if (_counselorChats.isNotEmpty)
                      Column(
                        children: _counselorChats
                            .map((chat) => _buildChatCard(chat))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
