import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDrawer extends StatefulWidget {
  const StudentDrawer({super.key});

  @override
  State<StudentDrawer> createState() => _StudentDrawerState();
}

class _StudentDrawerState extends State<StudentDrawer> {
  String _firstName = '';
  String _lastName = '';
  String? _profilePicture;
  String _studentCode = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Get profile picture from users table
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('profile_picture')
          .eq('user_id', userId)
          .maybeSingle();

      // Get student data from students table
      final studentResponse = await Supabase.instance.client
          .from('students')
          .select('first_name, last_name, student_code')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _firstName = studentResponse?['first_name'] ?? '';
          _lastName = studentResponse?['last_name'] ?? '';
          _profilePicture = userResponse?['profile_picture'];
          _studentCode = studentResponse?['student_code'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading student data: $e');
      if (mounted) {
        setState(() {
          _firstName = 'Student';
          _lastName = '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 180,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7C83FD),
                  Color(0xFF9BA3FF),
                ],
              ),
            ),
            child: Column(
              children: [
                // App Logo and Title - Centered
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),
                    Text(
                      'BreatheBetter',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Profile Section
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white,
                              backgroundImage: _profilePicture != null && _profilePicture!.isNotEmpty
                                  ? MemoryImage(base64Decode(_profilePicture!))
                                  : null,
                              child: _profilePicture == null || _profilePicture!.isEmpty
                                  ? Text(
                                      _getInitials(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF7C83FD),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _firstName.isNotEmpty ? _firstName : 'Student',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_lastName.isNotEmpty) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      _lastName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  if (_studentCode.isNotEmpty)
                                    Text(
                                      'ID: $_studentCode',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home_rounded,
            title: 'Home',
            onTap: () {
              Navigator.pushReplacementNamed(context, 'student-home');
            },
          ),
          _buildDrawerItem(
            icon: Icons.person_rounded,
            title: 'Profile',
            onTap: () {
              Navigator.pushNamed(context, '/student-profile');
            },
          ),
          _buildDrawerItem(
            key: const Key('chatbot_item'),
            icon: Icons.chat_bubble_rounded,
            title: 'Chatbot',
            onTap: () {
              Navigator.pushNamed(context, 'student-chatbot');
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings_rounded,
            title: 'Settings',
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const SizedBox(height: 240), // Push content down (adjusted for 4 menu items)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Divider(color: Color(0xFFE5E5E5)),
          ),
          _buildDrawerItem(
            key: const Key('logout_button'),
            icon: Icons.logout_rounded,
            title: 'Logout',
            iconColor: Colors.red[400]!,
            textColor: Colors.red[400]!,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    Key? key,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final defaultColor = const Color(0xFF3A3A50);
    final finalIconColor = iconColor ?? defaultColor;
    final finalTextColor = textColor ?? defaultColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: finalIconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: finalIconColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: finalTextColor,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        horizontalTitleGap: 12,
      ),
    );
  }

  String _getInitials() {
    String initials = '';
    if (_firstName.isNotEmpty) {
      initials += _firstName[0].toUpperCase();
    }
    if (_lastName.isNotEmpty) {
      initials += _lastName[0].toUpperCase();
    }
    return initials.isNotEmpty ? initials : 'S';
  }
}
