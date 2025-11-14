import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CounselorNotificationButton extends StatefulWidget {
  const CounselorNotificationButton({super.key});

  @override
  State<CounselorNotificationButton> createState() => _CounselorNotificationButtonState();
}

class _CounselorNotificationButtonState extends State<CounselorNotificationButton> {
  int _notificationCount = 0;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    
    // Listen for real-time updates
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId != null) {
      print('Setting up counselor notification listener for user: $userId');
      // Listen for new notifications in user_notifications table
      supabase
          .channel('counselor_notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              print('Counselor notification: notification change detected - ${payload.eventType}');
              _loadNotifications();
            },
          )
          .subscribe();
    }
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        print('Counselor notifications: No user ID found');
        return;
      }

      print('Loading counselor notifications for user: $userId');

      // Fetch notifications from user_notifications table
      final response = await supabase
          .from('user_notifications')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(50);

      final List<NotificationItem> notifications = [];

      for (final notification in response) {
        final notificationType = notification['notification_type'] as String?;
        final content = notification['content'] as String? ?? '';
        final timestamp = DateTime.parse(notification['timestamp'] as String);
        final isRead = notification['is_read'] as bool? ?? false;
        final actionUrl = notification['action_url'] as String?;

        NotificationType? type;
        String title = 'Notification';

        if (notificationType == 'appointment_booked') {
          type = NotificationType.newAppointment;
          title = 'New Appointment Request';
        } else if (notificationType == 'appointment_cancelled') {
          type = NotificationType.cancelledAppointment;
          title = 'Appointment Cancelled';
        }

        if (type != null) {
          notifications.add(NotificationItem(
            type: type,
            title: title,
            message: content,
            timestamp: timestamp,
            isUnread: !isRead,
            relatedId: notification['notification_id'].toString(),
            actionUrl: actionUrl,
          ));
        }
      }

      print('Total notifications: ${notifications.length}, Unread: ${notifications.where((n) => n.isUnread).length}');

      setState(() {
        _notifications = notifications;
        _notificationCount = notifications.where((n) => n.isUnread).length;
      });
    } catch (e) {
      print('Error loading counselor notifications: $e');
      if (mounted) {
        setState(() {
          _notifications = [];
          _notificationCount = 0;
        });
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await Supabase.instance.client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('notification_id', notificationId);

      setState(() {
        final index = _notifications
            .indexWhere((n) => n.relatedId == notificationId.toString());
        if (index != -1) {
          _notifications[index].isUnread = false;
          _notificationCount = _notifications.where((n) => n.isUnread).length;
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
          notification.isUnread = false;
        }
        _notificationCount = 0;
      });
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF5D5D72),
              size: 28,
            ),
            onPressed: _showNotificationsDropdown,
          ),
          if (_notificationCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  _notificationCount > 9 ? '9+' : _notificationCount.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNotificationsDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  if (_notificationCount > 0)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Mark all as read',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF7C83FD),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Notifications List
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationItem(_notifications[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isUnread
            ? _getTypeColor(notification.type).withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isUnread
              ? _getTypeColor(notification.type).withOpacity(0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getTypeColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getTypeIcon(notification.type),
            color: _getTypeColor(notification.type),
            size: 24,
          ),
        ),
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: notification.isUnread ? FontWeight.w600 : FontWeight.w500,
            color: const Color(0xFF3A3A50),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newAppointment:
        return Icons.event_available;
      case NotificationType.cancelledAppointment:
        return Icons.event_busy;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newAppointment:
        return Colors.blue;
      case NotificationType.cancelledAppointment:
        return Colors.orange;
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }

  void _handleNotificationTap(NotificationItem notification) async {
    // Mark as read
    await _markAsRead(int.parse(notification.relatedId));
    
    Navigator.pop(context); // Close bottom sheet
    
    // Navigate to action URL or default to appointments page
    final route = notification.actionUrl ?? '/counselor_appointments';
    Navigator.pushNamed(context, route);
  }

  @override
  void dispose() {
    Supabase.instance.client.removeAllChannels();
    super.dispose();
  }
}

enum NotificationType {
  newAppointment,
  cancelledAppointment,
}

class NotificationItem {
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isUnread;
  final String relatedId;
  final String? actionUrl;

  NotificationItem({
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isUnread = true,
    required this.relatedId,
    this.actionUrl,
  });
}
