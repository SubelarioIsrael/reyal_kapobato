import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CounselorNotificationButton extends StatefulWidget {
  const CounselorNotificationButton({super.key});

  @override
  State<CounselorNotificationButton> createState() => CounselorNotificationButtonState();
}

class CounselorNotificationButtonState extends State<CounselorNotificationButton> {
  int _notificationCount = 0;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
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
              _loadNotifications();
            },
          )
          .subscribe();
    }
  }

  // make a public method so parent can trigger refresh on swipe-to-refresh
  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

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
        final title = notification['title'] ?? _mapDefaultTitle(notificationType);

        NotificationType? type = _mapType(notificationType);

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

      setState(() {
        _notifications = notifications;
        _notificationCount = notifications.where((n) => n.isUnread).length;
      });
    } catch (_) {
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
        final index =
            _notifications.indexWhere((n) => n.relatedId == notificationId.toString());
        if (index != -1) {
          _notifications[index].isUnread = false;
          _notificationCount = _notifications.where((n) => n.isUnread).length;
        }
      });
    } catch (_) {}
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
        for (var n in _notifications) {
          n.isUnread = false;
        }
        _notificationCount = 0;
      });
    } catch (_) {}
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
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
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

  Widget _buildNotificationItem(NotificationItem n) {
    final color = _getTypeColor(n.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: n.isUnread ? color.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: n.isUnread ? color.withOpacity(0.2) : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getTypeIcon(n.type),
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          n.title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: n.isUnread ? FontWeight.w600 : FontWeight.w500,
            color: const Color(0xFF3A3A50),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              n.message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(n.timestamp),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(n),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType? type) {
    switch (type) {
      case NotificationType.newAppointment:
        return Icons.event_available;
      case NotificationType.cancelledAppointment:
        return Icons.event_busy;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(NotificationType? type) {
    switch (type) {
      case NotificationType.newAppointment:
        return Colors.blue;
      case NotificationType.cancelledAppointment:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime dt) {
    // Timestamps are already in Philippine time (UTC+8)
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd, yyyy').format(dt);
  }

  void _handleNotificationTap(NotificationItem n) async {
    await _markAsRead(int.parse(n.relatedId));
    Navigator.pop(context);
    Navigator.pushNamed(context, n.actionUrl ?? '/counselor_appointments');
  }

  @override
  void dispose() {
    Supabase.instance.client.removeAllChannels();
    super.dispose();
  }

  NotificationType? _mapType(String? raw) {
    switch (raw) {
      case 'appointment_booked':
        return NotificationType.newAppointment;
      case 'appointment_cancelled':
        return NotificationType.cancelledAppointment;
      default:
        return null;
    }
  }

  String _mapDefaultTitle(String? raw) {
    if (raw == null) return 'Notification';
    return raw.replaceAll('_', ' ').toUpperCase();
  }
}

enum NotificationType { newAppointment, cancelledAppointment }

class NotificationItem {
  final NotificationType? type;
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
    required this.isUnread,
    required this.relatedId,
    this.actionUrl,
  });
}
