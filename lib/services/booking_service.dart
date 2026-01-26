import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  }) async {
    final docRef = _firestore.collection('booking_requests').doc();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 1));

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
  Stream<List<Map<String, dynamic>>> streamCustomerBookings(String customerId) {
    return _firestore
        .collection('booking_requests')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
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

  /// Stream pending requests for a worker
  Stream<List<Map<String, dynamic>>> streamWorkerRequests(String workerId) {
    return _firestore
        .collection('booking_requests')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data())
              .where(
                (data) => (data['expiresAt'] as Timestamp).toDate().isAfter(
                  DateTime.now(),
                ),
              )
              .toList(),
        );
  }

  /// Stream active jobs (accepted requests) for a worker
  Stream<List<Map<String, dynamic>>> streamActiveJobs(String workerId) {
    return _firestore
        .collection('booking_requests')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
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
    await _firestore.collection('booking_requests').doc(requestId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'accepted' || status == 'completed') {
      await _firestore.collection('jobs').doc(requestId).set({
        'id': requestId,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
    await _firestore.collection('booking_requests').doc(requestId).update({
      'extraTimeRequest': {
        'hours': extraHours,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      },
    });
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
}
