import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_service.dart';
import 'notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkerService _workerService = WorkerService();
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

  /// Stream all bookings for a customer (with optional limit for pagination)
  Stream<List<Map<String, dynamic>>> streamCustomerBookings(String customerId, {int? limit}) {
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
        .where('status', whereIn: ['pending', 'accepted', 'assigned', 'in_progress'])
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => doc.data())
              .where((data) {
                if (data['status'] == 'pending') {
                  final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
                  return expiresAt == null || expiresAt.isAfter(DateTime.now());
                }
                return true;
              })
              .toList();

          list.sort((a, b) {
            final t1 = (a['startTime'] ?? a['createdAt']) as Timestamp?;
            final t2 = (b['startTime'] ?? b['createdAt']) as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t1.compareTo(t2);
          });

          return list;
        });
  }

  /// Stream the count of urgent notifications (new requests & reminders)
  Stream<int> streamNotificationCount(String workerId) {
    return streamUpcomingSchedule(workerId).map((list) {
      final now = DateTime.now();
      int count = 0;
      for (var job in list) {
        if (job['status'] == 'pending') {
          count++;
        } else if (job['status'] == 'accepted' || job['status'] == 'assigned') {
          final startTime = (job['startTime'] as Timestamp?)?.toDate();
          if (startTime != null) {
            final diff = startTime.difference(now);
            if (diff.inHours >= 0 && diff.inHours <= 12) {
              count++;
            }
          }
        }
      }
      return count;
    });
  }

  /// Simplified stream for dashboard compatibility
  Stream<List<Map<String, dynamic>>> streamWorkerRequests(String workerId) {
    return streamUpcomingSchedule(workerId).map((list) => 
      list.where((job) => job['status'] == 'pending').toList()
    );
  }

  /// Stream active jobs (accepted requests) for a worker
  Stream<List<Map<String, dynamic>>> streamActiveJobs(String workerId) {
    return _firestore
        .collection('booking_requests')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => doc.data()).toList();
          docs.sort((a, b) {
            final t1 = a['startTime'] as Timestamp?;
            final t2 = b['startTime'] as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t1.compareTo(t2); // Ascending: earliest first
          });
          return docs;
        });
  }

  Stream<List<Map<String, dynamic>>> streamCancelledJobs(String workerId) {
    return _firestore
        .collection('booking_requests')
        .where('workerId', isEqualTo: workerId)
        .where('status', whereIn: ['cancelled', 'rejected', 'expired'])
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => doc.data()).toList();
          docs.sort((a, b) {
            final t1 = (a['updatedAt'] ?? a['createdAt']) as Timestamp?;
            final t2 = (b['updatedAt'] ?? b['createdAt']) as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t2.compareTo(t1);
          });
          return docs.take(3).toList();
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
          final docs = snapshot.docs.map((doc) => doc.data()).toList();
          docs.sort((a, b) {
            final t1 = (a['updatedAt'] ?? a['createdAt']) as Timestamp?;
            final t2 = (b['updatedAt'] ?? b['createdAt']) as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t2.compareTo(t1);
          });
          return docs;
        });
  }

  /// Update request status (accepted, rejected, cancelled, expired, completed)
  Future<void> updateRequestStatus(String requestId, String status) async {
    final doc = await _firestore.collection('booking_requests').doc(requestId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final workerId = data['workerId'] as String?;

    final updateData = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'accepted') {
      updateData['acceptedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('booking_requests').doc(requestId).update(updateData);

    // Update worker acceptance stats
    if (workerId != null && (status == 'accepted' || status == 'rejected')) {
      await _updateWorkerAcceptanceStats(workerId, status == 'accepted');
    }

    if (status == 'accepted' || status == 'completed') {
      await _firestore.collection('jobs').doc(requestId).set({
        'id': requestId,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Update worker's internal acceptance statistics
  Future<void> _updateWorkerAcceptanceStats(String workerId, bool accepted) async {
    try {
      final workerRef = _firestore.collection('workers').doc(workerId);
      
      await _firestore.runTransaction((transaction) async {
        final workerDoc = await transaction.get(workerRef);
        
        if (workerDoc.exists) {
          final data = workerDoc.data()!;
          final totalRequests = (data['totalRequests'] as int?) ?? 0;
          final acceptedRequests = (data['acceptedRequests'] as int?) ?? 0;
          
          final newTotal = totalRequests + 1;
          final newAccepted = accepted ? acceptedRequests + 1 : acceptedRequests;
          final acceptanceRate = (newAccepted / newTotal) * 100;
          
          transaction.update(workerRef, {
            'totalRequests': newTotal,
            'acceptedRequests': newAccepted,
            'acceptanceRate': double.parse(acceptanceRate.toStringAsFixed(1)),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      print('✓ Worker acceptance stats updated for: $workerId (Accepted: $accepted)');
    } catch (e) {
      print('❌ Error updating worker acceptance stats: $e');
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String requestId) async {
    await _firestore.collection('booking_requests').doc(requestId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Complete a job
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

      // Credit worker balance
      final workerService = WorkerService();
      await workerService.creditWorkerBalance(workerId, totalAmount, requestId);

      print('✓ Job completed and worker credited: $totalAmount');
    } catch (e) {
      print('❌ Error completing job: $e');
      rethrow;
    }
  }

  /// Worker requests extra time
  Future<void> requestExtraTime(String requestId, int extraHours) async {
    try {
      final docRef = _firestore.collection('booking_requests').doc(requestId);
      await docRef.update({
        'extraTimeRequest': {
          'hours': extraHours,
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
        },
      });

      // Notify customer
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final customerId = data['customerId'] as String?;
        final workerName = data['workerName'] as String? ?? 'Provider';

        if (customerId != null) {
          await _createCustomerNotification(
            customerId: customerId,
            title: '⏳ Extra Time Requested',
            message: '$workerName has requested $extraHours additional hour(s) to complete the job.',
            type: NotificationType.extraTimeRequested,
            bookingId: requestId,
          );
        }
      }
    } catch (e) {
      print('❌ Error requesting extra time: $e');
    }
  }

  /// Customer responds to extra time
  Future<void> respondToExtraTime(String requestId, bool approve) async {
    final doc = await _firestore
        .collection('booking_requests')
        .doc(requestId)
        .get();
    final data = doc.data();
    if (data == null || data['extraTimeRequest'] == null) return;

    if (approve) {
      final additionalHours = data['extraTimeRequest']['hours'] as int;
      final currentDuration = data['duration'] as int;
      await _firestore.collection('booking_requests').doc(requestId).update({
        'duration': currentDuration + additionalHours,
        'extraTimeRequest': {...data['extraTimeRequest'], 'status': 'approved'},
      });
    } else {
      await _firestore.collection('booking_requests').doc(requestId).update({
        'extraTimeRequest': {...data['extraTimeRequest'], 'status': 'rejected'},
      });
    }

    // Notify worker
    final workerId = data['workerId'] as String?;
    if (workerId != null) {
      await _createWorkerNotification(
        workerId: workerId,
        title: approve ? '✅ Extra Time Approved' : '❌ Extra Time Declined',
        message: approve 
            ? 'The customer has approved your request for more time.' 
            : 'The customer has declined your request for more time.',
        type: NotificationType.extraTimeResponse,
        bookingId: requestId,
      );
    }
  }

  /// Submit a review for a worker
  Future<void> submitReview({
    required String requestId,
    required String workerId,
    required String customerId,
    required String customerName,
    required double rating,
    required String review,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Update booking request with rating info
      final requestRef = _firestore
          .collection('booking_requests')
          .doc(requestId);
      batch.update(requestRef, {
        'rating': rating,
        'review': review,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      // 2. Create a rating document
      final ratingRef = _firestore.collection('ratings').doc();
      batch.set(ratingRef, {
        'id': ratingRef.id,
        'requestId': requestId,
        'workerId': workerId,
        'ratedUserId': workerId, // For compatibility
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'review': review,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // 3. Update worker's average rating (using transaction for consistency)
      final workerRef = _firestore.collection('workers').doc(workerId);
      await _firestore.runTransaction((transaction) async {
        final workerDoc = await transaction.get(workerRef);
        if (!workerDoc.exists) return;

        final currentRating =
            (workerDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
        final totalReviews =
            (workerDoc.data()?['totalReviews'] as num?)?.toInt() ?? 0;

        final newTotalReviews = totalReviews + 1;
        // Formula: ((Average * Total) + NewValue) / (Total + 1)
        final newRating =
            ((currentRating * totalReviews) + rating) / newTotalReviews;

        transaction.update(workerRef, {
          'rating': newRating,
          'totalReviews': newTotalReviews,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      print('✓ Review submitted and worker rating updated');
    } catch (e) {
      print('❌ Error submitting review: $e');
      rethrow;
    }
  }

  // ==================== RESCUE JOB SYSTEM ====================

  /// Maximum number of reassignment attempts before giving up
  static const int maxReassignmentAttempts = 3;

  /// Discount tiers for customers based on reassignment count
  static const Map<int, double> customerDiscountTiers = {
    1: 0.10, // 10% discount
    2: 0.15, // 15% discount
    3: 0.20, // 20% discount
  };

  /// Bonus tiers for workers based on rescue level
  static const Map<int, double> workerBonusTiers = {
    1: 0.05, // 5% bonus
    2: 0.07, // 7% bonus
    3: 0.10, // 10% bonus
  };

  /// Find alternate available workers for the same service
  Future<List<Map<String, dynamic>>> findAlternateWorkers({
    required String serviceName,
    required List<String> excludedWorkerIds,
    Map<String, double>? customerCoordinates,
  }) async {
    try {
      // Get workers in the same service category
      final workers = await _workerService.getWorkersByCategory(serviceName);
      
      // Filter out excluded workers and unavailable ones
      final availableWorkers = workers.where((worker) {
        final workerId = worker['id'] as String?;
        if (workerId == null) return false;
        if (excludedWorkerIds.contains(workerId)) return false;
        return worker['isAvailable'] == true;
      }).toList();

      // Sort by rating (highest first)
      availableWorkers.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return ratingB.compareTo(ratingA);
      });

      return availableWorkers;
    } catch (e) {
      print('❌ Error finding alternate workers: $e');
      return [];
    }
  }

  /// Worker cancels the job
  Future<void> cancelBookingByWorker(String requestId, {required bool penalized}) async {
    try {
      final docRef = _firestore.collection('booking_requests').doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final workerId = data['workerId'] as String;
      final customerId = data['customerId'] as String;
      final workerName = data['workerName'] as String? ?? 'Provider';

      // 1. If penalized, apply rating penalty to worker
      if (penalized) {
        await _applyCancellationPenalty(workerId);
      }

      // 2. Notify customer about cancellation
      await _createCustomerNotification(
        customerId: customerId,
        title: '⚠️ Job Cancelled',
        message: '$workerName has cancelled the job. We are matching you with a new pro right now!',
        type: 'worker_cancelled',
        bookingId: requestId,
      );

      // 3. Initiate rescue broadcast
      await broadcastRescueJob(requestId);

      print('✓ Booking $requestId cancelled by worker and rescue broadcast initiated');
    } catch (e) {
      print('❌ Error in cancelBookingByWorker: $e');
      rethrow;
    }
  }

  /// Apply rating penalty for late cancellation
  Future<void> _applyCancellationPenalty(String workerId) async {
    try {
      final workerRef = _firestore.collection('workers').doc(workerId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(workerRef);
        if (!doc.exists) return;

        final currentRating = (doc.data()?['rating'] as num?)?.toDouble() ?? 5.0;
        final totalReviews = (doc.data()?['totalReviews'] as num?)?.toInt() ?? 0;

        // Small penalty: reduce rating slightly
        final newRating = (currentRating * 0.98).clamp(1.0, 5.0);
        
        transaction.update(workerRef, {
          'rating': newRating,
          'penaltyCount': FieldValue.increment(1),
          'lastPenaltyAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('❌ Error applying cancellation penalty: $e');
    }
  }

  /// Broadcast a rescue job to all available workers in the category
  Future<void> broadcastRescueJob(String requestId) async {
    try {
      final docRef = _firestore.collection('booking_requests').doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final int currentReassignmentCount = (data['reassignmentCount'] as int?) ?? 0;
      final int newReassignmentCount = currentReassignmentCount + 1;
      
      // Update booking to broadcast state
      await docRef.update({
        'status': 'pending_rescue',
        'workerId': null,
        'workerName': null,
        'reassignmentCount': newReassignmentCount,
        'isRescueJob': true,
        'rescueLevel': newReassignmentCount > 3 ? 3 : newReassignmentCount,
        'broadcastAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error broadcasting rescue job: $e');
    }
  }

  /// Stream broadcast rescue jobs for a specific service category
  Stream<List<Map<String, dynamic>>> streamRescueBroadcasts(String serviceName) {
    return _firestore
        .collection('booking_requests')
        .where('status', isEqualTo: 'pending_rescue')
        .where('serviceName', isEqualTo: serviceName)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        });
  }

  /// Accept a broadcast rescue job (atomic)
  Future<bool> acceptBroadcastRescueJob({
    required String requestId,
    required String workerId,
    required String workerName,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('booking_requests').doc(requestId);
        final doc = await transaction.get(docRef);

        if (!doc.exists) return false;
        
        final data = doc.data()!;
        if (data['status'] != 'pending_rescue' || data['workerId'] != null) {
          return false; // Already taken
        }

        // Apply bonus to price
        final originalPrice = (data['originalPrice'] as num?)?.toDouble() ?? 
                             (data['price'] as num?)?.toDouble() ?? 0.0;
        final rescueLevel = data['rescueLevel'] as int? ?? 1;
        final bonusPercent = getWorkerBonus(rescueLevel);
        final newPrice = originalPrice * (1 + bonusPercent);

        transaction.update(docRef, {
          'status': 'accepted',
          'workerId': workerId,
          'workerName': workerName,
          'price': newPrice,
          'originalPrice': originalPrice,
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      print('❌ Error accepting broadcast rescue job: $e');
      return false;
    }
  }

  /// Calculate customer discount based on reassignment count
  double getCustomerDiscount(int reassignmentCount) {
    if (reassignmentCount <= 0) return 0.0;
    final tier = reassignmentCount > 3 ? 3 : reassignmentCount;
    return customerDiscountTiers[tier] ?? 0.0;
  }

  /// Calculate worker bonus based on rescue level
  double getWorkerBonus(int rescueLevel) {
    if (rescueLevel <= 0) return 0.0;
    final tier = rescueLevel > 3 ? 3 : rescueLevel;
    return workerBonusTiers[tier] ?? 0.0;
  }

  /// Reassign a booking to a new worker (creates a Rescue Job)
  Future<bool> reassignBooking({
    required String requestId,
    required String newWorkerId,
    required String newWorkerName,
    required String reason,
  }) async {
    try {
      final docRef = _firestore.collection('booking_requests').doc(requestId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        print('❌ Booking not found: $requestId');
        return false;
      }

      final data = doc.data()!;
      final originalPrice = (data['originalPrice'] as num?)?.toDouble() ?? 
                           (data['price'] as num?)?.toDouble() ?? 0.0;
      final currentReassignmentCount = (data['reassignmentCount'] as int?) ?? 0;
      final newReassignmentCount = currentReassignmentCount + 1;
      
      // Store original worker info if this is the first reassignment
      final originalWorkerId = data['originalWorkerId'] ?? data['workerId'];
      final originalWorkerName = data['originalWorkerName'] ?? data['workerName'];
      
      // Get list of excluded workers
      List<String> excludedWorkers = List<String>.from(data['excludedWorkers'] ?? []);
      excludedWorkers.add(data['workerId'] as String);

      // Calculate discount for customer
      final discountPercent = getCustomerDiscount(newReassignmentCount);
      final discountAmount = originalPrice * discountPercent;
      final finalPrice = originalPrice - discountAmount;

      // Calculate bonus for rescue worker
      final bonusPercent = getWorkerBonus(newReassignmentCount);
      final bonusAmount = originalPrice * bonusPercent;
      final workerEarnings = originalPrice + bonusAmount;

      // Reset expiration for new worker
      final now = DateTime.now();
      final newExpiresAt = now.add(const Duration(minutes: 1));

      await docRef.update({
        // Rescue job flags
        'isRescueJob': true,
        'rescueLevel': newReassignmentCount,
        
        // New worker assignment
        'workerId': newWorkerId,
        'workerName': newWorkerName,
        
        // Original worker tracking
        'originalWorkerId': originalWorkerId,
        'originalWorkerName': originalWorkerName,
        
        // Reassignment info
        'reassignmentCount': newReassignmentCount,
        'reassignedAt': FieldValue.serverTimestamp(),
        'reassignmentReason': reason,
        'excludedWorkers': excludedWorkers,
        
        // Pricing with discount
        'originalPrice': originalPrice,
        'discountPercentage': discountPercent,
        'discountAmount': discountAmount,
        'finalPrice': finalPrice,
        'discountReason': 'reassignment_delay',
        
        // Worker bonus
        'rescueBonus': bonusAmount,
        'rescueBonusPercentage': bonusPercent,
        'workerEarnings': workerEarnings,
        
        // Reset status and timer
        'status': 'pending',
        'expiresAt': Timestamp.fromDate(newExpiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✓ Booking reassigned to $newWorkerName (Rescue Level: $newReassignmentCount)');
      print('  Customer discount: ${(discountPercent * 100).toInt()}% (₹${discountAmount.toInt()} off)');
      print('  Worker bonus: ${(bonusPercent * 100).toInt()}% (+₹${bonusAmount.toInt()})');
      
      // Notify customer about the new rescue worker
      await notifyCustomerRescueWorkerAssigned(
        requestId: requestId,
        newWorkerName: newWorkerName,
        discountPercentage: discountPercent,
        discountAmount: discountAmount,
      );
      
      return true;
    } catch (e) {
      print('❌ Error reassigning booking: $e');
      return false;
    }
  }

  /// Handle booking when worker rejects or request expires
  /// Automatically finds alternate worker and creates a Rescue Job
  Future<void> handleBookingExpiredOrRejected({
    required String requestId,
    required String reason, // 'expired' or 'rejected'
  }) async {
    try {
      final docRef = _firestore.collection('booking_requests').doc(requestId);
      final doc = await docRef.get();
      
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final serviceName = data['serviceName'] as String? ?? '';
      final currentReassignmentCount = (data['reassignmentCount'] as int?) ?? 0;
      
      // Check if we've exceeded max reassignment attempts
      if (currentReassignmentCount >= maxReassignmentAttempts) {
        await docRef.update({
          'status': 'failed',
          'failureReason': 'No workers available after $maxReassignmentAttempts attempts',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('❌ Booking failed: No workers available after max attempts');
        return;
      }

      // Get excluded workers list
      List<String> excludedWorkers = List<String>.from(data['excludedWorkers'] ?? []);
      excludedWorkers.add(data['workerId'] as String);

      // Find alternate workers
      final alternateWorkers = await findAlternateWorkers(
        serviceName: serviceName,
        excludedWorkerIds: excludedWorkers,
      );

      if (alternateWorkers.isEmpty) {
        await docRef.update({
          'status': 'failed',
          'failureReason': 'No alternate workers available',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('❌ Booking failed: No alternate workers available');
        return;
      }

      // Assign to the best available worker (first in sorted list)
      final newWorker = alternateWorkers.first;
      final success = await reassignBooking(
        requestId: requestId,
        newWorkerId: newWorker['id'] as String,
        newWorkerName: newWorker['name'] as String? ?? 'Worker',
        reason: reason,
      );

      if (!success) {
        await docRef.update({
          'status': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('❌ Error handling expired/rejected booking: $e');
    }
  }

  /// Update request status with rescue job auto-reassignment
  Future<void> updateRequestStatusWithRescue(String requestId, String status) async {
    await _firestore.collection('booking_requests').doc(requestId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Handle accepted/completed jobs
    if (status == 'accepted' || status == 'completed') {
      await _firestore.collection('jobs').doc(requestId).set({
        'id': requestId,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Auto-reassign when expired or rejected
    if (status == 'expired' || status == 'rejected') {
      await handleBookingExpiredOrRejected(
        requestId: requestId,
        reason: status,
      );
    }
  }

  /// Get rescue job statistics for a worker
  Future<Map<String, dynamic>> getRescueJobStats(String workerId) async {
    try {
      final snapshot = await _firestore
          .collection('booking_requests')
          .where('workerId', isEqualTo: workerId)
          .where('isRescueJob', isEqualTo: true)
          .where('status', isEqualTo: 'completed')
          .get();

      int totalRescueJobs = snapshot.docs.length;
      double totalBonusEarned = 0.0;

      for (var doc in snapshot.docs) {
        final bonus = (doc.data()['rescueBonus'] as num?)?.toDouble() ?? 0.0;
        totalBonusEarned += bonus;
      }

      return {
        'totalRescueJobs': totalRescueJobs,
        'totalBonusEarned': totalBonusEarned,
        'isRescueHero': totalRescueJobs >= 5,
        'isRescueChampion': totalRescueJobs >= 25,
        'isPlatinumRescuer': totalRescueJobs >= 100,
      };
    } catch (e) {
      print('❌ Error getting rescue job stats: $e');
      return {
        'totalRescueJobs': 0,
        'totalBonusEarned': 0.0,
        'isRescueHero': false,
        'isRescueChampion': false,
        'isPlatinumRescuer': false,
      };
    }
  }

  // ==================== WORKER DELAY REPORTING ====================

  /// Report that a worker is delayed (Phase 1 - Customer clicks "Worker Delayed?")
  /// This records the delay report and notifies the worker
  Future<void> reportWorkerDelay(String requestId) async {
    try {
      final docRef = _firestore.collection('booking_requests').doc(requestId);
      
      await docRef.update({
        'delayReported': true,
        'delayReportedAt': FieldValue.serverTimestamp(),
        'delayStatus': 'reported', // reported -> called -> not_reached
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get booking data to notify worker
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final workerId = data['workerId'] as String?;
        
        if (workerId != null) {
          // Create notification for worker
          await _createWorkerNotification(
            workerId: workerId,
            title: '⚠️ Customer Waiting',
            message: 'Customer has reported delay. Please update your status or contact them.',
            type: 'delay_reported',
            bookingId: requestId,
          );
        }
      }

      print('✓ Worker delay reported for booking: $requestId');
    } catch (e) {
      print('❌ Error reporting worker delay: $e');
    }
  }

  /// Record that customer initiated a call to worker (Phase 2)
  Future<void> recordCallToWorker(String requestId) async {
    try {
      await _firestore.collection('booking_requests').doc(requestId).update({
        'delayStatus': 'called',
        'callInitiatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✓ Call to worker recorded for booking: $requestId');
    } catch (e) {
      print('❌ Error recording call: $e');
    }
  }

  /// Report that worker was not reached (Phase 3 - Final action)
  /// This applies rating penalty and triggers rescue job
  Future<bool> reportWorkerNotReached(String requestId) async {
    try {
      final docRef = _firestore.collection('booking_requests').doc(requestId);
      final doc = await docRef.get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final workerId = data['workerId'] as String;
      final workerName = data['workerName'] as String? ?? 'Worker';

      // Update booking status
      await docRef.update({
        'delayStatus': 'not_reached',
        'workerNotReachedAt': FieldValue.serverTimestamp(),
        'originalWorkerMarkedDelayed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Apply rating penalty to worker
      await _applyDelayPenalty(workerId);

      // Notify worker about the penalty
      await _createWorkerNotification(
        workerId: workerId,
        title: '🔴 Marked as Not Reached',
        message: 'Customer reported you as unreachable. This affects your rating. Job is being reassigned.',
        type: 'delay_penalty',
        bookingId: requestId,
      );

      // Trigger rescue job reassignment
      await handleBookingExpiredOrRejected(
        requestId: requestId,
        reason: 'worker_delayed',
      );

      print('✓ Worker marked as not reached: $workerName ($workerId)');
      return true;
    } catch (e) {
      print('❌ Error reporting worker not reached: $e');
      return false;
    }
  }

  /// Apply rating penalty for delay
  Future<void> _applyDelayPenalty(String workerId) async {
    try {
      final workerRef = _firestore.collection('workers').doc(workerId);
      
      await _firestore.runTransaction((transaction) async {
        final workerDoc = await transaction.get(workerRef);
        
        if (workerDoc.exists) {
          final data = workerDoc.data()!;
          final currentRating = (data['rating'] as num?)?.toDouble() ?? 5.0;
          final delayCount = (data['delayCount'] as int?) ?? 0;
          
          // Rating penalty: -0.2 per delay incident (minimum rating 1.0)
          final newRating = (currentRating - 0.2).clamp(1.0, 5.0);
          
          transaction.update(workerRef, {
            'rating': newRating,
            'delayCount': delayCount + 1,
            'lastDelayAt': FieldValue.serverTimestamp(),
          });
        }
      });

      print('✓ Rating penalty applied to worker: $workerId');
    } catch (e) {
      print('❌ Error applying delay penalty: $e');
    }
  }



  /// Check if delay button should be shown (after scheduled time)
  bool shouldShowDelayButton(Map<String, dynamic> booking) {
    if (booking['status'] != 'accepted') return false;
    
    final startTime = (booking['startTime'] as Timestamp?)?.toDate();
    if (startTime == null) return false;
    
    return DateTime.now().isAfter(startTime);
  }

  /// Check if "Worker Not Reached" button should be shown
  /// (3 minutes after call was initiated)
  bool shouldShowNotReachedButton(Map<String, dynamic> booking) {
    final delayStatus = booking['delayStatus'] as String?;
    if (delayStatus != 'called') return false;
    
    final callInitiatedAt = (booking['callInitiatedAt'] as Timestamp?)?.toDate();
    if (callInitiatedAt == null) return false;
    
    final threeMinutesAfterCall = callInitiatedAt.add(const Duration(minutes: 3));
    return DateTime.now().isAfter(threeMinutesAfterCall);
  }

  /// Get time remaining until "Worker Not Reached" button appears
  Duration getTimeUntilNotReachedButtonShows(Map<String, dynamic> booking) {
    final callInitiatedAt = (booking['callInitiatedAt'] as Timestamp?)?.toDate();
    if (callInitiatedAt == null) return Duration.zero;
    
    final threeMinutesAfterCall = callInitiatedAt.add(const Duration(minutes: 3));
    final remaining = threeMinutesAfterCall.difference(DateTime.now());
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Stream worker notifications for real-time updates
  Stream<List<Map<String, dynamic>>> streamWorkerNotifications(String workerId) {
    return _firestore
        .collection('worker_notifications')
        .where('workerId', isEqualTo: workerId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        });
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('worker_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // ==================== WORKER STATUS UPDATES ====================

  /// Update worker status to "On my way"
  /// Sends push notification to customer
  Future<void> updateWorkerStatusOnTheWay({
    required String requestId,
    int? estimatedMinutes,
  }) async {
    try {
      final docRef = _firestore.collection('booking_requests').doc(requestId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final customerId = data['customerId'] as String?;
      final workerName = data['workerName'] as String? ?? 'Worker';
      final serviceName = data['serviceName'] as String? ?? 'Service';

      // Update booking status
      await docRef.update({
        'workerStatus': 'on_the_way',
        'workerDepartedAt': FieldValue.serverTimestamp(),
        'estimatedArrivalMinutes': estimatedMinutes ?? 15,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify customer
      if (customerId != null) {
        final etaMessage = estimatedMinutes != null
            ? ' ETA: $estimatedMinutes minutes.'
            : '';
            
        await _createCustomerNotification(
          customerId: customerId,
          title: '🚗 $workerName is on the way!',
          message: 'Your $serviceName worker has left and is heading to your location.$etaMessage',
          type: NotificationType.workerOnTheWay,
          bookingId: requestId,
        );
      }

      print('✓ Worker status updated to "On my way" for booking: $requestId');
    } catch (e) {
      print('❌ Error updating worker status: $e');
    }
  }

  /// Update worker status to "Arrived"
  /// Sends push notification to customer
  Future<void> updateWorkerStatusArrived(String requestId) async {
    try {
      final docRef = _firestore.collection('booking_requests').doc(requestId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final customerId = data['customerId'] as String?;
      final workerName = data['workerName'] as String? ?? 'Worker';

      // Update booking status
      await docRef.update({
        'workerStatus': 'arrived',
        'workerArrivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify customer
      if (customerId != null) {
        await _createCustomerNotification(
          customerId: customerId,
          title: '📍 $workerName has arrived!',
          message: 'Your worker is at your location. Please let them in.',
          type: NotificationType.workerArrived,
          bookingId: requestId,
        );
      }

      print('✓ Worker status updated to "Arrived" for booking: $requestId');
    } catch (e) {
      print('❌ Error updating worker status: $e');
    }
  }

  /// Update worker status to "Working"
  Future<void> updateWorkerStatusWorking(String requestId) async {
    try {
      await _firestore.collection('booking_requests').doc(requestId).update({
        'workerStatus': 'working',
        'workStartedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✓ Worker status updated to "Working" for booking: $requestId');
    } catch (e) {
      print('❌ Error updating worker status: $e');
    }
  }

  /// Get worker status for a booking
  String getWorkerStatus(Map<String, dynamic> booking) {
    return booking['workerStatus'] as String? ?? 'pending';
  }

  // ==================== CUSTOMER NOTIFICATIONS ====================

  /// Create a notification for a customer
  Future<void> _createCustomerNotification({
    required String customerId,
    required String title,
    required String message,
    required String type,
    String? bookingId,
    String? imageUrl,
  }) async {
    try {
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

      // Also send push notification
      await _notificationService.sendNotificationToUser(
        userId: customerId,
        userType: 'customer',
        title: title,
        body: message,
        imageUrl: imageUrl,
        data: {
          'type': type,
          'bookingId': bookingId,
        },
      );
    } catch (e) {
      print('❌ Error creating customer notification: $e');
    }
  }

  /// Create a notification for a worker
  Future<void> _createWorkerNotification({
    required String workerId,
    required String title,
    required String message,
    required String type,
    String? bookingId,
    String? imageUrl,
  }) async {
    try {
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

      // Also send push notification
      await _notificationService.sendNotificationToUser(
        userId: workerId,
        userType: 'worker',
        title: title,
        body: message,
        imageUrl: imageUrl,
        data: {
          'type': type,
          'bookingId': bookingId,
        },
      );
    } catch (e) {
      print('❌ Error creating worker notification: $e');
    }
  }

  /// Notify customer when a rescue worker is assigned
  Future<void> notifyCustomerRescueWorkerAssigned({
    required String requestId,
    required String newWorkerName,
    required double discountPercentage,
    required double discountAmount,
  }) async {
    try {
      final doc = await _firestore.collection('booking_requests').doc(requestId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final customerId = data['customerId'] as String?;
      final serviceName = data['serviceName'] as String? ?? 'Service';

      if (customerId != null) {
        final discountText = discountPercentage > 0
            ? ' You\'ll receive a ${(discountPercentage * 100).toInt()}% discount (₹${discountAmount.toInt()} off)!'
            : '';

        await _createCustomerNotification(
          customerId: customerId,
          title: '🦸 New Worker Assigned!',
          message: 'Good news! $newWorkerName has been assigned to your $serviceName.$discountText',
          type: NotificationType.rescueWorkerAssigned,
          bookingId: requestId,
        );
      }

      print('✓ Customer notified of rescue worker assignment');
    } catch (e) {
      print('❌ Error notifying customer: $e');
    }
  }

  /// Stream customer notifications for real-time updates
  Stream<List<Map<String, dynamic>>> streamCustomerNotifications(String customerId) {
    return _firestore
        .collection('customer_notifications')
        .where('customerId', isEqualTo: customerId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        });
  }

  /// Stream the latest notification for a specific booking
  Stream<Map<String, dynamic>?> streamLatestBookingNotification(String bookingId) {
    return _firestore
        .collection('customer_notifications')
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty 
            ? {'id': snapshot.docs.first.id, ...snapshot.docs.first.data()} 
            : null);
  }

  /// Mark a customer notification as read
  Future<void> markCustomerNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('customer_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}

