import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_service.dart';
import '../../components/s_h_rounded_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
// Assuming it's styled to match now

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  String? username;
  bool isLoading = true;
  StreamSubscription? _usernameSubscription;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _listenToUsernameChanges();
  }

  @override
  void dispose() {
    _usernameSubscription?.cancel();
    super.dispose();
  }

  void _listenToUsernameChanges() {
    _usernameSubscription = UserService.usernameStream.listen((newUsername) {
      if (mounted) {
        setState(() {
          username = newUsername;
          isLoading = false;
        });
      }
    });
  }

  Future<void> _loadUsername() async {
    final name = await UserService.getUsername();
    if (mounted) {
      setState(() {
        username = name;
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        // Already on home, no need to navigate
        break;
      case 1: // Notifications
        // TODO: Implement notifications page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications coming soon!')),
        );
        break;
      case 2: // Settings
        // TODO: Implement settings page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings coming soon!')),
        );
        break;
      case 3: // Profile
        Navigator.pushNamed(context, '/student-profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        drawer: _buildDrawer(context),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Welcome Back",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: Color(0xFF5D5D72),
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        isLoading ? "Loading..." : "Hi, $username!",
                        style: GoogleFonts.poppins(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _HomeButton(
                    icon: Icons.mood,
                    label: 'Track your mood',
                    onTap: () => Navigator.pushNamed(context, 'student-mtq'),
                    color: Colors.pink.shade100,
                  ),
                  _HomeButton(
                    icon: Icons.self_improvement,
                    label: 'Breathing Exercises',
                    onTap: () => Navigator.pushNamed(
                      context,
                      'student-breathing-exercises',
                    ),
                    color: Colors.blue.shade100,
                  ),
                  _HomeButton(
                    icon: Icons.book,
                    label: 'Mood Journal',
                    onTap: () => Navigator.pushNamed(
                      context,
                      'student-mood-journal',
                    ),
                    color: Colors.purple.shade100,
                  ),
                  _HomeButton(
                    icon: Icons.health_and_safety,
                    label: 'Mental Health Resources',
                    onTap: () => Navigator.pushNamed(
                      context,
                      'student-mental-health-resources',
                    ),
                    color: Colors.green.shade100,
                  ),
                  _HomeButton(
                    icon: Icons.chat,
                    label: 'Chatbot',
                    onTap: () =>
                        Navigator.pushNamed(context, 'student-chatbot'),
                    color: Colors.orange.shade100,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF7C83FD),
          unselectedItemColor: const Color(0xFFB0B0C3),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF7C83FD)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_circle, size: 80, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  isLoading ? "Loading..." : "$username!",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Profile'),
            onTap: () => Navigator.pushNamed(context, '/student-profile'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: const Color(0xFF3A3A50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF7C83FD),
            ),
          ],
        ),
      ),
    );
  }
}
