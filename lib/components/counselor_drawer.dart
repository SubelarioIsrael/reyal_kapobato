import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CounselorDrawer extends StatefulWidget {
  const CounselorDrawer({super.key});

  @override
  State<CounselorDrawer> createState() => _CounselorDrawerState();
}

class _CounselorDrawerState extends State<CounselorDrawer> {
  String _firstName = '';
  String _lastName = '';
  String? _profilePicture;
  String _specialization = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCounselorData();
  }

  Future<void> _fetchCounselorData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Get profile picture from users table
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('profile_picture')
          .eq('user_id', userId)
          .maybeSingle();

      // Get counselor data from counselors table
      final counselorResponse = await Supabase.instance.client
          .from('counselors')
          .select('first_name, last_name, specialization')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _firstName = counselorResponse?['first_name'] ?? '';
          _lastName = counselorResponse?['last_name'] ?? '';
          _profilePicture = userResponse?['profile_picture'];
          _specialization = counselorResponse?['specialization'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading counselor data: $e');
      if (mounted) {
        setState(() {
          _firstName = 'Counselor';
          _lastName = '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
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
                                    _firstName.isNotEmpty ? _firstName : 'Counselor',
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
                                  if (_specialization.isNotEmpty)
                                    Text(
                                      _specialization,
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
              Navigator.pushReplacementNamed(context, 'counselor-home');
            },
          ),
          _buildDrawerItem(
            icon: Icons.person_rounded,
            title: 'Profile',
            onTap: () {
              Navigator.pushNamed(context, '/counselor-profile-setup');
            },
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today_rounded,
            title: 'All Appointments',
            onTap: () {
              Navigator.pushNamed(context, '/all-appointments');
            },
          ),
          _buildDrawerItem(
            icon: Icons.people_rounded,
            title: 'My Students',
            onTap: () {
              Navigator.pushNamed(context, '/student-history-list');
            },
          ),
          _buildDrawerItem(
            icon: Icons.chat_bubble_rounded,
            title: 'Student Chats',
            onTap: () {
              Navigator.pushNamed(context, '/counselor-chat-list');
            },
          ),

          _buildDrawerItem(
            icon: Icons.settings_rounded,
            title: 'Settings',
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: Color(0xFFE5E5E5)),
          ),
          _buildDrawerItem(
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
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
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
    return initials.isNotEmpty ? initials : 'C';
  }
}