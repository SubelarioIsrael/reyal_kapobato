import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../services/activity_service.dart';

class StudentDailyCheckInPage extends StatefulWidget {
  const StudentDailyCheckInPage({Key? key}) : super(key: key);

  @override
  State<StudentDailyCheckInPage> createState() =>
      _StudentDailyCheckInPageState();
}

class _StudentDailyCheckInPageState extends State<StudentDailyCheckInPage> {
  int step = 0;
  String? moodType;
  String? emojiCode;
  List<String> reasons = [];
  TextEditingController noteController = TextEditingController();
  bool isSubmitting = false;
  bool isComplete = false;
  Map<String, dynamic>? todayCheckIn;

  int _selectedIndex = 2;

  final moodOptions = [
    {'type': 'angry', 'emoji': '😡'},
    {'type': 'sad', 'emoji': '😔'},
    {'type': 'neutral', 'emoji': '😐'},
    {'type': 'happy', 'emoji': '😃'},
    {'type': 'loved', 'emoji': '🥰'},
  ];
  final reasonOptions = ['Relationship', 'School', 'Friend', 'Work', 'Family'];

  @override
  void initState() {
    super.initState();
    _fetchTodayCheckIn();
  }

  Future<void> _fetchTodayCheckIn() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final today = DateTime.now();
    // Get the start and end of today in the local timezone
    final startOfToday = DateTime(today.year, today.month, today.day);
    final endOfToday =
        DateTime(today.year, today.month, today.day, 23, 59, 59, 999);

    try {
      final response = await Supabase.instance.client
          .from('mood_entries')
          .select()
          .eq('user_id', userId)
          .gte(
              'entry_date',
              startOfToday
                  .toIso8601String()) // Greater than or equal to start of day
          .lte('entry_date',
              endOfToday.toIso8601String()) // Less than or equal to end of day
          .maybeSingle()
          .timeout(
        const Duration(seconds: 10), // Add timeout for fetching as well
        onTimeout: () {
          throw TimeoutException('Fetching check-in timed out');
        },
      );

      if (mounted) {
        setState(() {
          todayCheckIn = response;
          isComplete = response != null;
        });
      }
    } catch (e) {
      if (mounted) {
        // Handle error during fetch, maybe show a message or set isComplete to false
        print('Error fetching today\'s check-in: ${e.toString()}');
        setState(() {
          isComplete = false; // Allow submission if fetching fails
        });
      }
    }
  }

  Future<void> _submitCheckIn() async {
    if (moodType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your mood'),
        ),
      );
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await Supabase.instance.client.from('mood_entries').insert({
        'user_id': user.id,
        'mood_type': moodType,
        'emoji_code': emojiCode,
        'reasons': reasons,
        'notes': noteController.text,
      });

      // Record activity completion
      await ActivityService.recordActivityCompletion('daily_checkin');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in saved successfully!'),
          ),
        );
        await _fetchTodayCheckIn();
      }
    } catch (e) {
      print('Error saving check-in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving check-in. Please try again.'),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, 'student-breathing-exercises');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, 'student-home');
        break;
      case 2:
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isComplete && todayCheckIn != null
            ? _buildSummary()
            : _buildStepper(),
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
              icon: Icon(Icons.self_improvement), label: 'Breathing Exercises'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_emotions), label: 'Track Mood'),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step == 0) ...[
          Text(
            "What's your mood Today?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Select mood reflects the most how you are feeling at this moment",
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
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
                  radius: 28,
                  child: Text(
                    mood['emoji']!,
                    style: TextStyle(
                      fontSize: 32,
                      color: moodType == mood['type']
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Spacer(),
          ElevatedButton(
            onPressed: moodType == null ? null : () => setState(() => step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ] else if (step == 1) ...[
          Text(
            "Choose the reason why you feel ${moodType?.capitalize() ?? ''}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Select a reason",
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: reasonOptions.map((reason) {
              final selected = reasons.contains(reason);
              return ChoiceChip(
                label: Text(reason),
                selected: selected,
                selectedColor: Colors.green,
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
          SizedBox(height: 24),
          TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: "Note:",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 3,
          ),
          Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => step = 0),
                  child: Text('Back'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      isSubmitting || moodType == null ? null : _submitCheckIn,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ]
      ],
    );
  }

  Widget _buildSummary() {
    if (todayCheckIn == null) return SizedBox();
    final emoji = todayCheckIn!['emoji_code'] ?? '';
    final mood = todayCheckIn!['mood_type'] ?? '';
    final reasons = (todayCheckIn!['reasons'] as List?)?.join(', ') ?? '';
    final notes = todayCheckIn!['notes'] ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'You have already checked in today!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Text(
          emoji,
          style: TextStyle(fontSize: 64),
        ),
        SizedBox(height: 16),
        Text(
          'You felt $mood',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        if (reasons.isNotEmpty)
          Text(
            'Because: $reasons',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        SizedBox(height: 8),
        if (notes.isNotEmpty)
          Text(
            'Note: $notes',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return this[0].toUpperCase() + substring(1);
  }
}
