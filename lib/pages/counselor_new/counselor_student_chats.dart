import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/student_avatar.dart';
import '../../controllers/counselor_student_chats_controller.dart';
import '../chat/direct_chat.dart';

class CounselorStudentChats extends StatefulWidget {
  const CounselorStudentChats({super.key});

  @override
  State<CounselorStudentChats> createState() => _CounselorStudentChatsState();
}

class _CounselorStudentChatsState extends State<CounselorStudentChats> {
  final CounselorStudentChatsController _controller = CounselorStudentChatsController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _appointmentsWithMessages = [];
  List<Map<String, dynamic>> _filteredAppointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _counselorDepartment;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _controller.subscribeToMessages(_loadChats);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredAppointments = _controller.searchStudents(_appointmentsWithMessages, _searchController.text);
    });
  }

  Future<void> _loadChats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final counselorInfo = await _controller.getCounselorInfo();
      if (counselorInfo == null) {
        throw Exception('Counselor information not found');
      }

      final counselorId = counselorInfo['counselor_id'] as int;
      _counselorDepartment = counselorInfo['department'] as String?;

      final chats = await _controller.loadAppointmentsWithMessages(counselorId, _counselorDepartment);

      setState(() {
        _appointmentsWithMessages = chats;
        _filteredAppointments = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading chats: $e';
        _isLoading = false;
      });
    }
  }

  void _openChat(Map<String, dynamic> appointmentData) {
    final appointmentInfo = appointmentData['appointment'];
    final studentUserId = appointmentInfo['user_id'];
    final studentName = appointmentData['user_name'];

    // Navigate to direct chat (no appointment needed)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectChat(
          otherUserId: studentUserId,
          otherUserName: studentName,
          isCounselor: true,
          studentUserId: studentUserId,
        ),
      ),
    ).then((_) => _loadChats());
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF718096),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF7C83FD),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),

                    // Chat List
                    Expanded(
                      child: _filteredAppointments.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadChats,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                itemCount: _filteredAppointments.length,
                                itemBuilder: (context, index) {
                                  final appointmentData = _filteredAppointments[index];
                                  return _buildChatCard(appointmentData);
                                },
                              ),
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
            onPressed: _loadChats,
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
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
    
    return Padding(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C83FD).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.chat_bubble_outline,
                size: 48,
                color: const Color(0xFF7C83FD),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? 'No Results Found' : 'No Conversations Yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try adjusting your search terms'
                  : 'Student conversations from your assigned department will appear here when they send messages',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
              // Profile Avatar with unread indicator (no purple background)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: StudentAvatar(
                      userId: appointmentData['appointment']['user_id'],
                      radius: 30,
                      fallbackName: userName,
                    ),
                  ),
                  // Unread indicator on avatar
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
}
