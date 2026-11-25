import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'user_manager.dart';
import 'dart:convert';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Order updates and offers from Ambhujakshi.',
    importance: Importance.max,
  );
  bool _started = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      // channel used by notifications sent from the admin (also when the app is closed)
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      await _localNotifications.initialize(
        const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'), iOS: DarwinInitializationSettings()),
        onDidReceiveNotificationResponse: (NotificationResponse details) => debugPrint('Notification tapped: ${details.payload}'),
      );

      // Android 13+ needs this runtime permission, iOS asks too
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      await _fcm.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

      FirebaseMessaging.onMessage.listen(_showLocalNotification);
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) => debugPrint('Opened from notification: ${m.data}'));

      // "All users" notifications
      await _fcm.subscribeToTopic('marketing');

      // personal notifications: keep this phone's token linked to the signed-in customer
      await updateToken();
      _fcm.onTokenRefresh.listen((_) => updateToken());
      FirebaseAuth.instance.authStateChanges().listen((_) => updateToken());
    } catch (e) {
      debugPrint('Notification setup failed: $e');
    }
  }

  Future<void> updateToken() async {
    try {
      final String? token = await _fcm.getToken();
      if (token == null) return;
      final String userId = UserManager().currentUserId;
      await http
          .post(Uri.parse('https://admin.adhvaithafoods.in/api/push/register'),
              headers: const <String, String>{'Content-Type': 'application/json'}, body: jsonEncode(<String, String>{'userId': userId, 'token': token}))
          .timeout(const Duration(seconds: 10));
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) await ApiService.saveFcmToken(userId: user.uid, token: token); // older server copy
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    String? imageUrl = message.data['image'] ?? notification?.android?.imageUrl;

    BigPictureStyleInformation? bigPictureStyleInformation;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
      final String largeIconPath = await _downloadAndSaveFile(imageUrl, 'largeIcon');
      final String bigPicturePath = await _downloadAndSaveFile(imageUrl, 'bigPicture');

      bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        largeIcon: FilePathAndroidBitmap(largeIconPath),
        contentTitle: notification?.title,
        summaryText: notification?.body,
      );
      } catch (_) {}
    }

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', 
            'High Importance Notifications',
            channelDescription: 'Used for important royal updates.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: bigPictureStyleInformation,
            playSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}
