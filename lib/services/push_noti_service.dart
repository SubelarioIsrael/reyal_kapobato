import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:breathe_better/services/notification_api.dart';

class PushNotiService {
  final notificationPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _currentUserId;
  final Map<String, int> _userNotificationIds = {};
  
  // Navigation key for routing
  static GlobalKey<NavigatorState>? _navigatorKey;
  
  // Store routes for notifications
  final Map<int, String> _notificationRoutes = {};

  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUserId;

  // SET CURRENT USER ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  // SET NAVIGATOR KEY
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  // GET NOTIFICATION ID FOR USER
  int _getNotificationIdForUser(String userId) {
    if (!_userNotificationIds.containsKey(userId)) {
      _userNotificationIds[userId] = _userNotificationIds.length + 1000;
    }
    return _userNotificationIds[userId]!;
  }

  // INITIALIZE
  Future<void> initNotification() async {
    if (_isInitialized) return;

    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
    );

    await notificationPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationTap(response);
      },
    );
    
    _isInitialized = true;
  }

  // HANDLE NOTIFICATION TAP
  void _handleNotificationTap(NotificationResponse response) {
    final notificationId = int.tryParse(response.id.toString());
    if (notificationId != null && _notificationRoutes.containsKey(notificationId)) {
      final route = _notificationRoutes[notificationId]!;
      
      if (_navigatorKey?.currentState != null) {
        _navigatorKey!.currentState!.pushNamed(route);
      }
    }
  }

  // NOTIFICATIONS DETAIL SETUP
  NotificationDetails notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
    );

    return const NotificationDetails(
      android: androidDetails,
    );
  }

  // SHOW NOTIFICATION
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? route,
  }) async {
    if (route != null) {
      _notificationRoutes[id] = route;
    }
    
    await notificationPlugin.show(
      id,
      title,
      body,
      notificationDetails(),
    );
  }

  // SHOW NOTIFICATION TO SPECIFIC USER
  Future<void> showNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String? route,
  }) async {
    // Only show notification if the target user is the current user
    if (_currentUserId != null && _currentUserId != userId) {
      // Don't show notification to wrong user
      return;
    }
    
    final notificationId = _getNotificationIdForUser(userId);
    
    if (route != null) {
      _notificationRoutes[notificationId] = route;
    }
    
    await notificationPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails(),
    );
  }

  // SHOW NOTIFICATION TO CURRENT USER
  Future<void> showNotificationToCurrentUser({
    required String title,
    required String body,
    String? route,
  }) async {
    if (_currentUserId == null) {
      throw Exception('No current user set. Call setCurrentUserId() first.');
    }

    await showNotificationToUser(
      userId: _currentUserId!,
      title: title,
      body: body,
      route: route,
    );
  }

  // REMOTE: Request server to send a push to a specific userId
  // (server will lookup tokens and deliver via FCM / OneSignal)
  Future<bool> sendRemoteNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final resp = await NotificationApi.sendToUser(userId, title: title, body: body, data: data);
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      print('sendRemoteNotificationToUser error: $e');
      return false;
    }
  }
  
  // REMOTE: Request server to send a push to a specific token
  Future<bool> sendRemoteNotificationToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final resp = await NotificationApi.sendToToken(token, title: title, body: body, data: data);
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      print('sendRemoteNotificationToToken error: $e');
      return false;
    }
  }

  // CANCEL NOTIFICATIONS FOR USER
  Future<void> cancelNotificationsForUser(String userId) async {
    if (_userNotificationIds.containsKey(userId)) {
      final notificationId = _userNotificationIds[userId]!;
      await notificationPlugin.cancel(notificationId);
      _notificationRoutes.remove(notificationId);
    }
  }

  // CANCEL ALL NOTIFICATIONS
  Future<void> cancelAllNotifications() async {
    await notificationPlugin.cancelAll();
    _userNotificationIds.clear();
    _notificationRoutes.clear();
  }
}