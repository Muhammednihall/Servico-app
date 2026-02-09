import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.notification?.title}');
}

/// Notification Service for handling FCM push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;
  StreamSubscription? _foregroundSubscription;

  /// Android notification channel for high-priority notifications
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'servico_high_importance',
    'Servico Notifications',
    description: 'High importance notifications for job updates',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('❌ Push notification permission denied');
      return;
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Set up foreground message handler
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for initial message (app opened from terminated state via notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          _handleLocalNotificationTap(data);
        }
      },
    );

    // Create notification channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Servico',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    String? body,
    String? imageUrl,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'servico_high_importance',
      'Servico Notifications',
      channelDescription: 'High importance notifications for job updates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap from FCM
  void _handleNotificationTap(RemoteMessage message) {
    print('📱 Notification tapped: ${message.data}');
    // Navigate based on notification type
    // This would typically use a navigation service or global key
  }

  /// Handle notification tap from local notification
  void _handleLocalNotificationTap(Map<String, dynamic> data) {
    print('📱 Local notification tapped: $data');
  }

  /// Get FCM token and save to user profile
  Future<String?> getAndSaveToken({
    required String userId,
    required String userType, // 'customer' or 'worker'
  }) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return null;

      // Save token to appropriate collection
      final collection = userType == 'worker' ? 'workers' : 'customers';
      await _firestore.collection(collection).doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _firestore.collection(collection).doc(userId).update({
          'fcmToken': newToken,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      });

      print('✅ FCM token saved for $userType: ${token.substring(0, 20)}...');
      return token;
    } catch (e) {
      print('❌ Error saving FCM token: $e');
      return null;
    }
  }

  /// Send notification to a specific user (using Cloud Functions or direct Firestore)
  /// Note: In production, use Cloud Functions for secure server-side sending
  Future<void> sendNotificationToUser({
    required String userId,
    required String userType,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Store notification in Firestore (will be picked up by Cloud Function)
      final notificationCollection = userType == 'worker' 
          ? 'worker_notifications' 
          : 'customer_notifications';

      await _firestore.collection(notificationCollection).add({
        'userId': userId,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'data': data ?? {},
        'isRead': false,
        'isSent': false, // Cloud Function will mark as true after sending
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notification queued for $userType: $userId');
    } catch (e) {
      print('❌ Error queuing notification: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _foregroundSubscription?.cancel();
  }
}

// ==================== NOTIFICATION TYPES ====================

/// Notification types for easy identification
class NotificationType {
  // Worker notifications
  static const String delayReported = 'delay_reported';
  static const String delayPenalty = 'delay_penalty';
  static const String newJobRequest = 'new_job_request';
  static const String rescueJobOffer = 'rescue_job_offer';
  static const String jobAccepted = 'job_accepted';
  static const String jobCancelled = 'job_cancelled';
  static const String extraTimeResponse = 'extra_time_response';

  // Customer notifications
  static const String workerOnTheWay = 'worker_on_the_way';
  static const String workerArrived = 'worker_arrived';
  static const String jobCompleted = 'job_completed';
  static const String rescueWorkerAssigned = 'rescue_worker_assigned';
  static const String bookingConfirmed = 'booking_confirmed';
  static const String workerDelayed = 'worker_delayed';
  static const String extraTimeRequested = 'extra_time_requested';
}
