import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Get worker profile data
  Future<Map<String, dynamic>?> getWorkerProfile(String uid) async {
    try {
      final doc = await _firestore.collection('workers').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error fetching worker profile: $e');
      rethrow;
    }
  }

  /// Get worker wallet data
  Future<Map<String, dynamic>?> getWorkerWallet(String uid) async {
    try {
      final doc = await _firestore.collection('wallets').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error fetching wallet: $e');
      rethrow;
    }
  }

  /// Get worker's jobs
  Future<List<Map<String, dynamic>>> getWorkerJobs(
    String uid, {
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection('jobs')
          .where('workerId', isEqualTo: uid);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error fetching worker jobs: $e');
      rethrow;
    }
  }

  /// Get worker's transactions
  Future<List<Map<String, dynamic>>> getWorkerTransactions(
    String uid, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error fetching transactions: $e');
      rethrow;
    }
  }

  /// Stream worker's transactions
  Stream<List<Map<String, dynamic>>> streamWorkerTransactions(
    String uid, {
    int limit = 10,
  }) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList(),
        );
  }

  /// Get worker's ratings
  Future<List<Map<String, dynamic>>> getWorkerRatings(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error fetching ratings: $e');
      rethrow;
    }
  }

  /// Stream worker's ratings
  Stream<List<Map<String, dynamic>>> streamWorkerRatings(String uid) {
    return _firestore
        .collection('ratings')
        .where('ratedUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList(),
        );
  }

  /// Get current jobs count
  Future<int> getCurrentJobsCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('workerId', isEqualTo: uid)
          .where('status', whereIn: ['pending', 'assigned', 'in_progress'])
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error fetching current jobs count: $e');
      return 0;
    }
  }

  /// Get today's earnings with local persistence and daily reset
  Future<double> getTodaysEarnings(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final dateKey = 'earnings_date_${uid}';
      final amountKey = 'today_earnings_${uid}';
      
      final savedDate = prefs.getString(dateKey);
      final todayStr = "${today.year}-${today.month}-${today.day}";

      // Reset if it's a new day
      if (savedDate != todayStr) {
        await prefs.setString(dateKey, todayStr);
        await prefs.setDouble(amountKey, 0.0);
        return 0.0;
      }

      return prefs.getDouble(amountKey) ?? 0.0;
    } catch (e) {
      print('❌ Error fetching today\'s earnings: $e');
      return 0.0;
    }
  }

  /// Internal helper to add earnings to local storage
  Future<void> _addEarningsLocally(String uid, double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final dateKey = 'earnings_date_${uid}';
      final amountKey = 'today_earnings_${uid}';
      
      final todayStr = "${today.year}-${today.month}-${today.day}";
      final savedDate = prefs.getString(dateKey);

      double currentAmount = 0.0;
      if (savedDate == todayStr) {
        currentAmount = prefs.getDouble(amountKey) ?? 0.0;
      }

      await prefs.setString(dateKey, todayStr);
      await prefs.setDouble(amountKey, currentAmount + amount);
      print('✓ Local earnings updated: ${currentAmount + amount}');
    } catch (e) {
      print('❌ Error updating local earnings: $e');
    }
  }

  /// Calculate average rating
  Future<double> getAverageRating(String uid) async {
    try {
      final ratings = await getWorkerRatings(uid);

      if (ratings.isEmpty) {
        return 0.0;
      }

      double total = 0;
      for (final rating in ratings) {
        total += (rating['rating'] as num).toDouble();
      }

      return total / ratings.length;
    } catch (e) {
      print('❌ Error calculating average rating: $e');
      return 0.0;
    }
  }

  /// Stream worker profile
  Stream<Map<String, dynamic>?> streamWorkerProfile(String uid) {
    return _firestore.collection('workers').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  /// Stream worker wallet
  Stream<Map<String, dynamic>?> streamWorkerWallet(String uid) {
    return _firestore.collection('wallets').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  /// Get workers by category
  Future<List<Map<String, dynamic>>> getWorkersByCategory(
    String category,
  ) async {
    try {
      // Fetch all workers and filter client-side to avoid index requirements and handle slight name mismatches
      final snapshot = await _firestore.collection('workers').get();

      final workers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((worker) {
            final serviceType = (worker['serviceType'] as String? ?? '')
                .toLowerCase();
            final searchCat = category.toLowerCase();
            final isAvailable = worker['isAvailable'] as bool? ?? false;

            return (serviceType == searchCat ||
                    serviceType.contains(searchCat)) &&
                isAvailable;
          })
          .toList();

      return workers;
    } catch (e) {
      print('❌ Error fetching workers by category: $e');
      rethrow;
    }
  }

  /// Stream worker jobs
  Stream<List<Map<String, dynamic>>> streamWorkerJobs(
    String uid, {
    String? status,
  }) {
    Query query = _firestore
        .collection('jobs')
        .where('workerId', isEqualTo: uid);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      },
    );
  }

  /// Credit worker balance after job completion
  Future<void> creditWorkerBalance(
    String workerId,
    double amount,
    String requestId,
  ) async {
    try {
      final walletRef = _firestore.collection('wallets').doc(workerId);

      await _firestore.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          throw 'Wallet not found for worker: $workerId';
        }

        final currentBalance = walletDoc.data()?['balance'] as num? ?? 0.0;
        final totalEarned = walletDoc.data()?['totalEarned'] as num? ?? 0.0;

        transaction.update(walletRef, {
          'balance': currentBalance + amount,
          'totalEarned': totalEarned + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Add a transaction record
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'id': transactionRef.id,
          'userId': workerId,
          'type': 'credit',
          'amount': amount,
          'description': 'Earnings for job #$requestId',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'completed',
        });
      });

      // Update local storage for instant dashboard reflection
      await _addEarningsLocally(workerId, amount);
      
      print('✓ Worker balance credited successfully');
    } catch (e) {
      print('❌ Error crediting worker balance: $e');
      rethrow;
    }
  }

  /// Update worker availability status
  Future<void> updateAvailability(String uid, bool isAvailable) async {
    try {
      await _firestore.collection('workers').doc(uid).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✓ Availability updated to: $isAvailable');
    } catch (e) {
      print('❌ Error updating availability: $e');
      rethrow;
    }
  }

  /// Check if worker is currently busy with a job
  Future<Map<String, dynamic>?> getWorkerCurrentBooking(String workerId) async {
    try {
      // Check for active bookings (accepted status)
      final activeBookings = await _firestore
          .collection('booking_requests')
          .where('workerId', isEqualTo: workerId)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();

      if (activeBookings.docs.isNotEmpty) {
        return activeBookings.docs.first.data();
      }
      return null;
    } catch (e) {
      print('❌ Error checking worker availability: $e');
      return null;
    }
  }

  /// Get count of token bookings in queue for a worker
  Future<int> getTokenQueueCount(String workerId) async {
    try {
      final tokenBookings = await _firestore
          .collection('booking_requests')
          .where('workerId', isEqualTo: workerId)
          .where('isTokenBooking', isEqualTo: true)
          .where('status', isEqualTo: 'pending')
          .get();
      return tokenBookings.docs.length;
    } catch (e) {
      print('❌ Error getting token queue: $e');
      return 0;
    }
  }

  /// Update worker busy status with current booking details
  Future<void> setWorkerBusy(String workerId, String bookingId, DateTime endTime) async {
    try {
      await _firestore.collection('workers').doc(workerId).update({
        'isAvailable': false,
        'currentBookingId': bookingId,
        'currentBookingEndTime': Timestamp.fromDate(endTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✓ Worker marked as busy');
    } catch (e) {
      print('❌ Error setting worker busy: $e');
    }
  }

  /// Clear worker busy status when job is complete
  Future<void> setWorkerFree(String workerId) async {
    try {
      await _firestore.collection('workers').doc(workerId).update({
        'isAvailable': true,
        'currentBookingId': null,
        'currentBookingEndTime': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✓ Worker marked as free');
    } catch (e) {
      print('❌ Error setting worker free: $e');
    }
  }

  /// Get estimated start time for a new token booking
  Future<DateTime> getEstimatedStartTime(String workerId, int newBookingDuration) async {
    try {
      // Get current booking end time
      final currentBooking = await getWorkerCurrentBooking(workerId);
      DateTime estimatedStart = DateTime.now();

      if (currentBooking != null && currentBooking['startTime'] != null) {
        final startTime = (currentBooking['startTime'] as Timestamp).toDate();
        final duration = currentBooking['duration'] ?? 1;
        estimatedStart = startTime.add(Duration(hours: duration));
      }

      // Add time for all pending token bookings
      final pendingTokens = await _firestore
          .collection('booking_requests')
          .where('workerId', isEqualTo: workerId)
          .where('isTokenBooking', isEqualTo: true)
          .where('status', isEqualTo: 'pending')
          .orderBy('tokenPosition')
          .get();

      for (var doc in pendingTokens.docs) {
        final tokenDuration = doc.data()['duration'] ?? 1;
        estimatedStart = estimatedStart.add(Duration(hours: tokenDuration));
      }

      return estimatedStart;
    } catch (e) {
      print('❌ Error calculating estimated start: $e');
      return DateTime.now().add(const Duration(hours: 2));
    }
  }
}
