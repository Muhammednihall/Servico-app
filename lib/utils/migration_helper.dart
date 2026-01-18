import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate existing workers by creating wallet documents
  /// Call this once after updating the app
  static Future<void> migrateExistingWorkers() async {
    try {
      print('🔄 Starting worker migration...');
      
      final workersSnapshot = await _firestore.collection('workers').get();
      print('Found ${workersSnapshot.docs.length} workers');
      
      int createdCount = 0;
      int skippedCount = 0;
      
      for (final workerDoc in workersSnapshot.docs) {
        final workerId = workerDoc.id;
        
        // Check if wallet already exists
        final walletDoc = await _firestore.collection('wallets').doc(workerId).get();
        
        if (walletDoc.exists) {
          print('⏭️  Wallet already exists for worker: $workerId');
          skippedCount++;
          continue;
        }
        
        // Create wallet for this worker
        final walletData = {
          'userId': workerId,
          'userType': 'worker',
          'balance': 0.0,
          'totalEarned': 0.0,
          'totalSpent': 0.0,
          'currency': 'USD',
          'payoutMethod': 'bank_transfer',
          'payoutDetails': {
            'accountHolder': '',
            'accountNumber': '',
            'bankName': '',
            'ifscCode': '',
            'upiId': '',
          },
          'nextPayoutDate': DateTime.now().add(const Duration(days: 7)),
          'lastPayoutDate': null,
          'lastPayoutAmount': null,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        };
        
        await _firestore.collection('wallets').doc(workerId).set(walletData);
        print('✓ Wallet created for worker: $workerId');
        createdCount++;
      }
      
      print('✅ Migration complete!');
      print('Created: $createdCount, Skipped: $skippedCount');
    } catch (e) {
      print('❌ Migration error: $e');
      rethrow;
    }
  }

  /// Verify all workers have wallets
  static Future<Map<String, dynamic>> verifyWorkerWallets() async {
    try {
      print('🔍 Verifying worker wallets...');
      
      final workersSnapshot = await _firestore.collection('workers').get();
      final walletsSnapshot = await _firestore.collection('wallets').get();
      
      final workersWithoutWallets = <String>[];
      
      for (final workerDoc in workersSnapshot.docs) {
        final workerId = workerDoc.id;
        final hasWallet = walletsSnapshot.docs.any((doc) => doc.id == workerId);
        
        if (!hasWallet) {
          workersWithoutWallets.add(workerId);
        }
      }
      
      return {
        'totalWorkers': workersSnapshot.docs.length,
        'totalWallets': walletsSnapshot.docs.length,
        'workersWithoutWallets': workersWithoutWallets,
        'isHealthy': workersWithoutWallets.isEmpty,
      };
    } catch (e) {
      print('❌ Verification error: $e');
      rethrow;
    }
  }
}
