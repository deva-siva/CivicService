import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
}

class NotificationService {
  static FirebaseMessaging? get _messaging {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'smart_grievance_channel',
    'Smart Grievance Notifications',
    description: 'Notifications for complaint status updates',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    final messaging = _messaging;
    if (messaging != null) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    if (messaging != null) {
      // Foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        _showLocalNotification(message);
      });

      // Tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleNotificationTap(message.data);
      });

      // Tap when app was terminated
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        // Delay so navigator is ready
        await Future.delayed(const Duration(milliseconds: 500));
        _handleNotificationTap(initial.data);
      }
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final complaintId = int.tryParse(payload);
    if (complaintId == null) return;
    _navigateToComplaint(complaintId);
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final raw = data['complaint_id'];
    if (raw == null) return;
    final complaintId = int.tryParse(raw.toString());
    if (complaintId == null) return;
    _navigateToComplaint(complaintId);
  }

  static void _navigateToComplaint(int complaintId) {
    final context = ApiService.navigatorKey?.currentContext;
    if (context == null) return;
    // Lazy import to avoid circular dependency
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/complaint-detail',
      arguments: complaintId,
    );
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['complaint_id'],
    );
  }

  static const _vapidKey =
      'AdrTqXFmQR3m7_3Hrhb4i0eirviNhmMv-LDVOtFaDY1Aox3HG3phGH5O6w8MXqPWBe0MqXFmfsv2W_d3JQ3uJg8k72uEfA510R4u5zkoTHCj93sOO_mdO0-BeJJIUgnOBPsGVf7fLhRKx9vO1Z0vV7fg-w';

  static Future<String?> getToken() async {
    try {
      return await _messaging?.getToken(vapidKey: _vapidKey);
    } catch (_) {
      return null;
    }
  }

  static Stream<String> get onTokenRefresh =>
      _messaging?.onTokenRefresh ?? const Stream.empty();
}
