// THIS LOOKS HORRENDOUS BTW BUT IT'S FINE


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../utils/responsive_utils.dart';
import '../../controllers/student_home_controller.dart';
import '../../services/activity_service.dart';

class StudentHomeNew extends StatefulWidget {
  const StudentHomeNew({super.key});

  @override
  State<StudentHomeNew> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHomeNew> {
  final controller = StudentHomeController();
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 1;

  final List<_FeatureCardData> _emotionalWellbeing = [
    const _FeatureCardData(title: 'Bi-Weekly Mind Check-In', image: 'https://www.21kschool.com/us/wp-content/uploads/sites/37/2024/12/Difference-Between-Assessment-and-Evaluation-A-Comprehensive-Guide.png', route: 'student-mtq'),
    const _FeatureCardData(title: 'My Mood Journal', image: 'https://t3.ftcdn.net/jpg/00/87/64/32/360_F_87643201_KtLtcqArlgjZ8zSFEPM48otNrRRW8RuJ.jpg', route: 'student-mood-journal'),
    const _FeatureCardData(title: 'Daily Mood Check-in', image: 'https://news.harvard.edu/gazette/wp-content/uploads/2023/08/Phonewithmoodioons.jpg', route: '/student-daily-checkin'),
  ];

  final List<_FeatureCardData> _supportTools = [
    const _FeatureCardData(title: 'Breathing Exercises', image: 'https://www.bhf.org.uk/-/media/images/information-support/heart-matters/2023/december/wellbeing/deep-breathing-620x400.png', route: 'student-breathing-exercises'),
    const _FeatureCardData(title: 'Wellness Resources', image: 'https://cdn.brewersassociation.org/wp-content/uploads/2024/05/29100101/illustration-of-person-with-harmonious-mental-health-1200x800-1.jpg', route: 'student-mental-health-resources'),
    const _FeatureCardData(title: 'Support Contacts', image: 'https://centerforliving.org/wp-content/uploads/2023/06/nycfl_1155348268.jpg', route: 'student-contacts'),
  ];

  final List<_FeatureCardData> _connectManage = [
    const _FeatureCardData(title: 'Connect with a Counselor', image: 'https://bouve.northeastern.edu/wp-content/uploads/2023/05/what-do-mental-health-counselors-do-northeastern-graduate.webp', route: 'student-counselors'),
    const _FeatureCardData(title: 'My Appointments', image: 'https://3veta.com/wp-content/uploads/2021/11/66.-How-to-effectively-schedule-appointments.png', route: 'student-appointments'),
  ];

  @override
  void initState() {
    super.initState();
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, 'student-breathing-exercises');
        break;
      case 1:
        break;
      case 2:
        Navigator.pushNamed(context, 'student-mood-journal');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: Text("BreatheBetter", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF3A3A50))),
        centerTitle: true,
        actions: const [StudentNotificationButton()],
      ),
      drawer: const StudentDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            controller.fetchTodayCheckIn(),
            controller.fetchWeeklyMood(),
            controller.loadTodayProgress(),
            controller.loadUnreadMessagesCount(),
            controller.loadDailyUplift(),
          ]);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder(
                  valueListenable: controller.isLoading,
                  builder: (_, bool loading, __) => Text(
                    loading ? 'Loading...' : 'Hi, ${controller.studentName.value ?? ''}!',
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                // Today progress bar
                ValueListenableBuilder(
                  valueListenable: controller.isProgressLoading,
                  builder: (_, bool progressLoading, __) {
                    if (progressLoading) return const LinearProgressIndicator();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: controller.todayProgress.value),
                        const SizedBox(height: 8),
                        Text('${(controller.todayProgress.value * 100).toInt()}% Complete'),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Weekly mood bar
                ValueListenableBuilder(
                  valueListenable: controller.isWeeklyMoodLoading,
                  builder: (_, bool loading, __) {
                    if (loading) return const Center(child: CircularProgressIndicator());
                    final week = controller.getWeekDaysWithMood();
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: week.map((day) {
                          final bgColor = day['checkedIn'] ? Colors.green : (day['isToday'] ? Colors.orange : Colors.grey[200]);
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                Text(day['date'].toString()),
                                Text(day['emoji'] ?? ''),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Daily uplift
                ValueListenableBuilder(
                  valueListenable: controller.isDailyUpliftLoading,
                  builder: (_, bool loading, __) {
                    if (loading) return const CircularProgressIndicator();
                    final uplift = controller.dailyUplift.value;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(uplift != null ? uplift['quote'] ?? 'Stay positive!' : 'Stay positive!'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Emotional wellbeing cards
                ResponsiveUtils.responsiveGridView(
                  context,
                  children: _emotionalWellbeing.map((feature) => _FeatureCard(feature: feature)).toList(),
                ),
                const SizedBox(height: 16),
                // Support tools
                ResponsiveUtils.responsiveGridView(
                  context,
                  children: _supportTools.map((feature) => _FeatureCard(feature: feature)).toList(),
                ),
                const SizedBox(height: 16),
                // Connect & manage
                ResponsiveUtils.responsiveGridView(
                  context,
                  children: _connectManage.map((feature) => _FeatureCard(feature: feature)).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF7C83FD),
        unselectedItemColor: const Color(0xFFB0B0C3),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.self_improvement), label: 'Breathing Exercises'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Mood Journal'),
        ],
      ),
    );
  }
}

class _FeatureCardData {
  final Key? key;
  final String title;
  final String image;
  final String route;
  const _FeatureCardData({this.key, required this.title, required this.image, required this.route});
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
        child: Column(
          children: [
            Expanded(child: Image.network(feature.image, fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(feature.title, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
