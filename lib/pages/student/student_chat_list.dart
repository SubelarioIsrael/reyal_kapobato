import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appointment.dart';
import '../chat/appointment_chat.dart';

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
    _loadCounselorChats();
  }

  Future<void> _loadCounselorChats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }
      print('Current User ID: $currentUserId'); // Debug print

      // Fetch all appointments for the current student
      final allAppointmentsResponse = await _supabase
          .from('counseling_appointments')
          .select('counselor_id')
          .eq('user_id', currentUserId);

      final Set<int> uniqueCounselorIds = (allAppointmentsResponse as List)
          .map((e) => e['counselor_id'] as int)
          .toSet(); // Get unique counselor IDs

      final List<int> counselorIds = uniqueCounselorIds.toList();
      print(
          'Unique Counselor IDs with appointments: $counselorIds'); // Debug print

      final List<Map<String, dynamic>> counselorChatsData = [];

      for (int counselorId in counselorIds) {
        // Fetch counselor details (user_id, first_name, last_name)
        final counselorDetails = await _supabase
            .from('counselors')
            .select('user_id, first_name, last_name')
            .eq('counselor_id', counselorId)
            .single();

        final counselorUserId = counselorDetails['user_id'].toString();
        final counselorUsername =
            '${counselorDetails['first_name'] ?? ''} ${counselorDetails['last_name'] ?? ''}'
                .trim();
        print(
            'Processing Counselor: $counselorUsername (Counselor ID: $counselorId, User ID: $counselorUserId)'); // Debug print

        // Find the latest message between this student and this counselor
        final lastMessageResponse = await _supabase
            .from('messages')
            .select('message, created_at, appointment_id')
            .or(
              'and(sender_id.eq.$currentUserId,receiver_id.eq.$counselorUserId),and(sender_id.eq.$counselorUserId,receiver_id.eq.$currentUserId)',
            )
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        String lastMessage = 'No messages yet';
        DateTime? lastMessageTime;
        int?
            appointmentIdForChat; // Use the appointment_id from the latest message

        if (lastMessageResponse != null) {
          lastMessage = lastMessageResponse['message'];
          lastMessageTime = DateTime.parse(lastMessageResponse['created_at']);
          appointmentIdForChat = lastMessageResponse['appointment_id'];
          print(
              'Found last message for $counselorUsername: $lastMessage at $lastMessageTime (Appointment ID: $appointmentIdForChat)'); // Debug print
        } else {
          print(
              'No messages found for $counselorUsername. Looking for latest accepted appointment.'); // Debug print
          // If no messages, find the latest accepted appointment with this counselor
          final latestAcceptedAppt = await _supabase
              .from('counseling_appointments')
              .select('appointment_id')
              .eq('user_id', currentUserId)
              .eq('counselor_id', counselorId)
              .eq('status',
                  'accepted') // Only consider accepted appointments for new chats
              .order('appointment_date', ascending: false)
              .limit(1)
              .maybeSingle();
          if (latestAcceptedAppt != null) {
            appointmentIdForChat = latestAcceptedAppt['appointment_id'];
            print(
                'Found latest accepted appointment for $counselorUsername: $appointmentIdForChat'); // Debug print
          }
        }

        if (appointmentIdForChat != null) {
          counselorChatsData.add({
            'counselor_id': counselorId,
            'counselor_username': counselorUsername,
            'counselor_user_id': counselorUserId,
            'last_message': lastMessage,
            'last_message_time': lastMessageTime,
            'appointment_id': appointmentIdForChat,
          });
        }
      }

      setState(() {
        _counselorChats = counselorChatsData;
        _counselorChats.sort((a, b) {
          final timeA = a['last_message_time'] as DateTime?;
          final timeB = b['last_message_time'] as DateTime?;
          if (timeA != null && timeB != null) {
            return timeB.compareTo(timeA); // Newest message first
          } else if (timeA != null) {
            return -1;
          } else if (timeB != null) {
            return 1;
          } else {
            return a['counselor_username'].compareTo(b['counselor_username']);
          }
        });
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading counselor chats: $e');
      setState(() {
        _errorMessage = 'Error loading chats: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(child: Text(_errorMessage!))
            else if (_counselorChats.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No chats yet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a conversation with a counselor through an accepted appointment.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _counselorChats.length,
                  itemBuilder: (context, index) {
                    final chat = _counselorChats[index];
                    final Appointment dummyAppointment = Appointment(
                      id: chat['appointment_id'],
                      counselorId: chat['counselor_id'] as int,
                      userId: _supabase.auth.currentUser!.id,
                      appointmentDate:
                          DateTime.now(), // Placeholder, not used for chat
                      startTime: DateTime.now(), // Placeholder
                      endTime: DateTime.now(), // Placeholder
                      status: 'accepted', // Assume accepted for chat
                      counselorName: chat['counselor_username'],
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF7C83FD),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          chat['counselor_username'] != null &&
                                  chat['counselor_username'].isNotEmpty
                              ? chat['counselor_username'][0].toUpperCase() +
                                  chat['counselor_username'].substring(1)
                              : '',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          chat['last_message'],
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: chat['last_message_time'] != null
                            ? Text(
                                TimeOfDay(
                                        hour: chat['last_message_time'].hour,
                                        minute:
                                            chat['last_message_time'].minute)
                                    .format(context),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentChat(
                                appointment: dummyAppointment,
                                isCounselor: false,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
