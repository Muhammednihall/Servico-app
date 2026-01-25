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

  /// Stream pending requests for a worker
  Stream<List<Map<String, dynamic>>> streamWorkerRequests(String workerId) {
    return _firestore
        .collection('booking_requests')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .where((data) => (data['expiresAt'] as Timestamp).toDate().isAfter(DateTime.now()))
            .toList());
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

  /// Update request status (accepted, rejected, cancelled, expired, completed)
  Future<void> updateRequestStatus(String requestId, String status) async {
    await _firestore.collection('booking_requests').doc(requestId).update({
      'status': status,
    });

    if (status == 'accepted' || status == 'completed') {
       // Optionally sync with a general 'jobs' collection
       await _firestore.collection('jobs').doc(requestId).set({
         'id': requestId,
         'status': status,
         'updatedAt': FieldValue.serverTimestamp(),
       }, SetOptions(merge: true));
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String requestId) async {
    await updateRequestStatus(requestId, 'cancelled');
  }

  /// Complete a job
  Future<void> completeJob(String requestId) async {
    try {
      final doc = await _firestore.collection('booking_requests').doc(requestId).get();
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
      }
    });
  }

  /// Customer responds to extra time
  Future<void> respondToExtraTime(String requestId, bool approve) async {
    final doc = await _firestore.collection('booking_requests').doc(requestId).get();
    final data = doc.data();
    if (data == null || data['extraTimeRequest'] == null) return;

    if (approve) {
      final additionalHours = data['extraTimeRequest']['hours'] as int;
      final currentDuration = data['duration'] as int;
      await _firestore.collection('booking_requests').doc(requestId).update({
        'duration': currentDuration + additionalHours,
        'extraTimeRequest': {
          ...data['extraTimeRequest'],
          'status': 'approved',
        }
      });
    } else {
      await _firestore.collection('booking_requests').doc(requestId).update({
        'extraTimeRequest': {
          ...data['extraTimeRequest'],
          'status': 'rejected',
        }
      });
    }
  }
}
