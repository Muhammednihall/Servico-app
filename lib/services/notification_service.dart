import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../screens/new_job_request_screen.dart';
import '../screens/job_details_screen.dart';
import '../screens/track_order_screen.dart';
import '../screens/customer_bookings_screen.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.notification?.title}');
  
  // Show local notification for background/terminated state
  // This ensures notifications appear even if Android doesn't auto-display them
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    iOS: DarwinInitializationSettings(),
  );
  await localNotifications.initialize(initSettings);
  
  // Create channel (needed on first background wake)
  await localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'servico_high_importance',
        'Servico Notifications',
        description: 'High importance notifications for job updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ));
  
  final title = message.notification?.title ?? message.data['title'] ?? 'Servico';
  final body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';
  
  if (title.isNotEmpty || body.isNotEmpty) {
    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'servico_high_importance',
          'Servico Notifications',
          channelDescription: 'High importance notifications for job updates',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
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
  StreamSubscription? _firestoreSubscription;
  StreamSubscription? _broadcastSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  final Set<String> _seenNotificationIds = {};

  // Note: App uses Cloud Functions for sending push notifications (secure production standard).
  // No server key is stored in the client codebase.

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
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_isInitialized) return;
    _navigatorKey = navigatorKey;

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

    // Request Android 13+ permissions
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // Set foreground notification presentation (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set foreground message handler
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for initial message (app opened from terminated state via notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay to allow navigator to be ready
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationTap(initialMessage);
      });
    }

    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
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
      icon: '@mipmap/launcher_icon',
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
    _navigateToScreen(message.data);
  }

  /// Handle notification tap from local notification
  void _handleLocalNotificationTap(Map<String, dynamic> data) {
    print('📱 Local notification tapped: $data');
    _navigateToScreen(data);
  }

  /// Centralized navigation logic based on notification data
  Future<void> _navigateToScreen(Map<String, dynamic> data) async {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      print('❌ Cannot navigate: No navigator context found');
      return;
    }

    final type = data['type'];
    final bookingId = data['bookingId'];

    if (bookingId == null || bookingId.isEmpty) {
      print('❌ No bookingId in notification data');
      return;
    }

    try {
      // Show loading indicator if possible or just proceed
      
      if (type == NotificationType.newJobRequest) {
        // Special handling for new job request - needs full data
        final bookingDoc = await _firestore.collection('booking_requests').doc(bookingId).get();
        if (!bookingDoc.exists) return;

        final bookingData = bookingDoc.data()!;
        bookingData['id'] = bookingId;

        final workerId = bookingData['workerId'];
        if (workerId == null) return;

        final workerDoc = await _firestore.collection('workers').doc(workerId).get();
        final workerName = workerDoc.exists ? (workerDoc.data()?['name'] ?? 'Worker') : 'Worker';

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewJobRequestScreen(
                request: bookingData,
                workerId: workerId,
                workerName: workerName,
              ),
            ),
          );
        }
      } else if (type == NotificationType.workerOnTheWay || 
                 type == NotificationType.workerArrived ||
                 type == NotificationType.workerDelayed ||
                 type == NotificationType.extraTimeRequested) {
        // Customer side tracking
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TrackOrderScreen(),
            ),
          );
        }
      } else if (type == NotificationType.jobAccepted || 
                 type == NotificationType.bookingConfirmed ||
                 type == NotificationType.jobCompleted) {
        // General booking details
        final bookingDoc = await _firestore.collection('booking_requests').doc(bookingId).get();
        if (!bookingDoc.exists) return;

        final bookingData = bookingDoc.data()!;
        bookingData['id'] = bookingId;

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsScreen(jobData: bookingData),
            ),
          );
        }
      } else {
        // Fallback: Go to bookings screen
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Check if worker or customer (simple check based on data or just default)
        // For now, default to customer bookings as a safe fallback
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerBookingsScreen(),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error during notification navigation: $e');
    }
  }

  /// Start listening to Firestore for new notifications to trigger local notifications
  /// This works without Cloud Functions by watching for new documents.
  bool _isFirstSnapshot = true;
  bool _isFirstBroadcastSnapshot = true;
  
  /// Set up Firestore listeners for notifications (Foreground - real-time sync)
  void startListeningToFirestoreNotifications(String userId, String userType) {
    _firestoreSubscription?.cancel();
    _broadcastSubscription?.cancel();
    
    _seenNotificationIds.clear();
    _isFirstSnapshot = true;
    _isFirstBroadcastSnapshot = true;
    
    final collection = userType == 'worker' ? 'worker_notifications' : 'customer_notifications';
    final userField = userType == 'worker' ? 'workerId' : 'customerId';

    // Only look at notifications from the last 5 minutes (prevents old notification flood)
    final recentCutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(minutes: 5)),
    );

    // 1. Listen for user-specific notifications (only recent & unread)
    _firestoreSubscription = _firestore
        .collection(collection)
        .where(userField, isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .where('createdAt', isGreaterThan: recentCutoff)
        .snapshots()
        .listen((snapshot) {
      
      if (_isFirstSnapshot) {
        // On first load, mark all existing ones as "seen" so they don't pop up
        for (final doc in snapshot.docs) { _seenNotificationIds.add(doc.id); }
        _isFirstSnapshot = false;
        return;
      }
      
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final doc = change.doc;
          final data = doc.data();
          if (data == null || _seenNotificationIds.contains(doc.id)) continue;
          _seenNotificationIds.add(doc.id);
          
          _showLocalNotification(
            title: data['title'] ?? 'Servico Update',
            body: data['message'] ?? data['body'] ?? '',
            payload: jsonEncode({
              'type': data['type'] ?? 'general',
              'bookingId': data['bookingId'] ?? '',
              'id': doc.id,
            }),
          );

          // Mark as read so it won't show again on next app open
          _firestore.collection(collection).doc(doc.id).update({'isRead': true});
        }
      }
    }, onError: (e) => print('❌ Notification sync error: $e'));

    // 2. Listen for global broadcasts (only recent ones)
    final broadcastCutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(minutes: 5)),
    );

    _broadcastSubscription = _firestore
        .collection('broadcast_notifications')
        .where('createdAt', isGreaterThan: broadcastCutoff)
        .snapshots()
        .listen((snapshot) {
      
      if (_isFirstBroadcastSnapshot) {
        for (final doc in snapshot.docs) { _seenNotificationIds.add('broad_${doc.id}'); }
        _isFirstBroadcastSnapshot = false;
        return;
      }
      
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final doc = change.doc;
          final data = doc.data();
          if (data == null || _seenNotificationIds.contains('broad_${doc.id}')) continue;
          _seenNotificationIds.add('broad_${doc.id}');
          
          final target = data['targetTopic'] ?? 'all';
          if (target == 'all' || (target == 'workers' && userType == 'worker') || (target == 'customers' && userType == 'customer')) {
            _showLocalNotification(
              title: data['title'] ?? 'Announcement',
              body: data['body'] ?? '',
              payload: jsonEncode({'type': 'broadcast', 'id': doc.id}),
            );
          }
        }
      }
    });
  }

  /// Stop listening to Firestore notifications
  void stopListeningToFirestoreNotifications() {
    _firestoreSubscription?.cancel();
    _broadcastSubscription?.cancel();
    _firestoreSubscription = null;
    _broadcastSubscription = null;
    _seenNotificationIds.clear();
  }

  /// Get FCM token and save to user profile
  Future<String?> getAndSaveToken({
    required String userId,
    required String userType,
  }) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return null;

      final collection = userType == 'worker' ? 'workers' : 'customers';
      await _firestore.collection(collection).doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      _messaging.onTokenRefresh.listen((newToken) {
        _firestore.collection(collection).doc(userId).update({
          'fcmToken': newToken,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      });

      await _messaging.subscribeToTopic('all');
      await _messaging.subscribeToTopic(userType == 'worker' ? 'workers' : 'customers');

      return token;
    } catch (e) {
      print('❌ Error saving FCM token: $e');
      return null;
    }
  }

  /// Send notification to a user by writing to Firestore.
  /// A Cloud Function watches these collections and sends the actual push notification.
  /// (Secure production method - no server key needed in client app)
  Future<void> sendNotificationToUser({
    required String userId,
    required String userType,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final collection = userType == 'worker' ? 'worker_notifications' : 'customer_notifications';
      await _firestore.collection(collection).add({
        if (userType == 'worker') 'workerId': userId,
        if (userType == 'customer') 'customerId': userId,
        'title': title,
        'message': body,
        'body': body,
        'imageUrl': imageUrl,
        'data': data ?? {},
        'type': data?['type'] ?? 'general',
        'bookingId': data?['bookingId'] ?? '',
        'isRead': false,
        'isSent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Notification queued via Firestore for $userType: $userId');
    } catch (e) {
      print('❌ Error queuing notification: $e');
    }
  }

  /// Sends a broadcast notification to a topic via Firestore trigger.
  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
    String? imageUrl,
    required String targetTopic,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('broadcast_notifications').add({
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'targetTopic': targetTopic,
        'data': data ?? {},
        'isSent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Broadcast queued via Firestore for: $targetTopic');
    } catch (e) {
      print('❌ Error queuing broadcast: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _foregroundSubscription?.cancel();
    _firestoreSubscription?.cancel();
    _broadcastSubscription?.cancel();
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
