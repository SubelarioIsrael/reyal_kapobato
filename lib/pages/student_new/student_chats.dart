import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/counselor_avatar.dart';
import '../../controllers/student_chats_controller.dart';
import '../chat/direct_chat.dart';

class StudentChats extends StatefulWidget {
  const StudentChats({super.key});

  @override
  State<StudentChats> createState() => _StudentChatsState();
}

class _StudentChatsState extends State<StudentChats> {
  final StudentChatsController _controller = StudentChatsController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _counselorChats = [];
  List<Map<String, dynamic>> _filteredChats = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _studentDepartment;

  @override
  void initState() {
    super.initState();
    _fetchCounselorChats();
    _controller.subscribeToMessages(_fetchCounselorChats);
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
      _filteredChats = _controller.searchCounselors(_counselorChats, _searchController.text);
    });
  }

  Future<void> _fetchCounselorChats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get student's department
      _studentDepartment = await _controller.getStudentDepartment();

      if (_studentDepartment == null) {
        setState(() {
          _errorMessage = 'Unable to determine your department';
          _isLoading = false;
        });
        return;
      }

      // Load chats from counselors in the same department
      final chats = await _controller.loadCounselorChats(_studentDepartment!);

      setState(() {
        _counselorChats = chats;
        _filteredChats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching chats: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildChatCard(Map<String, dynamic> chat, int index) {
    return Container(
      key: Key('studentChatCard_$index'),
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
          // Navigate to direct chat (no appointment needed)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DirectChat(
                otherUserId: chat['counselor_user_id'],
                otherUserName: chat['counselor_name'],
                isCounselor: false,
                counselorId: chat['counselor_id'],
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
      key: const Key('studentChatsScreen'),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          key: const Key('backButton'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                          hintText: 'Search counselors...',
                          hintStyle: GoogleFonts.inter(
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
                      child: _filteredChats.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: const Color(0xFF7C83FD),
                              onRefresh: _fetchCounselorChats,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                itemCount: _filteredChats.length,
                                itemBuilder: (context, index) {
                                  final chat = _filteredChats[index];
                                  return _buildChatCard(chat, index);
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
      child: Padding(
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
                  color: const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Error Loading Chats',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'An unexpected error occurred',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _fetchCounselorChats,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
    
    return Center(
      child: Padding(
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
                    : 'Conversations with counselors will appear here when you have accepted appointments',
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
    );
  }
}
