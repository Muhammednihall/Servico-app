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
          {'lat': 11.2588, 'lng': 75.7804}, // Targeted to Kozhikode instead of NYC mock
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

  /// Stream incoming requests for a worker (direct Always + broadcast rescue if category matches)
  Stream<List<Map<String, dynamic>>> streamWorkerRequests(String workerId, {String? workerCategory}) {
    return _firestore
        .collection('booking_requests')
        .where('status', whereIn: ['pending', 'reassigning'])
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .where((req) {
                // Direct request - ALWAYS show to the assigned worker
                if (req['workerId'] == workerId && req['status'] == 'pending') return true;
                
                // Broadcast rescue job (anyone in category except previous worker)
                if (workerCategory != null &&
                    req['status'] == 'reassigning' && 
                    req['serviceName'] == workerCategory && 
                    req['previousWorkerId'] != workerId) {
                  final rejectedBy = req['rejectedBy'] as List<dynamic>? ?? [];
                  if (!rejectedBy.contains(workerId)) return true;
                }
                
                return false;
              })
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

  /// Accept a booking request (handles both direct and broadcast)
  Future<void> acceptBooking(String requestId, String workerId, String workerName) async {
    final docRef = _firestore.collection('booking_requests').doc(requestId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Request not found');
      
      final data = snapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'];
      
      if (currentStatus != 'pending' && currentStatus != 'reassigning') {
        throw Exception('Job already taken or no longer available');
      }

      transaction.update(docRef, {
        'status': 'accepted',
        'workerId': workerId,
        'workerName': workerName,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final jobRef = _firestore.collection('jobs').doc(requestId);
      transaction.set(jobRef, {
        ...data,
        'status': 'accepted',
        'workerId': workerId,
        'workerName': workerName,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    // Notify customer about new worker if it was a rescue job
    final finalDoc = await docRef.get();
    if (finalDoc.exists && finalDoc.data()?['isRescueJob'] == true) {
      final customerId = finalDoc.data()?['customerId'];
      if (customerId != null) {
        await _createCustomerNotification(
          customerId: customerId,
          title: '✅ Rescue Worker Found!',
          message: '$workerName has accepted your request and is now on the way!',
          type: 'rescue_worker_accepted',
          bookingId: requestId,
        );
      }
    }
  }

  /// Update request status (general)
  Future<void> updateRequestStatus(String requestId, String status) async {
    await _firestore.collection('booking_requests').doc(requestId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// Formally reject a booking request (handles both direct and broadcast appropriately)
  Future<void> rejectBooking(String requestId, String workerId) async {
    final docRef = _firestore.collection('booking_requests').doc(requestId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'];
      
      if (currentStatus == 'reassigning') {
        // Just record that this worker rejected the broadcast
        List<dynamic> rejectedBy = data['rejectedBy'] ?? [];
        if (!rejectedBy.contains(workerId)) {
          rejectedBy.add(workerId);
        }
        transaction.update(docRef, {
          'rejectedBy': rejectedBy,
        });
      } else if (currentStatus == 'pending') {
        // Direct booking rejected
        transaction.update(docRef, {
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
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
      final rescueBonus = (data['rescueBonus'] as num?)?.toDouble() ?? 0.0;
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      final duration = (data['duration'] as int?) ?? 1;
      final totalAmount = (price * duration) + rescueBonus;

      final customerPayment = price * duration;

      await updateRequestStatus(requestId, 'completed');

      final workerService = WorkerService();
      await workerService.creditWorkerBalance(workerId, totalAmount, requestId);

      // Create Service Record (Receipt)
      await _firestore.collection('service_records').add({
        'bookingId': requestId,
        'workerId': workerId,
        'workerName': data['workerName'],
        'customerId': data['customerId'],
        'customerName': data['customerName'],
        'serviceName': data['serviceName'],
        'finalAmount': totalAmount, // For legacy compatibility
        'workerEarnings': totalAmount,
        'customerPayment': customerPayment,
        'duration': duration,
        'completedAt': FieldValue.serverTimestamp(),
        'isReassigned': data['isReassigned'] ?? false,
        'isRescueJob': data['isRescueJob'] ?? false,
        'rescueBonus': data['rescueBonus'] ?? 0.0,
        'originalPrice': data['originalPrice'] ?? price,
      });

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
        final rawNewRating =
            ((currentRating * totalReviews) + rating) / newTotalReviews;
        final newRating = rawNewRating.clamp(1.0, 5.0);

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
    if (hours > 2) {
      throw Exception('Cannot request more than 2 extra hours per job');
    }

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

      // Tell customer about cancellation, but let them know a new worker is being found
      await _createCustomerNotification(
        customerId: customerId,
        title: '⚠️ Worker Update',
        message:
            '$workerName was unable to make it. Don\'t worry, we are assigning a new expert now and have applied a 20% discount!',
        type: 'worker_cancelled_reassigning',
        bookingId: requestId,
      );

      // Put job back into pool for anyone in the category exception this worker
      await docRef.update({
        'status': 'reassigning',
        'isReassigned': true,
        'previousWorkerId': workerId,
        'previousWorkerName': workerName,
        'workerId': null, // Open to anyone
        'workerName': null,
        'workerStatus': null,
        'estimatedArrivalMinutes': null,
        'isRescueJob': true,
        'rescueBonus': 150.0,
        'originalPrice': data['originalPrice'] ?? (data['price'] ?? 0.0),
        'price': (data['originalPrice'] ?? (data['price'] ?? 0.0)) * 0.8, // 20% discount
        'cancelledBy': 'worker',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // autoReassignWorker is no longer needed to create a new doc, 
      // as the original doc is now effectively the broadcast request.

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
        final rawRating = (doc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
        final totalReviews = (doc.data()?['totalReviews'] as num?)?.toInt() ?? 0;
        final currentRating = (rawRating == 0.0 && totalReviews == 0) ? 5.0 : rawRating;
        final newRating = (currentRating * 0.98).clamp(1.0, 5.0);
        final penaltyCount = (doc.data()?['penaltyCount'] as int?) ?? 0;
        final newPenaltyCount = penaltyCount + 1;
        
        final updates = <String, dynamic>{
          'rating': newRating,
          'penaltyCount': newPenaltyCount,
          'lastPenaltyAt': FieldValue.serverTimestamp(),
        };

        // Temporary hard suspension after 3 cancellations
        if (newPenaltyCount >= 3) {
          updates['isAvailable'] = false;
          updates['accountStatus'] = 'suspended';
        }

        transaction.update(workerRef, updates);
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
      // Mark original booking for reassignment
      await docRef.update({
        'status': 'reassigning',
        'isReassigned': true,
        'previousWorkerId': workerId,
        'workerId': null,
        'workerName': null,
        'workerStatus': null,
        'estimatedArrivalMinutes': null,
        'delayStatus': 'not_reached',
        'isRescueJob': true,
        'rescueBonus': 150.0,
        'originalPrice': (doc.data()?['price'] as num?)?.toDouble() ?? 0.0,
        'price': ((doc.data()?['price'] as num?)?.toDouble() ?? 0.0) * 0.8,
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

      final customerId = doc.data()?['customerId'];
      if (customerId != null) {
        await _createCustomerNotification(
          customerId: customerId,
          title: '🔄 Finding New Worker',
          message: 'Since the worker was unreachable, we are assigning a new expert for you. A 20% discount has been applied!',
          type: 'worker_unreachable_reassigning',
          bookingId: requestId,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Auto-assign alternate worker for delays
  Future<void> autoReassignWorker(String oldRequestId) async {
    try {
      final oldDoc =
          await _firestore.collection('booking_requests').doc(oldRequestId).get();
      if (!oldDoc.exists) return;

      final oldData = oldDoc.data()!;
      final category = oldData['serviceName'] as String;
      final originalPrice = (oldData['price'] as num).toDouble();
      final customerId = oldData['customerId'] as String;
      final oldWorkerId = oldData['workerId'] as String;

      // Find available workers in same category
      final workerService = WorkerService();
      final allWorkers = await workerService.getWorkersByCategory(category);

      // Filter out original worker and those already on a job
      final availableWorkers = allWorkers.where((w) => w['id'] != oldWorkerId).toList();

      if (availableWorkers.isEmpty) {
        await _createCustomerNotification(
          customerId: customerId,
          title: '⚠️ No alternate workers',
          message:
              'We couldn\'t find an alternate worker right now. Please try again later.',
          type: 'no_alternate_worker',
          bookingId: oldRequestId,
        );
        return;
      }

      // Sort by rating or distance (mocked for now, just picking first rated)
      availableWorkers.sort((a, b) {
        final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return rB.compareTo(rA);
      });

      final newWorker = availableWorkers.first;

      // Calculate reduced charge (20% discount)
      final reducedPrice = originalPrice * 0.8;

      // Create new booking request
      final newRequestId = await createBookingRequest(
        workerId: newWorker['id'],
        workerName: newWorker['name'] ?? 'Provider',
        serviceName: category,
        price: reducedPrice,
        duration: oldData['duration'] ?? 1,
        customerId: customerId,
        customerName: oldData['customerName'],
        customerAddress: oldData['customerAddress'],
        customerCoordinates:
            Map<String, double>.from(oldData['customerCoordinates'] ?? {}),
      );

      // Mark as reassigned with original info and Rescue Job bonus
      await _firestore.collection('booking_requests').doc(newRequestId).update({
        'isReassigned': true,
        'isRescueJob': true,
        'rescueBonus': 150.0, // Bonus for picking up a cancelled/delayed job
        'originalRequestId': oldRequestId,
        'originalPrice': originalPrice,
        'discountPercentage': 20,
      });

      // Notify Customer
      await _createCustomerNotification(
        customerId: customerId,
        title: '🔄 New Worker Assigned!',
        message:
            'Due to delay, ${newWorker['name']} has been assigned. You received a 20% discount!',
        type: 'worker_reassigned',
        bookingId: newRequestId,
      );
    } catch (e) {
      print('❌ Error in autoReassignWorker: $e');
    }
  }

  Future<void> _applyDelayPenalty(String workerId) async {
    final workerRef = _firestore.collection('workers').doc(workerId);
    await _firestore.runTransaction((transaction) async {
      final workerDoc = await transaction.get(workerRef);
      if (workerDoc.exists) {
        final rawRating = (workerDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
        final totalReviews = (workerDoc.data()?['totalReviews'] as num?)?.toInt() ?? 0;
        final currentRating = (rawRating == 0.0 && totalReviews == 0) ? 5.0 : rawRating;
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
    // Always write to Firestore first — this is what drives the in-app popup stream
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

    // FCM push is best-effort — don't let a failed token block the in-app notification
    try {
      await _notificationService.sendNotificationToUser(
        userId: customerId,
        userType: 'customer',
        title: title,
        body: message,
        imageUrl: imageUrl,
        data: {'type': type, 'bookingId': bookingId},
      );
    } catch (e) {
      print('⚠️ FCM push failed (in-app notification still sent): $e');
    }
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

  Future<int> getCompletedJobsCount(String workerId) async {
    try {
      final snapshot = await _firestore
          .collection('booking_requests')
          .where('workerId', isEqualTo: workerId)
          .where('status', isEqualTo: 'completed')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Stream<List<Map<String, dynamic>>> streamServiceRecords(
    String userId, {
    required String userRole,
  }) {
    final collection = _firestore.collection('service_records');
    final queryField = userRole == 'customer' ? 'customerId' : 'workerId';

    return collection
        .where(queryField, isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
