import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/student_avatar.dart';
import '../../widgets/counselor_avatar.dart';

/// Direct chat between counselor and student without appointment requirement
class DirectChat extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final bool isCounselor;
  final int? counselorId; // For counselor avatar
  final String? studentUserId; // For student avatar

  const DirectChat({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.isCounselor,
    this.counselorId,
    this.studentUserId,
  });

  @override
  State<DirectChat> createState() => _DirectChatState();
}

class _DirectChatState extends State<DirectChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Load messages between current user and other user (no appointment_id required)
      final response = await _supabase
          .from('messages')
          .select('*')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .or('sender_id.eq.${widget.otherUserId},receiver_id.eq.${widget.otherUserId}')
          .isFilter('appointment_id', null) // Only get direct messages (no appointment)
          .order('created_at', ascending: true);

      // Filter to only messages between these two users
      final filteredMessages = (response as List).where((msg) {
        return (msg['sender_id'] == currentUserId && msg['receiver_id'] == widget.otherUserId) ||
               (msg['sender_id'] == widget.otherUserId && msg['receiver_id'] == currentUserId);
      }).toList();

      setState(() {
        _messages = filteredMessages.map((m) => Map<String, dynamic>.from(m)).toList();
        _isLoading = false;
      });

      // Mark messages as read
      await _markMessagesAsRead();

      // Scroll to bottom
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
      print('Error loading messages: $e');
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

      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', currentUserId)
          .eq('sender_id', widget.otherUserId)
          .isFilter('appointment_id', null)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _setupRealtimeSubscription() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    _supabase
        .channel('direct_chat_${currentUserId}_${widget.otherUserId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newMessage = payload.newRecord;
            
            // Check if message is between these two users and has no appointment_id
            if (newMessage['appointment_id'] == null &&
                ((newMessage['sender_id'] == currentUserId && newMessage['receiver_id'] == widget.otherUserId) ||
                 (newMessage['sender_id'] == widget.otherUserId && newMessage['receiver_id'] == currentUserId))) {
              setState(() {
                _messages.add(Map<String, dynamic>.from(newMessage));
              });

              // Auto-scroll to bottom
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });

              // Mark as read if we're the receiver
              if (newMessage['receiver_id'] == currentUserId) {
                _markMessagesAsRead();
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Send message without appointment_id
      await _supabase.from('messages').insert({
        'sender_id': currentUserId,
        'receiver_id': widget.otherUserId,
        'message': messageText,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'is_read': false,
        'message_type': 'text',
        'appointment_id': null, // Explicitly null for direct messages
      });

      _messageController.clear();

      // Scroll to bottom
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
      print('Error sending message: $e');
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar
            if (widget.isCounselor && widget.studentUserId != null)
              StudentAvatar(
                userId: widget.studentUserId!,
                radius: 20,
                fallbackName: widget.otherUserName,
              )
            else if (!widget.isCounselor && widget.counselorId != null)
              CounselorAvatar(
                counselorId: widget.counselorId!,
                radius: 20,
                fallbackName: widget.otherUserName,
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF7C83FD),
                child: Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.isCounselor ? 'Student' : 'Counselor',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Messages List
                    Expanded(
                      child: _messages.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isMe = message['sender_id'] == _supabase.auth.currentUser?.id;
                                return _buildMessageBubble(message, isMe);
                              },
                            ),
                    ),

                    // Message Input
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: GoogleFonts.poppins(
                                  color: const Color(0xFF718096),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF7FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C83FD),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final timestamp = DateTime.parse(message['created_at']);
    final timeString = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF7C83FD) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['message'],
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isMe ? Colors.white : const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeString,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isMe ? Colors.white.withOpacity(0.8) : const Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Messages',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF718096),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMessages,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C83FD),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
