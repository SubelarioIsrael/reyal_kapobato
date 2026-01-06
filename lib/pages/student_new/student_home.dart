import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../controllers/student_home_controller.dart';
import '../../utils/responsive_utils.dart';

class StudentHomeNew extends StatefulWidget {
  const StudentHomeNew({super.key});

  @override
  State<StudentHomeNew> createState() => _StudentHomeNewState();
}

class _StudentHomeNewState extends State<StudentHomeNew> {
  final controller = StudentHomeController();
  final ScrollController _scrollController = ScrollController();
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  // List of grid features for the home page
  final List<_FeatureCardData> _emotionalWellbeing = [
    const _FeatureCardData(
      title: 'Bi-Weekly Mind Check-In',
      image: 'https://www.21kschool.com/us/wp-content/uploads/sites/37/2024/12/Difference-Between-Assessment-and-Evaluation-A-Comprehensive-Guide.png',
      route: 'student-mtq',
    ),
    const _FeatureCardData(
      title: 'My Mood Journal',
      image: 'https://t3.ftcdn.net/jpg/00/87/64/32/360_F_87643201_KtLtcqArlgjZ8zSFEPM48otNrRRW8RuJ.jpg',
      route: 'student-mood-journal',
    ),
    const _FeatureCardData(
      title: 'Daily Mood Check-in',
      image: 'https://news.harvard.edu/gazette/wp-content/uploads/2023/08/Phonewithmoodioons.jpg',
      route: '/student-daily-checkin',
    ),
  ];

  final List<_FeatureCardData> _supportTools = [
    const _FeatureCardData(
      key: Key('breathing_exercises_card'),
      title: 'Breathing Exercises',
      image: 'https://www.bhf.org.uk/-/media/images/information-support/heart-matters/2023/december/wellbeing/deep-breathing-620x400.png',
      route: 'student-breathing-exercises',
    ),
    const _FeatureCardData(
      title: 'Wellness Resources',
      image: 'https://cdn.brewersassociation.org/wp-content/uploads/2024/05/29100101/illustration-of-person-with-harmonious-mental-health-1200x800-1.jpg',
      route: 'student-mental-health-resources',
    ),
    const _FeatureCardData(
      title: 'Support Contacts',
      image: 'https://centerforliving.org/wp-content/uploads/2023/06/nycfl_1155348268.jpg',
      route: 'student-contacts',
    )
  ];

  final List<_FeatureCardData> _connectManage = [
    const _FeatureCardData(
      title: 'Connect with a Counselor',
      image: 'https://bouve.northeastern.edu/wp-content/uploads/2023/05/what-do-mental-health-counselors-do-northeastern-graduate.webp',
      route: 'student-counselors',
    ),
    const _FeatureCardData(
      title: 'Appointments\n',
      image: 'https://3veta.com/wp-content/uploads/2021/11/66.-How-to-effectively-schedule-appointments.png',
      route: 'student-appointments',
    ),
  ];

  @override
  void initState() {
    super.initState();
    controller.init();
    _checkEmergencyContacts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh all data when returning to this page
    _refreshPageData();
  }

  Future<void> _refreshPageData() async {
    await Future.wait([
      controller.fetchTodayCheckIn(),
      controller.fetchWeeklyMood(),
      controller.loadTodayProgress(),
      controller.loadUnreadMessagesCount(),
      controller.loadDailyUplift(),
    ]);
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkEmergencyContacts() async {
    final hasContacts = await controller.checkEmergencyContacts();
    if (!hasContacts && mounted) {
      // Wait a bit for the page to fully load before showing dialog
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showEmergencyContactDialog();
      }
    }
  }

