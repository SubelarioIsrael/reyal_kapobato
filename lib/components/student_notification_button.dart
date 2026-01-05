import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  RealtimeChannel? _notificationChannel;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      _notificationChannel = supabase
          .channel('student_notifications')
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
              if (mounted) {
                _fetchNotifications();
              }
            },
          )
          .subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh notifications when dependencies change (e.g., when returning to page)
    _fetchNotifications();
  }

  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['is_read']).length;

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
          if (unreadCount > 0)
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
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
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
    final unreadCount = _notifications.where((n) => !n['is_read']).length;

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
                  if (unreadCount > 0)
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
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
                      : RefreshIndicator(
                          key: _refreshKey,
                          onRefresh: _fetchNotifications,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              return _buildNotificationItem(_notifications[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isUnread = !(notification['is_read'] as bool? ?? false);
    final notificationType = notification['notification_type'] as String? ?? '';
    final content = notification['content'] as String? ?? '';
    final timestamp = DateTime.parse(notification['timestamp'] as String);
    final title = _getTypeTitle(notificationType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread
            ? _getTypeColor(notificationType).withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? _getTypeColor(notificationType).withOpacity(0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getTypeColor(notificationType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getTypeIcon(notificationType),
            color: _getTypeColor(notificationType),
            size: 24,
          ),
        ),
        title: title.isNotEmpty
            ? Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                  color: const Color(0xFF3A3A50),
                ),
              )
            : null,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) const SizedBox(height: 4),
            Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timestamp),
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

  IconData _getTypeIcon(String notificationType) {
    switch (notificationType) {
      case 'appointment_accepted':
        return Icons.check_circle;
      case 'appointment_rejected':
        return Icons.cancel;
      case 'appointment_completed':
        return Icons.event_available;
      case 'appointment_cancelled':
        return Icons.event_busy;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String notificationType) {
    switch (notificationType) {
      case 'appointment_accepted':
        return Colors.green;
      case 'appointment_rejected':
        return Colors.red;
      case 'appointment_completed':
        return Colors.blue;
      case 'appointment_cancelled':
        return Colors.orange;
      default:
        return const Color(0xFF7C83FD);
    }
  }

  String _getTypeTitle(String notificationType) {
    switch (notificationType) {
      case 'appointment_accepted':
        return 'Appointment Accepted';
      case 'appointment_rejected':
        return 'Appointment Rejected';
      case 'appointment_completed':
        return 'Appointment Completed';
      case 'appointment_cancelled':
        return 'Appointment Cancelled';
      default:
        return '';
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
