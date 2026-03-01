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
  String _departmentAssigned = '';
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
      final userResponse = await Supabase.instance.client
          .from('users').select('profile_picture').eq('user_id', userId).maybeSingle();
      final counselorResponse = await Supabase.instance.client
          .from('counselors').select('first_name, last_name, department_assigned').eq('user_id', userId).maybeSingle();
      if (mounted) {
        setState(() {
          _firstName = counselorResponse?['first_name'] ?? '';
          _lastName = counselorResponse?['last_name'] ?? '';
          _profilePicture = userResponse?['profile_picture'];
          _departmentAssigned = counselorResponse?['department_assigned'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _firstName = 'Counselor'; _lastName = ''; _isLoading = false; });
      }
    }
  }

  String _getInitials() {
    String i = '';
    if (_firstName.isNotEmpty) i += _firstName[0].toUpperCase();
    if (_lastName.isNotEmpty) i += _lastName[0].toUpperCase();
    return i.isNotEmpty ? i : 'C';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('ACCOUNT'),
                  _buildItem(icon: Icons.dashboard_rounded, title: 'Home',
                      onTap: () => Navigator.pushReplacementNamed(context, 'counselor-home')),
                  _buildItem(icon: Icons.person_rounded, title: 'Profile',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/counselor-profile'); }),
                  _buildLabel('STUDENTS'),
                  _buildItem(icon: Icons.people_rounded, title: 'My Students',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/student-history-list'); }),
                  _buildItem(icon: Icons.calendar_month_rounded, title: 'Appointments',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/all-appointments'); }),
                  _buildItem(icon: Icons.chat_rounded, title: 'Student Chats',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/counselor-chat-list'); }),
                  _buildLabel('SETTINGS'),
                  _buildItem(icon: Icons.settings_rounded, title: 'Settings',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/settings'); }),
                ],
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFEEEEEE))),
          _buildLogout(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D5A99), Color(0xFF5C7EC9)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(20),
                    child: SizedBox(height: 24, width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.6), width: 2.5),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            backgroundImage: _profilePicture != null && _profilePicture!.isNotEmpty
                                ? MemoryImage(base64Decode(_profilePicture!)) : null,
                            child: _profilePicture == null || _profilePicture!.isEmpty
                                ? Text(_getInitials(), style: GoogleFonts.poppins(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)) : null,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 17),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _firstName.isNotEmpty
                          ? 'Dr. $_firstName${_lastName.isNotEmpty ? ' $_lastName' : ''}' : 'Counselor',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.2),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Counselor', style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                        ),
                        if (_departmentAssigned.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(child: Text(_departmentAssigned, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 10))),
                        ],
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 2),
      child: Text(label, style: GoogleFonts.poppins(
          fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFAAAAAA), letterSpacing: 1.2)),
    );
  }

  Widget _buildItem({Key? key, required IconData icon, required String title, required VoidCallback onTap,
      Color? iconColor, Color? textColor}) {
    final c = iconColor ?? const Color(0xFF5D5D72);
    final tc = textColor ?? const Color(0xFF3A3A50);
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        horizontalTitleGap: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: c, size: 18),
        ),
        title: Text(title, style: GoogleFonts.poppins(color: tc, fontWeight: FontWeight.w500, fontSize: 14)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogout() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        key: const Key('logout_button'),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        horizontalTitleGap: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(9)),
          child: Icon(Icons.logout_rounded, color: Colors.red[400], size: 18),
        ),
        title: Text('Logout', style: GoogleFonts.poppins(
            color: Colors.red[400], fontWeight: FontWeight.w600, fontSize: 14)),
        onTap: () async {
          await Supabase.instance.client.auth.signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        },
      ),
    );
  }
}