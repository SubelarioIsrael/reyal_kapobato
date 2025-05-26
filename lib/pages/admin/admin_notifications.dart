import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminNotifications extends StatefulWidget {
  const AdminNotifications({super.key});

  @override
  State<AdminNotifications> createState() => _AdminNotificationsState();
}

class _AdminNotificationsState extends State<AdminNotifications> {
  // Mock data - Replace with actual data from your backend
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New User Registration',
      'message': 'John Doe has registered as a student',
      'time': '2 hours ago',
      'isRead': false,
    },
    {
      'title': 'Appointment Request',
      'message': 'New appointment request from Jane Smith',
      'time': '5 hours ago',
      'isRead': true,
    },
    {
      'title': 'System Update',
      'message': 'System maintenance scheduled for tomorrow',
      'time': '1 day ago',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3A3A50),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: notification['isRead']
                    ? Colors.grey.withOpacity(0.1)
                    : const Color(0xFF7C83FD).withOpacity(0.1),
                child: Icon(
                  Icons.notifications,
                  color: notification['isRead']
                      ? Colors.grey
                      : const Color(0xFF7C83FD),
                ),
              ),
              title: Text(
                notification['title'],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['time'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              onTap: () {
                // TODO: Handle notification tap
              },
            ),
          );
        },
      ),
    );
  }
}
