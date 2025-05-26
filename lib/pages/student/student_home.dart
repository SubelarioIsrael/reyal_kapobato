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

  // List of grid features for the home page
  final List<_FeatureCardData> _emotionalWellbeing = [
    const _FeatureCardData(
      title: 'Track your mood',
      icon: Icons.mood,
      image:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
      route: 'student-mtq',
    ),
    const _FeatureCardData(
      title: 'Mood Journal',
      icon: Icons.book,
      image:
          'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80',
      route: 'student-mood-journal',
    ),
  ];
  final List<_FeatureCardData> _supportTools = [
    const _FeatureCardData(
      title: 'Breathing Exercises',
      icon: Icons.self_improvement,
      image:
          'https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=400&q=80',
      route: 'student-breathing-exercises',
    ),
    const _FeatureCardData(
      title: 'Mental Resources',
      icon: Icons.health_and_safety,
      image:
          'https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=400&q=80',
      route: 'student-mental-health-resources',
    ),
  ];
  final List<_FeatureCardData> _connectManage = [
    const _FeatureCardData(
      title: 'Chatbot',
      icon: Icons.chat,
      image:
          'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80',
      route: 'student-chatbot',
    ),
    const _FeatureCardData(
      title: 'Counselors',
      icon: Icons.people,
      image:
          'https://images.unsplash.com/photo-1503676382389-4809596d5290?auto=format&fit=crop&w=400&q=80',
      route: 'student-counselors',
    ),
    const _FeatureCardData(
      title: 'My Appointments',
      icon: Icons.event_note,
      image:
          'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80',
      route: 'student-appointments',
    ),
  ];

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
        break;
      case 1: // Settings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings coming soon!')),
        );
        break;
      case 2: // Profile
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
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          children: [
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Welcome Back",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5D5D72),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none,
                          color: Color(0xFF5D5D72)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('No new notifications.')),
                        );
                      },
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
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isLoading ? "Loading..." : "Hi, $username!",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 20),
            // Daily Uplift Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.cyan.shade50,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Healing takes time, and asking for help is a courageous step.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— Mariska Hargitay',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Emotional Well-being',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: _emotionalWellbeing
                  .map((feature) => _FeatureCard(feature: feature))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Support & Self-Care Tools',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: _supportTools
                  .map((feature) => _FeatureCard(feature: feature))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Connect & Manage',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: _connectManage
                  .map((feature) => _FeatureCard(feature: feature))
                  .toList(),
            ),
            const SizedBox(height: 24),
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
                icon: Icon(Icons.settings), label: 'Settings'),
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
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, 'student-settings');
            },
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

class _FeatureCardData {
  final String title;
  final IconData icon;
  final String image;
  final String route;
  const _FeatureCardData(
      {required this.title,
      required this.icon,
      required this.image,
      required this.route});
}

class _FeatureCard extends StatelessWidget {
  final _FeatureCardData feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, feature.route),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  feature.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Icon(feature.icon, color: const Color(0xFF7C83FD)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
