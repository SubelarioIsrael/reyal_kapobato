import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../services/activity_service.dart';
import '../../services/chat_message_service.dart';
import '../../utils/responsive_utils.dart';
// Assuming it's styled to match now

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final textEditingController = TextEditingController();
  String? studentName;
  bool isLoading = true;
  StreamSubscription? _studentNameSubscription;
  int _selectedIndex = 1;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  Map<String, dynamic>? todayCheckIn;
  bool isCheckInLoading = true;

  List<Map<String, dynamic>> weeklyMood = [];
  bool isWeeklyMoodLoading = true;

  double _todayProgress = 0.0;
  bool _isProgressLoading = true;
  Map<String, bool> _todayCompletions = {
    'track_mood': false,
    'mood_journal': false,
    'daily_checkin': false,
    'breathing_exercise': false,
  };

  int _unreadMessagesCount = 0;

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
    const _FeatureCardData(
      title: 'Daily Mood Check-in',
      icon: Icons.emoji_emotions,
      image:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
      route: '/student-daily-checkin',
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
    const _FeatureCardData(
      title: 'Crisis Support',
      icon: Icons.contact_emergency,
      image:
          'https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=400&q=80',
      route: 'student-contacts',
    )
  ];
  final List<_FeatureCardData> _connectManage = [
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
    _loadStudentName();
    _listenToStudentNameChanges();
    _fetchTodayCheckIn();
    _fetchWeeklyMood();
    _loadTodayProgress();
    _loadUnreadMessagesCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh unread count when returning to this page
    _loadUnreadMessagesCount();
  }

  @override
  void dispose() {
    _studentNameSubscription?.cancel();
    super.dispose();
  }

  void _listenToStudentNameChanges() {
    _studentNameSubscription = UserService.studentNameStream.listen((newStudentName) {
      if (mounted) {
        setState(() {
          studentName = newStudentName;
          isLoading = false;
        });
      }
    });
  }

  Future<void> _loadStudentName() async {
    final name = await UserService.getStudentName();
    if (mounted) {
      setState(() {
        studentName = name;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchTodayCheckIn() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final today = DateTime.now();
    final response = await Supabase.instance.client
        .from('mood_entries')
        .select()
        .eq('user_id', userId)
        .eq('entry_date',
            "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}")
        .maybeSingle();
    setState(() {
      todayCheckIn = response;
      isCheckInLoading = false;
    });
  }

  Future<void> _fetchWeeklyMood() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    final response = await Supabase.instance.client
        .from('mood_entries')
        .select()
        .eq('user_id', userId)
        .gte('entry_date', startOfWeek.toIso8601String().substring(0, 10))
        .lte('entry_date', endOfWeek.toIso8601String().substring(0, 10));
    setState(() {
      weeklyMood = List<Map<String, dynamic>>.from(response);
      isWeeklyMoodLoading = false;
    });
  }

  List<Map<String, dynamic>> getWeekDaysWithMood() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    return List.generate(7, (i) {
      final date = startOfWeek.add(Duration(days: i));
      final entry = weeklyMood.firstWhere(
        (e) =>
            DateTime.parse(e['entry_date']).year == date.year &&
            DateTime.parse(e['entry_date']).month == date.month &&
            DateTime.parse(e['entry_date']).day == date.day,
        orElse: () => {},
      );
      return {
        'date': date,
        'isToday': date.day == today.day &&
            date.month == today.month &&
            date.year == today.year,
        'checkedIn': entry.isNotEmpty,
        'emoji': entry['emoji_code'],
      };
    });
  }

  Widget _buildWeeklyMoodBar() {
    if (isWeeklyMoodLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final week = getWeekDaysWithMood();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: week.map((day) {
          final isToday = day['isToday'];
          final checkedIn = day['checkedIn'];
          final emoji = day['emoji'];
          final date = day['date'] as DateTime;
          Color bgColor;
          if (checkedIn) {
            bgColor = Colors.green;
          } else if (isToday) {
            bgColor = Colors.orange;
          } else {
            bgColor = Colors.grey[200]!;
          }
          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  children: [
                    Text(DateFormat('E').format(date),
                        style: TextStyle(
                          color: checkedIn
                              ? Colors.white
                              : (isToday ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.bold,
                        )),
                    Text('${date.day}',
                        style: TextStyle(
                          color: checkedIn
                              ? Colors.white
                              : (isToday ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (checkedIn)
                Text(emoji ?? '', style: TextStyle(fontSize: 24))
              else if (isToday)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/student-daily-checkin');
                  },
                  child: Icon(Icons.add, size: 18),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(8),
                    minimumSize: Size(36, 36),
                  ),
                )
              else
                SizedBox(height: 36),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0: // Breathing Exercises
        Navigator.pushNamed(context, 'student-breathing-exercises');
        break;
      case 1: // Home (stay on this page)
        // No navigation needed, already on home
        break;
      case 2: // Track Mood (Daily Check-in)
        Navigator.pushNamed(context, '/student-daily-checkin');
        break;
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isCheckInLoading = true;
      isWeeklyMoodLoading = true;
    });

    await Future.wait([
      _fetchTodayCheckIn(),
      _fetchWeeklyMood(),
      _loadUnreadMessagesCount(),
    ]);

    setState(() {
      isCheckInLoading = false;
      isWeeklyMoodLoading = false;
    });
  }

  Future<void> _loadTodayProgress() async {
    setState(() => _isProgressLoading = true);
    final completions = await ActivityService.getTodayCompletions();
    final progress = await ActivityService.getTodayProgress();
    if (mounted) {
      setState(() {
        _todayCompletions = completions;
        _todayProgress = progress;
        _isProgressLoading = false;
      });
    }
  }

  Future<void> _loadUnreadMessagesCount() async {
    final count = await ChatMessageService.getUnreadMessagesFromCounselors();
    if (mounted) {
      setState(() {
        _unreadMessagesCount = count;
      });
    }
  }

  Widget _buildProgressBar() {
    if (_isProgressLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get remaining activities
    final remainingActivities = <String>[];
    if (!_todayCompletions['track_mood']!)
      remainingActivities.add('Track your mood');
    if (!_todayCompletions['mood_journal']!)
      remainingActivities.add('Write in your mood journal');
    if (!_todayCompletions['daily_checkin']!)
      remainingActivities.add('Complete your daily check-in');
    if (!_todayCompletions['breathing_exercise']!)
      remainingActivities.add('Do a breathing exercise');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Progress',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _todayProgress,
              backgroundColor: Colors.blue.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              borderRadius: BorderRadius.circular(10),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              '${(_todayProgress * 100).toInt()}% Complete',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (remainingActivities.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Complete these activities to reach 100%:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF3A3A50),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...remainingActivities.map((activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle,
                            size: 8, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          activity,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF5D5D72),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 242, 241, 248),
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF5D5D72)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            "BreatheBetter",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
            ),
          ),
          centerTitle: true,
          actions: [
            const StudentNotificationButton(),
          ],
        ),
        drawer: const StudentDrawer(),
        body: RefreshIndicator(
          key: _refreshKey,
          onRefresh: () async {
            await Future.wait([
              _refreshData(),
              _loadTodayProgress(),
              _loadUnreadMessagesCount(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20), // Add some space below AppBar
                  Text(
                    "Welcome Back",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isLoading
                        ? "Loading..."
                        : "Hi, ${studentName ?? ''}!",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildProgressBar(),
                  const SizedBox(height: 32),
                  Text(
                    'Daily Mood Check-in',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  _buildWeeklyMoodBar(),
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
                  ResponsiveUtils.responsiveGridView(
                    context,
                    children: _emotionalWellbeing
                        .map((feature) => _FeatureCard(feature: feature))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  ResponsiveUtils.responsiveText(
                    context,
                    'Support & Self-Care Tools',
                    style: GoogleFonts.poppins(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        small: 14.0,
                        medium: 16.0,
                        large: 18.0,
                      ),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ResponsiveUtils.responsiveGridView(
                    context,
                    children: _supportTools
                        .map((feature) => _FeatureCard(feature: feature))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  ResponsiveUtils.responsiveText(
                    context,
                    'Connect & Manage',
                    style: GoogleFonts.poppins(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        small: 14.0,
                        medium: 16.0,
                        large: 18.0,
                      ),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ResponsiveUtils.responsiveGridView(
                    context,
                    children: _connectManage
                        .map((feature) => _FeatureCard(feature: feature))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
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
            BottomNavigationBarItem(
                icon: Icon(Icons.self_improvement),
                label: 'Breathing Exercises'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.emoji_emotions), label: 'Track Mood'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, 'student-chat-list').then((_) {
              // Refresh unread messages count when returning from chat list
              _loadUnreadMessagesCount();
            });
          },
          backgroundColor: const Color(0xFF7C83FD),
          child: Stack(
            children: [
              const Icon(
                Icons.chat,
                color: Colors.white,
                size: 28,
              ),
              if (_unreadMessagesCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadMessagesCount > 99
                          ? '99+'
                          : _unreadMessagesCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
    // Special handling for Crisis Support card
    if (feature.title == 'Crisis Support') {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context,
            'student-contacts'), // Make sure this matches your routes.dart
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          feature.icon,
                          color: const Color(0xFF7C83FD),
                          size: ResponsiveUtils.getResponsiveIconSize(context),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: ResponsiveUtils.getResponsivePadding(context),
                child: Row(
                  children: [
                    Icon(
                      feature.icon,
                      color: const Color(0xFF7C83FD),
                      size: ResponsiveUtils.getResponsiveIconSize(
                        context,
                        small: 16.0,
                        medium: 18.0,
                        large: 20.0,
                      ),
                    ),
                    SizedBox(
                        width: ResponsiveUtils.getResponsiveSpacing(context)),
                    Expanded(
                      child: ResponsiveUtils.responsiveText(
                        context,
                        feature.title,
                        style: GoogleFonts.poppins(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            small: 12.0,
                            medium: 14.0,
                            large: 16.0,
                          ),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

    // Default for other cards
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context,
          feature.route), // This will use the route as defined in the card data
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
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        feature.icon,
                        color: const Color(0xFF7C83FD),
                        size: ResponsiveUtils.getResponsiveIconSize(context),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Row(
                children: [
                  Icon(
                    feature.icon,
                    color: const Color(0xFF7C83FD),
                    size: ResponsiveUtils.getResponsiveIconSize(
                      context,
                      small: 16.0,
                      medium: 18.0,
                      large: 20.0,
                    ),
                  ),
                  SizedBox(
                      width: ResponsiveUtils.getResponsiveSpacing(context)),
                  Expanded(
                    child: ResponsiveUtils.responsiveText(
                      context,
                      feature.title,
                      style: GoogleFonts.poppins(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          small: 12.0,
                          medium: 14.0,
                          large: 16.0,
                        ),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

class DailyCheckInDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  const DailyCheckInDialog({required this.onSubmit});

  @override
  State<DailyCheckInDialog> createState() => _DailyCheckInDialogState();
}

class _DailyCheckInDialogState extends State<DailyCheckInDialog> {
  String? moodType;
  String? emojiCode;
  List<String> reasons = [];
  TextEditingController noteController = TextEditingController();

  final moodOptions = [
    {'type': 'angry', 'emoji': '😡'},
    {'type': 'sad', 'emoji': '😔'},
    {'type': 'neutral', 'emoji': '😐'},
    {'type': 'happy', 'emoji': '😃'},
    {'type': 'loved', 'emoji': '🥰'},
  ];
  final reasonOptions = ['Relationship', 'School', 'Friend', 'Work', 'Family'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("How are you feeling today?"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: moodOptions.map((mood) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      moodType = mood['type'];
                      emojiCode = mood['emoji'];
                    });
                  },
                  child: CircleAvatar(
                    backgroundColor: moodType == mood['type']
                        ? Colors.green
                        : Colors.grey[200],
                    child: Text(mood['emoji']!, style: TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: reasonOptions.map((reason) {
                final selected = reasons.contains(reason);
                return ChoiceChip(
                  label: Text(reason),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (selected) {
                        reasons.remove(reason);
                      } else {
                        reasons.add(reason);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: "Add a note (optional)"),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: moodType == null
              ? null
              : () {
                  widget.onSubmit({
                    'mood_type': moodType,
                    'emoji_code': emojiCode,
                    'reasons': reasons,
                    'notes': noteController.text,
                  });
                  Navigator.pop(context);
                },
          child: Text("Submit"),
        ),
      ],
    );
  }
}
