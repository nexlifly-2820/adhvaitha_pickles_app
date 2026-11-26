import 'dart:io';
import 'profile_extras.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'user_manager.dart';
import 'dart:convert';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'smart_notifications.dart';

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

  // brand icon if it is in the build, otherwise the app icon (never let a missing icon block notifications)
  String _icon = 'ic_stat_ambhujakshi';
  bool _logoOk = true;

  Future<void> init() async {
    if (_started) return;
    _started = true;

    // 1. receiving pushes comes first and must never depend on anything else
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage m) => _showLocalNotification(m));
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) => debugPrint('Opened from notification: ${m.data}'));
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      await _fcm.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      await _fcm.subscribeToTopic('marketing');
    } catch (e) {
      debugPrint('FCM setup failed: $e');
    }

    // 2. local notifications (used to show pushes while the app is open + reminders)
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);
      try {
        await _localNotifications.initialize(
          const InitializationSettings(android: AndroidInitializationSettings('ic_stat_ambhujakshi'), iOS: DarwinInitializationSettings()),
          onDidReceiveNotificationResponse: (NotificationResponse d) => debugPrint('Notification tapped: ${d.payload}'),
        );
      } catch (e) {
        debugPrint('Brand notification icon not in this build yet ($e) — using the app icon');
        _icon = '@mipmap/ic_launcher';
        _logoOk = false;
        await _localNotifications.initialize(
          const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'), iOS: DarwinInitializationSettings()),
          onDidReceiveNotificationResponse: (NotificationResponse d) => debugPrint('Notification tapped: ${d.payload}'),
        );
      }
      await android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Local notification setup failed: $e');
    }

    // 3. link this phone to the customer (personal + order notifications)
    try {
      await updateToken();
      _fcm.onTokenRefresh.listen((_) => updateToken());
      FirebaseAuth.instance.authStateChanges().listen((_) => updateToken());
    } catch (e) {
      debugPrint('Token setup failed: $e');
    }

    // 4. automatic reminders (cart, viewed, wishlist, after-order, we-miss-you)
    try {
      tzdata.initializeTimeZones();
      await SmartNotifications.start(_localNotifications, _channel, icon: _icon, withLogo: _logoOk);
    } catch (e) {
      debugPrint('Smart reminders not started: $e');
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
      final String bigPicturePath = await _downloadAndSaveFile(imageUrl, 'bigPicture');

      bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        hideExpandedLargeIcon: true,
        contentTitle: notification?.title,
        summaryText: notification?.body,
      );
      } catch (_) {}
    }

    if (notification == null) return;
    await AppPrefs().load();
    final String type = '${message.data['type'] ?? ''}';
    if (type == 'order_status' && !AppPrefs().orderUpdates) return;
    if (type != 'order_status' && message.from == '/topics/marketing' && !AppPrefs().offers) return;
    Future<void> show({required bool styled}) => _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: styled ? _icon : '@mipmap/ic_launcher',
              largeIcon: styled && _logoOk ? const DrawableResourceAndroidBitmap('notification_logo') : null,
              color: const Color(0xFF7A1426),
              styleInformation: styled ? (bigPictureStyleInformation ?? BigTextStyleInformation(notification.body ?? '')) : null,
              playSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
    try {
      await show(styled: true);
    } catch (e) {
      debugPrint('Styled notification failed ($e) — showing a plain one');
      try {
        await show(styled: false);
      } catch (_) {}
    }
  }
}
