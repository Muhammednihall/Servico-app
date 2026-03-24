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

  /// Get today's earnings by streaming transactions from today
  Stream<double> streamTodaysEarnings(String uid) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: 'credit')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snapshot) {
          double total = 0;
          for (var doc in snapshot.docs) {
            total += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
          }
          return total;
        });
  }

  /// Get today's earnings with local persistence (fallback)
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
      final snapshot = await _firestore.collection('workers').get();

      // Build a list of keywords to match for this category
      final searchKeywords = _getCategoryKeywords(category.toLowerCase());

      final workers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((worker) {
            // Split serviceType into individual words for accurate matching
            final serviceType = (worker['serviceType'] as String? ?? '').toLowerCase();
            final serviceWords = serviceType
                .replaceAll(',', ' ')
                .split(RegExp(r'\s+'))
                .where((w) => w.isNotEmpty)
                .toList();

            final isAvailable = worker['isAvailable'] as bool? ?? false;

            // Check if any keyword matches any word in serviceType (word-level, not substring)
            final matches = searchKeywords.any((kw) {
              // First try exact word match
              if (serviceWords.contains(kw)) return true;
              // Then try if the serviceType as a whole contains the keyword as a proper word
              return serviceType.contains(kw) &&
                  (serviceType == kw ||
                      serviceType.startsWith('$kw ') ||
                      serviceType.endsWith(' $kw') ||
                      serviceType.contains(' $kw ') ||
                      serviceType.contains('$kw,') ||
                      serviceType.contains(',$kw'));
            });
            return matches && isAvailable;
          })
          .toList();

      return workers;
    } catch (e) {
      print('❌ Error fetching workers by category: $e');
      rethrow;
    }
  }

  /// Returns a list of keywords to match serviceType for a given category
  List<String> _getCategoryKeywords(String category) {
    if (category.contains('automotive') || category.contains('car wash') ||
        category.contains('mechanic')) {
      return ['automotive', 'car', 'mechanic', 'washing', 'vehicle'];
    }
    if (category.contains('electric')) {
      return ['electric'];
    }
    if (category.contains('plumb') || category.contains('water')) {
      return ['plumb', 'water'];
    }
    if (category.contains('clean')) {
      return ['clean'];
    }
    if (category.contains('garden')) {
      return ['garden', 'gardener'];
    }
    if (category.contains('paint')) {
      return ['paint', 'painter'];
    }
    if (category.contains('pest')) {
      return ['pest', 'exterminator'];
    }
    if (category.contains('laundry')) {
      return ['laundry'];
    }
    if (category.contains('wifi') || category.contains('it support')) {
      return ['wifi', 'it support', 'internet', 'network'];
    }
    if (category.contains('appliance')) {
      return ['appliance'];
    }
    if (category.contains('furniture')) {
      return ['furniture', 'carpenter'];
    }
    if (category.contains('ac') || category.contains('hvac')) {
      return ['ac', 'hvac', 'air con', 'cooling'];
    }
    if (category.contains('security') || category.contains('lock')) {
      return ['security', 'lock', 'cctv'];
    }
    // fallback: search by first word of the category
    final firstWord = category.split(' ').first;
    return [firstWord];
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

      final double platformCommission = amount * 0.10;
      final double workerEarnings = amount - platformCommission;

      // Fetch worker and job details to enhance transaction description
      final requestDoc = await _firestore.collection('booking_requests').doc(requestId).get();
      final requestData = requestDoc.data();
      final String placeName = requestData?['customerAddress'] ?? 'Unspecified Location';

      await _firestore.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          // Create a wallet if it doesn't exist
          transaction.set(walletRef, {
            'userId': workerId,
            'userType': 'worker',
            'balance': workerEarnings,
            'totalEarned': workerEarnings,
            'totalSpent': 0.0,
            'currency': 'INR',
            'payoutMethod': 'bank_transfer',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final currentBalance = walletDoc.data()?['balance'] as num? ?? 0.0;
          final totalEarned = walletDoc.data()?['totalEarned'] as num? ?? 0.0;

          transaction.update(walletRef, {
            'balance': currentBalance + workerEarnings,
            'totalEarned': totalEarned + workerEarnings,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Add a transaction record for the worker
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'id': transactionRef.id,
          'userId': workerId,
          'type': 'credit',
          'amount': workerEarnings,
          'description': 'Earnings for job at $placeName (Net)',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'completed',
        });

        // Add a platform earnings record
        final platformRef = _firestore.collection('platform_earnings').doc();
        transaction.set(platformRef, {
          'id': platformRef.id,
          'jobId': requestId,
          'workerId': workerId,
          'totalAmount': amount,
          'commissionAmount': platformCommission,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // Update local storage for instant dashboard reflection
      await _addEarningsLocally(workerId, workerEarnings);
      
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
