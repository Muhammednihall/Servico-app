import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Future<List<Map<String, dynamic>>> getWorkerJobs(String uid, {String? status}) async {
    try {
      Query query = _firestore.collection('jobs').where('workerId', isEqualTo: uid);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      final snapshot = await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('❌ Error fetching worker jobs: $e');
      rethrow;
    }
  }

  /// Get worker's transactions
  Future<List<Map<String, dynamic>>> getWorkerTransactions(String uid, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('❌ Error fetching transactions: $e');
      rethrow;
    }
  }

  /// Get worker's ratings
  Future<List<Map<String, dynamic>>> getWorkerRatings(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('❌ Error fetching ratings: $e');
      rethrow;
    }
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

  /// Get today's earnings
  Future<double> getTodaysEarnings(String uid) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: uid)
          .where('type', isEqualTo: 'credit')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThanOrEqualTo: endOfDay)
          .get();
      
      double total = 0;
      for (final doc in snapshot.docs) {
        total += (doc['amount'] as num).toDouble();
      }
      
      return total;
    } catch (e) {
      print('❌ Error fetching today\'s earnings: $e');
      return 0.0;
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

  /// Get workers by category/service type
  Future<List<Map<String, dynamic>>> getWorkersByCategory(String category) async {
    try {
      // Get all workers and filter by serviceType containing the category
      final snapshot = await _firestore.collection('workers').get();
      
      final workers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((worker) {
            final serviceType = worker['serviceType'] as String? ?? '';
            // Check if serviceType contains the category (case-insensitive)
            return serviceType.toLowerCase().contains(category.toLowerCase());
          })
          .toList();
      
      return workers;
    } catch (e) {
      print('❌ Error fetching workers by category: $e');
      rethrow;
    }
  }

  /// Stream worker jobs
  Stream<List<Map<String, dynamic>>> streamWorkerJobs(String uid, {String? status}) {
    Query query = _firestore.collection('jobs').where('workerId', isEqualTo: uid);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }
}
