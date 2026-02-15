import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_service.dart';
import 'notification_service.dart';
import 'dart:async';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Create a new booking request
  Future<String> createBookingRequest({
    required String workerId,
    required String workerName,
    required String serviceName,
    required double price,
    int duration = 1,
    String? customerId,
    String? customerName,
    String? customerAddress,
    Map<String, double>? customerCoordinates,
    bool isTokenBooking = false,
    int? tokenPosition,
    DateTime? startTime,
    DateTime? estimatedStartTime,
  }) async {
    final docRef = _firestore.collection('booking_requests').doc();
    final now = DateTime.now();

    // Token bookings don't expire as quickly
    final expiresAt = isTokenBooking
        ? now.add(const Duration(hours: 24))
        : now.add(const Duration(minutes: 1));

    await docRef.set({
      'id': docRef.id,
      'workerId': workerId,
      'workerName': workerName,
      'serviceName': serviceName,
      'price': price,
      'duration': duration,
      'customerId': customerId,
      'customerName': customerName ?? 'User',
      'customerAddress': customerAddress ?? 'Address not provided',
      'customerCoordinates':
          customerCoordinates ??
          {'lat': 40.7128, 'lng': -74.0060}, // Mock coordinates (NYC)
      'status': 'pending',
      'isTokenBooking': isTokenBooking,
      'tokenPosition': tokenPosition,
      'estimatedStartTime': estimatedStartTime != null
          ? Timestamp.fromDate(estimatedStartTime)
          : null,
      'startTime': startTime != null ? Timestamp.fromDate(startTime) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt,
      'extraTimeRequest': null,
    });

    return docRef.id;
  }

  /// Stream a specific booking request
  Stream<DocumentSnapshot> streamBookingRequest(String requestId) {
    return _firestore.collection('booking_requests').doc(requestId).snapshots();
  }

  /// Stream all bookings for a customer
  Stream<List<Map<String, dynamic>>> streamCustomerBookings(
    String customerId, {
    int? limit,
  }) {
    var query = _firestore
        .collection('booking_requests')
        .where('customerId', isEqualTo: customerId);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs.map((doc) => doc.data()).toList();
      docs.sort((a, b) {
        final t1 = (a['createdAt'] as Timestamp?);
        final t2 = (b['createdAt'] as Timestamp?);
        if (t1 == null || t2 == null) return 0;
        return t2.compareTo(t1);
      });
      return docs;
    });
  }

  /// Stream upcoming schedule (pending & accepted requests) for a worker
  Stream<List<Map<String, dynamic>>> streamUpcomingSchedule(String workerId) {
    return _firestore
        .collection('booking_requests')
        .where('workerId', isEqualTo: workerId)
        .where(
          'status',
          whereIn: ['pending', 'accepted', 'assigned', 'in_progress'],
        )
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          docs.sort((a, b) {
            final t1 =
                (a['startTime'] ??
                        a['scheduledTime'] ??
                        a['estimatedStartTime'] ??
                        a['createdAt'])
                    as Timestamp?;
            final t2 =
                (b['startTime'] ??
                        b['scheduledTime'] ??
                        b['estimatedStartTime'] ??
                        b['createdAt'])
                    as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t1.compareTo(t2);
          });
          return docs;
        });
  }

  /// Stream incoming requests for a worker (only pending)
  Stream<List<Map<String, dynamic>>> streamWorkerRequests(String workerId) {
    return _firestore
        .collection('booking_requests')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          docs.sort((a, b) {
            final t1 = (a['updatedAt'] ?? a['createdAt']) as Timestamp?;
            final t2 = (b['updatedAt'] ?? b['createdAt']) as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t2.compareTo(t1);
          });
          return docs;
        });
  }

  /// Update request status
  Future<void> updateRequestStatus(String requestId, String status) async {
    final doc = await _firestore
        .collection('booking_requests')
        .doc(requestId)
        .get();
    if (!doc.exists) return;

    final updateData = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'accepted') {
      updateData['acceptedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore
        .collection('booking_requests')
        .doc(requestId)
        .update(updateData);

    if (status == 'accepted') {
      final data = doc.data() as Map<String, dynamic>;
      await _firestore.collection('jobs').doc(requestId).set({
        ...data,
        'id': requestId,
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
        'acceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Stream active jobs for a worker
  Stream<List<Map<String, dynamic>>> streamActiveJobs(String workerId) {
    return _firestore
        .collection('booking_requests')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          docs.sort((a, b) {
            final t1 = (a['updatedAt'] ?? a['createdAt']) as Timestamp?;
            final t2 = (b['updatedAt'] ?? b['createdAt']) as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t2.compareTo(t1);
          });
          return docs;
        });
  }

  /// Stream completed jobs for a worker
  Stream<List<Map<String, dynamic>>> streamWorkerCompletedJobs(
    String workerId,
  ) {
    return _firestore
        .collection('booking_requests')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          docs.sort((a, b) {
            final t1 = (a['updatedAt'] ?? a['createdAt']) as Timestamp?;
            final t2 = (b['updatedAt'] ?? b['createdAt']) as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t2.compareTo(t1);
          });
          return docs;
        });
  }

  /// Stream cancelled jobs for a customer
  Stream<List<Map<String, dynamic>>> streamCancelledJobs(String customerId) {
    return _firestore
        .collection('booking_requests')
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: 'cancelled')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Update worker status (legacy/general)
  Future<void> updateWorkerStatus(
    String requestId,
    String status, {
    int? estimatedMinutes,
  }) async {
    final updateData = <String, dynamic>{
      'workerStatus': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (estimatedMinutes != null) {
      updateData['estimatedArrivalMinutes'] = estimatedMinutes;
    }
    await _firestore
        .collection('booking_requests')
        .doc(requestId)
        .update(updateData);

    final doc = await _firestore
        .collection('booking_requests')
        .doc(requestId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      final customerId = data['customerId'] as String?;
      final workerName = data['workerName'] as String? ?? 'Provider';

      if (customerId != null) {
        String title = '';
        String message = '';
        String type = '';

        if (status == 'on_the_way') {
          title = '🚗 Provider on the way!';
          message =
              '$workerName is heading to your location.${estimatedMinutes != null ? ' (ETA: $estimatedMinutes mins)' : ''}';
          type = NotificationType.workerOnTheWay;
        } else if (status == 'arrived') {
          title = '📍 Provider Arrived!';
          message = '$workerName has arrived at your location.';
          type = NotificationType.workerArrived;
        } else if (status == 'working') {
          title = '🛠️ Work Started';
          message = '$workerName has started working on your request.';
          type = 'worker_working';
        }

        if (title.isNotEmpty) {
          await _createCustomerNotification(
            customerId: customerId,
            title: title,
            message: message,
            type: type,
            bookingId: requestId,
          );
        }
      }
    }
  }

  /// Specific status updates matching UI calls
  Future<void> updateWorkerStatusOnTheWay({
    required String requestId,
    int? estimatedMinutes,
  }) async => updateWorkerStatus(
    requestId,
    'on_the_way',
    estimatedMinutes: estimatedMinutes,
  );

  Future<void> updateWorkerStatusArrived(String requestId) async =>
      updateWorkerStatus(requestId, 'arrived');

  Future<void> updateWorkerStatusWorking(String requestId) async =>
      updateWorkerStatus(requestId, 'working');

  /// Complete job
  Future<void> completeJob(String requestId) async {
    try {
      final doc = await _firestore
          .collection('booking_requests')
          .doc(requestId)
          .get();
      final data = doc.data();
      if (data == null) return;

      final workerId = data['workerId'];
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      final duration = (data['duration'] as num?)?.toInt() ?? 1;
      final totalAmount = price * duration;

      await updateRequestStatus(requestId, 'completed');

      final workerService = WorkerService();
      await workerService.creditWorkerBalance(workerId, totalAmount, requestId);

      final customerId = data['customerId'] as String?;
      if (customerId != null) {
        await _createCustomerNotification(
          customerId: customerId,
          title: '✅ Job Completed!',
          message: 'Your job has been completed. Please rate your experience!',
          type: NotificationType.jobCompleted,
          bookingId: requestId,
        );
      }
    } catch (e) {
      print('❌ Error completing job: $e');
      rethrow;
    }
  }

  /// Submit review (Primary name)
  Future<void> submitReview({
    required String requestId,
    required String workerId,
    required String customerId,
    required String customerName,
    required double rating,
    required String review,
  }) async {
    await submitWorkerReview(
      requestId: requestId,
      workerId: workerId,
      customerId: customerId,
      customerName: customerName,
      rating: rating,
      review: review,
    );
  }

  /// Internal worker review method
  Future<void> submitWorkerReview({
    required String requestId,
    required String workerId,
    required String customerId,
    required String customerName,
    required double rating,
    required String review,
  }) async {
    try {
      final batch = _firestore.batch();
      final requestRef = _firestore
          .collection('booking_requests')
          .doc(requestId);
      batch.update(requestRef, {
        'rating': rating,
        'review': review,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      final ratingRef = _firestore.collection('ratings').doc();
      batch.set(ratingRef, {
        'id': ratingRef.id,
        'requestId': requestId,
        'workerId': workerId,
        'ratedUserId': workerId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'review': review,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      final workerRef = _firestore.collection('workers').doc(workerId);
      await _firestore.runTransaction((transaction) async {
        final workerDoc = await transaction.get(workerRef);
        if (!workerDoc.exists) return;

        final currentRating =
            (workerDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
        final totalReviews =
            (workerDoc.data()?['totalReviews'] as num?)?.toInt() ?? 0;

        final newTotalReviews = totalReviews + 1;
        final newRating =
            ((currentRating * totalReviews) + rating) / newTotalReviews;

        transaction.update(workerRef, {
          'rating': newRating,
          'totalReviews': newTotalReviews,
        });
      });
    } catch (e) {
      print('❌ Error submitting review: $e');
      rethrow;
    }
  }

  /// General cancel booking
  Future<void> cancelBooking(String requestId) async {
    final doc = await _firestore
        .collection('booking_requests')
        .doc(requestId)
        .get();
    if (!doc.exists) return;

    final status = doc.data()?['status'];
    if (status == 'pending' || status == 'accepted') {
      await updateRequestStatus(requestId, 'cancelled');
    }
  }

  /// Extra time handling
  Future<void> requestExtraTime(String requestId, int hours) async {
    await _firestore.collection('booking_requests').doc(requestId).update({
      'extraTimeRequest': {
        'hours': hours,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      },
    });

    final doc = await _firestore
        .collection('booking_requests')
        .doc(requestId)
        .get();
    if (doc.exists) {
      final customerId = doc.data()?['customerId'] as String?;
      if (customerId != null) {
        await _createCustomerNotification(
          customerId: customerId,
          title: '⏳ Extra Time Requested',
          message: 'The pro needs $hours more hour to complete the job.',
          type: NotificationType.extraTimeRequested,
          bookingId: requestId,
        );
      }
    }
  }

  Future<void> respondToExtraTime(String requestId, bool approve) async {
    final docRef = _firestore.collection('booking_requests').doc(requestId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final extraTime = data['extraTimeRequest'] as Map<String, dynamic>?;
    if (extraTime == null) return;

    final hours = extraTime['hours'] as int? ?? 1;
    final workerId = data['workerId'] as String;

    if (approve) {
      final currentDuration = data['duration'] as int? ?? 1;
      await docRef.update({
        'duration': currentDuration + hours,
        'extraTimeRequest.status': 'approved',
        'extraTimeRequest.respondedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.update({
        'extraTimeRequest.status': 'declined',
        'extraTimeRequest.respondedAt': FieldValue.serverTimestamp(),
      });
    }

    await _createWorkerNotification(
      workerId: workerId,
      title: approve ? '✅ Extra Time Approved' : '❌ Extra Time Declined',
      message: approve
          ? 'Customer approved $hours more hour(s).'
          : 'Customer declined your extra time request.',
      type: NotificationType.extraTimeResponse,
      bookingId: requestId,
    );
  }

  // ==================== CANCELLATION & DELAY HANDLING ====================

  Future<void> cancelBookingByWorker(
    String requestId, {
    required bool penalized,
  }) async {
    try {
      final docRef = _firestore.collection('booking_requests').doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final workerId = data['workerId'] as String;
      final customerId = data['customerId'] as String;
      final workerName = data['workerName'] as String? ?? 'Provider';

      if (penalized) await _applyCancellationPenalty(workerId);

      await _createCustomerNotification(
        customerId: customerId,
        title: '⚠️ Job Cancelled',
        message:
            '$workerName has cancelled the job. Please book another provider.',
        type: 'worker_cancelled',
        bookingId: requestId,
      );

      await docRef.update({
        'status': 'cancelled',
        'cancelledBy': 'worker',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error in cancelBookingByWorker: $e');
      rethrow;
    }
  }

  Future<void> _applyCancellationPenalty(String workerId) async {
    try {
      final workerRef = _firestore.collection('workers').doc(workerId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(workerRef);
        if (!doc.exists) return;
        final currentRating =
            (doc.data()?['rating'] as num?)?.toDouble() ?? 5.0;
        final newRating = (currentRating * 0.98).clamp(1.0, 5.0);
        transaction.update(workerRef, {
          'rating': newRating,
          'penaltyCount': FieldValue.increment(1),
          'lastPenaltyAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {}
  }

  Future<void> handleBookingExpiredOrRejected({
    required String requestId,
    required String reason,
  }) async {
    await _firestore.collection('booking_requests').doc(requestId).update({
      'status': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== WORKER DELAY REPORTING ====================

  Future<void> reportWorkerDelay(String requestId) async {
    final docRef = _firestore.collection('booking_requests').doc(requestId);
    await docRef.update({
      'delayReported': true,
      'delayReportedAt': FieldValue.serverTimestamp(),
      'delayStatus': 'reported',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    if (doc.exists) {
      final workerId = doc.data()?['workerId'] as String?;
      if (workerId != null) {
        await _createWorkerNotification(
          workerId: workerId,
          title: '⚠️ Customer Waiting',
          message: 'Customer has reported delay. Please update your status.',
          type: 'delay_reported',
          bookingId: requestId,
        );
      }
    }
  }

  Future<void> recordCallToWorker(String requestId) async {
    await _firestore.collection('booking_requests').doc(requestId).update({
      'delayStatus': 'called',
      'callInitiatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> reportWorkerNotReached(String requestId) async {
    try {
      final docRef = _firestore.collection('booking_requests').doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final workerId = doc.data()?['workerId'] as String;
      await docRef.update({
        'delayStatus': 'not_reached',
        'workerNotReachedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _applyDelayPenalty(workerId);
      await _createWorkerNotification(
        workerId: workerId,
        title: '🔴 Marked as Not Reached',
        message: 'Customer reported you as unreachable.',
        type: 'delay_penalty',
        bookingId: requestId,
      );

      await handleBookingExpiredOrRejected(
        requestId: requestId,
        reason: 'worker_delayed',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _applyDelayPenalty(String workerId) async {
    final workerRef = _firestore.collection('workers').doc(workerId);
    await _firestore.runTransaction((transaction) async {
      final workerDoc = await transaction.get(workerRef);
      if (workerDoc.exists) {
        final currentRating =
            (workerDoc.data()?['rating'] as num?)?.toDouble() ?? 5.0;
        final delayCount = (workerDoc.data()?['delayCount'] as int?) ?? 0;
        final newRating = (currentRating - 0.2).clamp(1.0, 5.0);
        transaction.update(workerRef, {
          'rating': newRating,
          'delayCount': delayCount + 1,
          'lastDelayAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  bool shouldShowDelayButton(Map<String, dynamic> booking) {
    if (booking['status'] != 'accepted') return false;
    final startTime = (booking['startTime'] as Timestamp?)?.toDate();
    if (startTime == null) return false;
    return DateTime.now().isAfter(startTime);
  }

  bool shouldShowNotReachedButton(Map<String, dynamic> booking) {
    if (booking['delayStatus'] != 'called') return false;
    final callTime = (booking['callInitiatedAt'] as Timestamp?)?.toDate();
    if (callTime == null) return false;
    return DateTime.now().difference(callTime).inMinutes >= 5;
  }

  Duration getTimeUntilNotReachedButtonShows(Map<String, dynamic> booking) {
    if (booking['delayStatus'] != 'called') return Duration.zero;
    final callTime = (booking['callInitiatedAt'] as Timestamp?)?.toDate();
    if (callTime == null) return Duration.zero;
    final waitDuration = const Duration(minutes: 5);
    final elapsed = DateTime.now().difference(callTime);
    final remaining = waitDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String getDelayStatusLabel(String status) {
    switch (status) {
      case 'reported':
        return 'Step 1: Delay Reported';
      case 'called':
        return 'Step 2: Called Worker';
      case 'not_reached':
        return 'Step 3: Marked Unreached';
      default:
        return 'Report Delay';
    }
  }

  // ==================== NOTIFICATIONS ====================

  Future<void> _createCustomerNotification({
    required String customerId,
    required String title,
    required String message,
    required String type,
    String? bookingId,
    String? imageUrl,
  }) async {
    await _firestore.collection('customer_notifications').add({
      'customerId': customerId,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'type': type,
      'bookingId': bookingId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _notificationService.sendNotificationToUser(
      userId: customerId,
      userType: 'customer',
      title: title,
      body: message,
      imageUrl: imageUrl,
      data: {'type': type, 'bookingId': bookingId},
    );
  }

  Future<void> _createWorkerNotification({
    required String workerId,
    required String title,
    required String message,
    required String type,
    String? bookingId,
    String? imageUrl,
  }) async {
    await _firestore.collection('worker_notifications').add({
      'workerId': workerId,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'type': type,
      'bookingId': bookingId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _notificationService.sendNotificationToUser(
      userId: workerId,
      userType: 'worker',
      title: title,
      body: message,
      imageUrl: imageUrl,
      data: {'type': type, 'bookingId': bookingId},
    );
  }

  Stream<List<Map<String, dynamic>>> streamCustomerNotifications(
    String customerId,
  ) {
    return _firestore
        .collection('customer_notifications')
        .where('customerId', isEqualTo: customerId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Stream<Map<String, dynamic>?> streamLatestBookingNotification(
    String bookingId,
  ) {
    return _firestore
        .collection('customer_notifications')
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isNotEmpty
              ? {'id': snapshot.docs.first.id, ...snapshot.docs.first.data()}
              : null,
        );
  }

  Future<void> markCustomerNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('customer_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Stream<List<Map<String, dynamic>>> streamWorkerNotifications(
    String workerId,
  ) {
    return _firestore
        .collection('worker_notifications')
        .where('workerId', isEqualTo: workerId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('worker_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Stream<int> streamNotificationCount(String userId, [String? userType]) {
    if (userId.isEmpty) return Stream.value(0);

    // If userType is not provided, we have to check both or combine streams
    // For simplicity in a prototype, we return the sum of both or just check customer for now
    // But since ModernHeader is used by both, let's combine.

    final customerStream = _firestore
        .collection('customer_notifications')
        .where('customerId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    // Use both streams if needed, but for now combining manually
    return customerStream.asyncMap((cCount) async {
      final wSnapshot = await _firestore
          .collection('worker_notifications')
          .where('workerId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return cCount + wSnapshot.docs.length;
    });
  }
}
