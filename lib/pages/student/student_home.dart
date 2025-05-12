import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../components/s_h_rounded_button.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  String? username;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final name = await UserService.getUsername();
    setState(() {
      username = name;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLoading ? 'Loading...' : 'Welcome back, $username!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // Matching color palette
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Start Your Journey",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
              RoundedButton(
                icon: Icons.mood,
                label: 'Track your mood now!',
                onTap: () {
                  Navigator.pushNamed(context, 'student-mtq');
                  print('Mood tracking pressed');
                },
              ),
              RoundedButton(
                icon: Icons.self_improvement,
                label: 'Breathing Exercises',
                onTap: () {
                  Navigator.pushNamed(context, 'student-breathing-exercises');
                  print('Breathing exercises pressed');
                },
              ),
              RoundedButton(
                icon: Icons.book,
                label: 'Mood Journal',
                onTap: () {
                  Navigator.pushNamed(context, 'student-mood-journal');
                  print('Mood journal pressed');
                },
              ),
              RoundedButton(
                icon: Icons.health_and_safety,
                label: 'Mental Health Resources',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    'student-mental-health-resources',
                  );
                  print('Health resources pressed');
                },
              ),
              RoundedButton(
                icon: Icons.chat,
                label: 'Chatbot',
                onTap: () {
                  Navigator.pushNamed(context, 'student-chatbot');
                  print('Chatbot pressed');
                },
              ),
            ],
          ),
        ),
      ),
      persistentFooterButtons: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.home, size: 32, color: Color(0xFF4CAF50)),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.notifications,
                size: 32,
                color: Color(0xFFFF9800),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.settings, size: 32, color: Color(0xFF2196F3)),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.person, size: 32, color: Colors.black),
            ),
          ],
        ),
      ],
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text(isLoading ? 'Loading...' : 'Welcome back, $username!'),
  //       centerTitle: true,
  //     ),
  //     body: SafeArea(
  //       child: SingleChildScrollView(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             RoundedButton(
  //               icon: Icons.mood, // for tracking mood
  //               label: 'Track your mood now!',
  //               onTap: () {
  //                 print('Mood tracking pressed');
  //               },
  //             ),
  //             RoundedButton(
  //               icon: Icons.self_improvement, // for breathing exercises
  //               label: 'Breathing Exercises',
  //               onTap: () {
  //                 print('Breathing exercises pressed');
  //               },
  //             ),
  //             RoundedButton(
  //               icon: Icons.book, // for journal
  //               label: 'Mood Journal',
  //               onTap: () {
  //                 print('Mood journal pressed');
  //               },
  //             ),
  //             RoundedButton(
  //               icon: Icons.health_and_safety, // for health resources
  //               label: 'Mental Health Resources',
  //               onTap: () {
  //                 print('Health resources pressed');
  //               },
  //             ),
  //             RoundedButton(
  //               icon: Icons.chat, // for chatbot
  //               label: 'Chatbot',
  //               onTap: () {
  //                 print('Chatbot pressed');
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //     persistentFooterButtons: <Widget>[
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly, // spreads them out
  //         mainAxisSize: MainAxisSize.max,
  //         children: [
  //           IconButton(
  //             onPressed: () {},
  //             icon: Icon(Icons.home, size: 32, color: Color(0xFF4CAF50)),
  //           ),
  //           IconButton(
  //             onPressed: () {},
  //             icon: Icon(
  //               Icons.notifications,
  //               size: 32,
  //               color: Color(0xFFFF9800),
  //             ),
  //           ),
  //           IconButton(
  //             onPressed: () {},
  //             icon: Icon(Icons.settings, size: 32, color: Color(0xFF2196F3)),
  //           ),
  //           IconButton(
  //             onPressed: () {},
  //             icon: Icon(Icons.person, size: 32, color: Colors.black),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }
}
