import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class StudentNotificationButton extends StatefulWidget {
  const StudentNotificationButton({super.key});

  @override
  State<StudentNotificationButton> createState() =>
      _StudentNotificationButtonState();
}

class _StudentNotificationButtonState extends State<StudentNotificationButton> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('user_notifications')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(50); // Increased limit to show more notifications

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await Supabase.instance.client
          .from('user_notifications')
          .update({'is_read': true}).eq('notification_id', notificationId);

      setState(() {
        final index = _notifications
            .indexWhere((n) => n['notification_id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      setState(() {
        for (var notification in _notifications) {
          notification['is_read'] = true;
        }
      });
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    await _markAsRead(notification['notification_id']);

    if (notification['action_url'] != null) {
      Navigator.pop(context);
      Navigator.pushNamed(context, notification['action_url']);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupNotificationsByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var notification in _notifications) {
      final date = DateTime.parse(notification['timestamp']);
      String key;

      if (date.isToday) {
        key = 'Today';
      } else if (date.isYesterday) {
        key = 'Yesterday';
      } else {
        key = DateFormat('MMMM d, y').format(date);
      }

      grouped.putIfAbsent(key, () => []).add(notification);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['is_read']).length;

    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.notifications_none, color: Color(0xFF5D5D72)),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      if (unreadCount > 0)
                        TextButton(
                          onPressed: _markAllAsRead,
                          child: Text(
                            'Mark all as read',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF7C83FD),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_notifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No new notifications',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: RefreshIndicator(
                        key: _refreshKey,
                        onRefresh: _fetchNotifications,
                        child: ListView(
                          children:
                              _groupNotificationsByDate().entries.map((entry) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    entry.key,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                ...entry.value.map((notification) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor: notification['is_read']
                                              ? Colors.grey.withOpacity(0.1)
                                              : const Color(0xFF7C83FD)
                                                  .withOpacity(0.1),
                                          child: Icon(
                                            Icons.notifications,
                                            color: notification['is_read']
                                                ? Colors.grey
                                                : const Color(0xFF7C83FD),
                                          ),
                                        ),
                                        title: Text(
                                          notification['notification_type'],
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3A3A50),
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              notification['content'],
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              timeago.format(
                                                DateTime.parse(
                                                    notification['timestamp']),
                                                locale: 'en_short',
                                              ),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () =>
                                            _handleNotificationTap(notification),
                                      ),
                                    )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

extension DateTimeExtension on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}
