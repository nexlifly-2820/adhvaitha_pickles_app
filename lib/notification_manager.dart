import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
      
      // 2. Setup Local Notifications for Foreground
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          print("Notification tapped: ${details.payload}");
        },
      );

      // 3. Listen for Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Message received in foreground: ${message.notification?.title}");
        _showLocalNotification(message);
      });

      // 4. Handle Notification Taps (App in Background/Terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("App opened via notification: ${message.data}");
      });

      // 5. Check if app was opened from a terminated state
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        print("App launched from terminated state via notification");
      }

      // 6. Sync Token & Topics
      await updateToken();
      await _fcm.subscribeToTopic('marketing');
    }
  }

  Future<void> updateToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': 'android',
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error updating FCM token: $e");
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

  void _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    String? imageUrl = message.data['image'] ?? notification?.android?.imageUrl;

    BigPictureStyleInformation? bigPictureStyleInformation;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final String largeIconPath = await _downloadAndSaveFile(imageUrl, 'largeIcon');
      final String bigPicturePath = await _downloadAndSaveFile(imageUrl, 'bigPicture');

      bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        largeIcon: FilePathAndroidBitmap(largeIconPath),
        contentTitle: notification?.title,
        summaryText: notification?.body,
      );
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
