import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../chat/appointment_chat.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchCounselorChats();
  }

  Future<void> _fetchCounselorChats() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Start with all accepted appointments for this student
      final acceptedAppointments = await _supabase
          .from('counseling_appointments')
          .select('appointment_id, counselor_id, user_id, appointment_date, start_time, end_time, status, notes')
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
            'appointment_data': appointment, // Store full appointment data
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
        _isLoading = false;
      });
    }
  }

  Widget _buildChatCard(Map<String, dynamic> chat, int index) {
    return Container(
      key: Key('studentChatCard_$index'), // <-- Added for test
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
          final appointmentData = chat['appointment_data'];
          final appointment = Appointment.fromJson({
            ...appointmentData,
            'counselor_name': chat['counselor_name'],
          });
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentChat(
                appointment: appointment,
                isCounselor: false,
              ),
            ),
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
                      child: CounselorAvatar(
                        counselorId: chat['counselor_id'],
                        radius: 30,
                        fallbackName: chat['counselor_name'] ?? 'Counselor',
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
      key: const Key('studentChatListScreen'), // <-- Added for test
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          key: const Key('backButton'),
          icon: Icon(Icons.arrow_back_ios_new_rounded), // or Icons.arrow_back
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "My Chats",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
              child: ListView.builder(
                itemCount: _counselorChats.length,
                itemBuilder: (context, index) {
                  final chat = _counselorChats[index];
                  return _buildChatCard(chat, index); // Pass index for key
                },
              ),
            ),
    );
  }
}