  void _showEmergencyContactDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Emergency Contacts',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'You still have not added your emergency contacts.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF3A3A50),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Adding emergency contacts ensures you have support in case of emergencies.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF5D5D72),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: Color(0xFF7C83FD),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Later',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C83FD),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      'student-contacts',
                      arguments: {'autoOpenAddDialog': true},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF7C83FD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Proceed',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyMoodBar() {
    return ValueListenableBuilder(
      valueListenable: controller.weeklyMood,
      builder: (_, List<Map<String, dynamic>> moodData, __) {
        return ValueListenableBuilder(
          valueListenable: controller.isWeeklyMoodLoading,
          builder: (_, bool loading, __) {
            if (loading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final week = controller.getWeekDaysWithMood();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  key: const Key('weekly_mood_bar'),
                  children: week.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;
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
                    return Padding(
                      padding: EdgeInsets.only(right: index < week.length - 1 ? 12.0 : 0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('E').format(date),
                                  style: TextStyle(
                                    color: checkedIn
                                        ? Colors.white
                                        : (isToday ? Colors.white : Colors.black87),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: checkedIn
                                        ? Colors.white
                                        : (isToday ? Colors.white : Colors.black87),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (checkedIn)
                            Text(emoji ?? '', style: const TextStyle(fontSize: 24))
                          else if (isToday)
                            ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.pushNamed(context, '/student-daily-checkin');
                                // Refresh home page data if check-in was completed
                                if (result == true) {
                                  _refreshPageData();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(8),
                                minimumSize: const Size(36, 36),
                              ),
                              child: const Icon(Icons.add, size: 18),
                            )
                          else
                            const SizedBox(height: 36),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return ValueListenableBuilder(
      valueListenable: controller.isProgressLoading,
      builder: (_, bool loading, __) {
        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get remaining activities
        final todayCompletions = controller.todayCompletions.value;
        final remainingActivities = <String>[];
        if (!todayCompletions['mood_journal']!) {
          remainingActivities.add('Write in your mood journal');
        }
        if (!todayCompletions['daily_checkin']!) {
          remainingActivities.add('Complete your daily check-in');
        }
        if (!todayCompletions['breathing_exercise']!) {
          remainingActivities.add('Do a breathing exercise');
        }

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
                  value: controller.todayProgress.value,
                  backgroundColor: Colors.blue.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(controller.todayProgress.value * 100).toInt()}% Complete',
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
                            Icon(Icons.circle, size: 8, color: Colors.blue.shade700),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: const Key('studentHomeScreen'),
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 242, 241, 248),
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              key: const Key('drawer_button'),
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
            StudentNotificationButton(key: UniqueKey()),
          ],
        ),
        drawer: const StudentDrawer(),
        body: RefreshIndicator(
          key: _refreshKey,
          onRefresh: _refreshPageData,
          child: SingleChildScrollView(
            key: const Key('studentHomeScrollView'),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome Back",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5D5D72),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: controller.isLoading,
                    builder: (_, bool loading, __) => Text(
                      loading ? "Loading..." : "Hi, ${controller.studentName.value ?? ''}!",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildProgressBar(),
                  const SizedBox(height: 10),
                  Text(
                    'Daily Mood Check-in',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  _buildWeeklyMoodBar(),

                  // Daily Uplift Card
                  ValueListenableBuilder(
                    valueListenable: controller.isDailyUpliftLoading,
                    builder: (_, bool loading, __) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.cyan.shade50,
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: loading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : controller.dailyUplift.value != null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          key: const Key('dailyUpliftQuote'),
                                          controller.dailyUplift.value!['quote'] ??
                                              'Stay positive and keep going!',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF3A3A50),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (controller.dailyUplift.value!['author'] != null &&
                                            controller.dailyUplift.value!['author']
                                                .toString()
                                                .isNotEmpty)
                                          Text(
                                            '— ${controller.dailyUplift.value!['author']}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Stay positive and keep going!',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF3A3A50),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Daily uplifts will appear here when available.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Emotional Well-being',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 5),
                  ResponsiveUtils.responsiveGridView(
                    context,
                    children: _emotionalWellbeing
                        .map((feature) => _FeatureCard(feature: feature))
                        .toList(),
                  ),
                  const SizedBox(height: 5),
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
                  const SizedBox(height: 5),
                  ResponsiveUtils.responsiveGridView(
                    context,
                    children: _supportTools
                        .map((feature) => _FeatureCard(feature: feature))
                        .toList(),
                  ),
                  const SizedBox(height: 5),
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
                  const SizedBox(height: 5),
                  ResponsiveUtils.responsiveGridView(
                    context,
                    children: _connectManage
                        .map((feature) => _FeatureCard(feature: feature))
                        .toList(),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        ),
        
        floatingActionButton: ValueListenableBuilder(
          valueListenable: controller.unreadMessagesCount,
          builder: (_, int count, __) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, 'student-chat-list').then((_) {
                  controller.loadUnreadMessagesCount();
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
                  if (count > 0)
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
                          count > 99 ? '99+' : count.toString(),
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
            );
          },
        ),
      ),
    );
  }
}

class _FeatureCardData {
  final Key? key;
  final String title;
  final String image;
  final String route;
  const _FeatureCardData({
    this.key,
    required this.title,
    required this.image,
    required this.route,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureCardData feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    // Special handling for Crisis Support card
    if (feature.title == 'Crisis Support') {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, 'student-contacts'),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    feature.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const SizedBox(),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Text(
                  feature.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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
      );
    }

    // Default for other cards
    return GestureDetector(
      key: feature.key,
      onTap: () => Navigator.pushNamed(context, feature.route),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  feature.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const SizedBox(),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Text(
                feature.title,
                style: GoogleFonts.poppins(
                  fontSize: 12.9,
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
    );
  }
}
