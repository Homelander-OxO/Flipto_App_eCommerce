import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseApi {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static String? fcmToken;

  // ✅ Static method to initialize Firebase Messaging & Notifications
  static Future<void> initNotification() async {
    // ✅ Request permission for push notifications
    await _firebaseMessaging.requestPermission();

    // ✅ Delete the previous FCM token to ensure a new one is generated
    await _firebaseMessaging.deleteToken();

    // ✅ Generate a fresh FCM token
    fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print('🔹 New FCM Token: $fcmToken');
    } else {
      print('❌ Failed to get FCM Token');
    }

    // ✅ Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // ✅ Handle notifications when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(
          message.notification!.title ?? 'No Title',
          message.notification!.body ?? 'No Body',
        );
      }
    });
  }

  // ✅ Show notification when the app is in the foreground
  static Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _flutterLocalNotificationsPlugin.show(
      notificationId, // ✅ Use a unique ID
      title,
      body,
      notificationDetails,
    );
  }
}
