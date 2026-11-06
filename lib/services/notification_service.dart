import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../models/notification.dart';
import 'api_service.dart';
import '../screens/chat_detail_screen.dart';
import '../screens/notifications_screen.dart';
import '../main.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static Future<void> init() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Initialize Local Notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationClick();
      },
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick();
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick();
    });
  }

  /// Request permissions if not already granted.
  /// Avoids re-requesting background location every time to prevent annoying the user.
  static Future<void> requestPermissions() async {
    debugPrint("--- Checking Permissions ---");

    // 1. Notifications (Android 13+)
    NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined || 
        settings.authorizationStatus == AuthorizationStatus.denied) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 2. Foreground Location
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // We only request if it's not deniedForever. 
      // If it's deniedForever, we shouldn't keep asking.
      permission = await Geolocator.requestPermission();
    }

    // 3. Background Location
    // Only request background location if we really need it and don't have it yet.
    // If the user gave "whileInUse", we respect that and don't keep nagging for "Always".
    // Most apps don't need "Always" unless they do geofencing or constant tracking.
    /* 
    if (permission == LocationPermission.whileInUse) {
      // Optionally request background here, but since the user is annoyed, we stop nagging.
      debugPrint("Foreground location granted. Skipping background location nag.");
    }
    */
    
    debugPrint("--- Permission Check Finished ---");
  }

  static void _handleNotificationClick() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  static void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // API Methods
  static Future<List<AppNotification>> getNotifications({int limit = 20, int offset = 0}) async {
    final data = await ApiService.get('/notifications?limit=$limit&offset=$offset');
    if (data != null && data['notifications'] != null) {
      return (data['notifications'] as List).map((e) => AppNotification.fromJson(e)).toList();
    }
    return [];
  }

  static Future<int> getUnreadCount() async {
    final data = await ApiService.get('/notifications/unread-count');
    return data != null ? (data['unread'] ?? 0) : 0;
  }

  static Future<void> markAsRead(String notificationId) async {
    await ApiService.post('/notifications/$notificationId/read');
  }

  static Future<void> markAllAsRead() async {
    await ApiService.post('/notifications/read-all');
  }

  static void handleDeepLink(BuildContext context, AppNotification notification) {
    if (notification.deepLink != null && notification.deepLink!.startsWith('chat')) {
      final userId = notification.relatedId;
      if (userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              receiverId: userId,
              receiverName: notification.title.isNotEmpty ? notification.title : 'User',
            ),
          ),
        );
      }
    }
  }
}
