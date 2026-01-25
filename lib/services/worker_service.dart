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

  Future<List<Map<String, dynamic>>> getWorkersByCategory(String category) async {
    try {
      // Fetch all workers and filter client-side to avoid index requirements and handle slight name mismatches
      final snapshot = await _firestore.collection('workers').get();
      
      final workers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((worker) {
            final serviceType = (worker['serviceType'] as String? ?? '').toLowerCase();
            final searchCat = category.toLowerCase();
            final isAvailable = worker['isAvailable'] as bool? ?? false;
            
            return (serviceType == searchCat || serviceType.contains(searchCat)) && isAvailable;
          })
          .toList();
      
      return workers;
    } catch (e) {
      print('❌ Error fetching workers by category: $e');
      rethrow;
    }
  }

  /// Initialize sample workers for each category and subcategory
  Future<void> initializeSampleWorkers() async {
    try {
      print('⏳ Initializing sample workers...');
      
      // Get all categories to know what subcategories exist
      final categoriesSnapshot = await _firestore.collection('categories').get();
      
      if (categoriesSnapshot.docs.isEmpty) {
        print('⚠️ No categories found to populate workers for.');
        return;
      }

      final List<String> names = ['John', 'David', 'Michael', 'Robert', 'William', 'James', 'Alex', 'Emma', 'Sophia', 'Olivia', 'Lucas', 'Mia', 'Ethan', 'Isabella'];
      final List<String> lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson'];
      
      int totalCreated = 0;
      int globalIndex = 0;

      for (var catDoc in categoriesSnapshot.docs) {
        final catData = catDoc.data();
        final String categoryName = catData['name'] ?? 'General';
        final List<dynamic> subcategories = catData['subcategories'] ?? [];

        for (var sub in subcategories) {
          final String subName = sub['name'] ?? 'General Service';
          
          // Create 2-3 workers for each subcategory
          int count = 2; 
          for (int i = 0; i < count; i++) {
            final String firstName = names[globalIndex % names.length];
            final String lastName = lastNames[globalIndex % lastNames.length];
            final String fullName = '$firstName $lastName';
            final String workerId = 'worker_${globalIndex}_${DateTime.now().millisecondsSinceEpoch}';

            await _firestore.collection('workers').doc(workerId).set({
              'name': fullName,
              'email': '${firstName.toLowerCase()}.${lastName.toLowerCase()}${globalIndex}@servico.com',
              'phone': '+1 555-0${100 + globalIndex}',
              'serviceType': categoryName,
              'subcategory': subName,
              'rating': 4.0 + (globalIndex % 10) / 10.0,
              'totalReviews': 10 + (globalIndex * 3) % 40,
              'isAvailable': true,
              'experience': '${(globalIndex % 5) + 3} years',
              'bio': 'Certified $subName expert with professional experience in $categoryName projects.',
              'hourlyRate': 25.0 + (globalIndex % 50),
              'completedJobs': 20 + (globalIndex % 100),
              'images': ['https://i.pravatar.cc/300?u=$workerId'],
              'profileImage': 'https://i.pravatar.cc/150?u=$workerId',
              'location': 'New York, NY',
              'joinedAt': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });

            // Create a wallet for the worker
            await _firestore.collection('wallets').doc(workerId).set({
              'userId': workerId,
              'balance': 150.0 + (globalIndex * 10),
              'totalEarned': 1200.0 + (globalIndex * 50),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            globalIndex++;
            totalCreated++;
          }
        }
      }
      print('✓ $totalCreated sample workers initialized successfully');
    } catch (e) {
      print('❌ Error initializing sample workers: $e');
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

  /// Credit worker balance after job completion
  Future<void> creditWorkerBalance(String workerId, double amount, String requestId) async {
    try {
      final walletRef = _firestore.collection('wallets').doc(workerId);
      
      await _firestore.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);
        
        if (!walletDoc.exists) {
          throw 'Wallet not found for worker: $workerId';
        }

        final currentBalance = (walletDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        final totalEarned = (walletDoc.data()?['totalEarned'] as num?)?.toDouble() ?? 0.0;

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
      print('✓ Worker balance credited successfully');
    } catch (e) {
      print('❌ Error crediting worker balance: $e');
      rethrow;
    }
  }
}
