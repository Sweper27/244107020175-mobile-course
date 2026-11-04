import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM setup, local notification display, and notification interactions.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Callback invoked when a notification is tapped (with announcementId).
  void Function(String announcementId)? onNotificationTap;

  /// Android notification channel for campus notifications.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'campus_notification', // id
    'Campus Notification', // name
    description: 'Notifikasi pengumuman kampus',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Request notification permission
    await _requestPermission();

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Get FCM token
    await _getFcmToken();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen for notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Checks if app was opened from a terminated state via notification.
  Future<RemoteMessage?> getInitialMessage() async {
    return _messaging.getInitialMessage();
  }

  /// Requests notification permission from the user.
  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      developer.log(
        'Permission status: ${settings.authorizationStatus}',
        name: 'Notification',
      );
    } catch (e) {
      developer.log('Permission request failed: $e', name: 'Notification');
    }
  }

  /// Gets the FCM token for this device.
  Future<void> _getFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final partial = token.length > 20
            ? '${token.substring(0, 20)}...'
            : token;
        developer.log('Token (partial): $partial', name: 'FCM');
      } else {
        developer.log('Token is null', name: 'FCM');
      }
    } catch (e) {
      developer.log('Failed to get token: $e', name: 'FCM');
    }
  }

  /// Handles foreground FCM messages by showing a local notification.
  void _handleForegroundMessage(RemoteMessage message) {
    developer.log('Foreground message received', name: 'FCM');

    final notification = message.notification;
    if (notification == null) return;

    final announcementId = message.data['announcementId'] ?? '';

    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'Campus Notification',
      notification.body ?? 'Ada pengumuman baru!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: announcementId,
    );
  }

  /// Handles notification tap when app was in background.
  void _handleMessageOpenedApp(RemoteMessage message) {
    developer.log('Message opened app', name: 'FCM');
    final announcementId = message.data['announcementId'];
    if (announcementId != null && onNotificationTap != null) {
      onNotificationTap!(announcementId);
    }
  }

  /// Handles local notification tap.
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty && onNotificationTap != null) {
      onNotificationTap!(payload);
    }
  }
}
