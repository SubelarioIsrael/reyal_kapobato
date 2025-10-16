// import 'dart:convert';

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class PushNotifications {
//   PushNotifications._();

//   static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin _local =
//       FlutterLocalNotificationsPlugin();

//   static const AndroidNotificationChannel _defaultChannel =
//       AndroidNotificationChannel(
//     'bb_default_channel',
//     'General Notifications',
//     description: 'General updates and alerts',
//     importance: Importance.high,
//   );

//   static Future<void> initialize({
//     required GlobalKey<NavigatorState> navigatorKey,
//   }) async {
//     // Local notifications init
//     const AndroidInitializationSettings androidInit =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     const InitializationSettings initSettings =
//         InitializationSettings(android: androidInit);
//     await _local.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         final payload = response.payload;
//         if (payload == null || payload.isEmpty) return;
//         _handleTapPayload(navigatorKey, payload);
//       },
//     );

//     // Create channel (Android)
//     final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
//         _local.resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>();
//     await androidPlugin?.createNotificationChannel(_defaultChannel);

//     // Ask FCM permission (Android 13+)
//     await _messaging.requestPermission();

//     // Background message handler must be registered at startup
//     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

//     // Foreground message handler
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//       await _display(message);
//     });

//     // Tap from terminated/background state
//     final initialMessage = await _messaging.getInitialMessage();
//     if (initialMessage != null) {
//       _navigateFromMessage(navigatorKey, initialMessage);
//     }
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       _navigateFromMessage(navigatorKey, message);
//     });
//   }

//   static Future<String?> getFcmToken() => _messaging.getToken();

//   static Future<void> _display(RemoteMessage message) async {
//     final notification = message.notification;
//     final android = message.notification?.android;
//     final data = message.data;

//     final title = notification?.title ?? data['title'] ?? 'Notification';
//     final body = notification?.body ?? data['body'] ?? '';
//     final payload = jsonEncode(data);

//     final AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       _defaultChannel.id,
//       _defaultChannel.name,
//       channelDescription: _defaultChannel.description,
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//       enableVibration: true,
//     );

//     final NotificationDetails details =
//         NotificationDetails(android: androidDetails);

//     await _local.show(
//       DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       title,
//       body,
//       details,
//       payload: payload,
//     );
//   }

//   static void _navigateFromMessage(
//       GlobalKey<NavigatorState> navigatorKey, RemoteMessage message) {
//     _handleTapPayload(navigatorKey, jsonEncode(message.data));
//   }

//   static void _handleTapPayload(
//       GlobalKey<NavigatorState> navigatorKey, String payload) {
//     try {
//       final Map<String, dynamic> data = jsonDecode(payload);
//       final String? route = data['route'] as String?;
//       final Map<String, dynamic>? arguments =
//           (data['args'] is Map<String, dynamic>) ? data['args'] : null;

//       if (route != null && route.isNotEmpty) {
//         navigatorKey.currentState?.pushNamed(route, arguments: arguments);
//       }
//     } catch (_) {
//       // Ignore malformed payloads
//     }
//   }
// }

// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await PushNotifications._display(message);
// }
