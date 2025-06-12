import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF7C83FD),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Color(0xFF7C83FD),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Student Portal',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF5D5D72)),
            title: Text(
              'Home',
              style: GoogleFonts.poppins(
                color: const Color(0xFF5D5D72),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pushReplacementNamed(context, 'student-home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF5D5D72)),
            title: Text(
              'Profile',
              style: GoogleFonts.poppins(
                color: const Color(0xFF5D5D72),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/student-profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Color(0xFF5D5D72)),
            title: Text(
              'Chatbot',
              style: GoogleFonts.poppins(
                color: const Color(0xFF5D5D72),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(context, 'student-chatbot');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF5D5D72)),
            title: Text(
              'Settings',
              style: GoogleFonts.poppins(
                color: const Color(0xFF5D5D72),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(context, 'student-settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF5D5D72)),
            title: Text(
              'Logout',
              style: GoogleFonts.poppins(
                color: const Color(0xFF5D5D72),
                fontWeight: FontWeight.w500,
              ),
            ),
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
}
