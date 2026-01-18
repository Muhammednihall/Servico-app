import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to populate wallets for existing workers
/// Run this once to create wallet documents for workers who registered before this feature
Future<void> populateWorkerWallets() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    print('📝 Starting to populate wallets for existing workers...');
    
    // Get all workers
    final workersSnapshot = await firestore.collection('workers').get();
    print('Found ${workersSnapshot.docs.length} workers');
    
    int createdCount = 0;
    int skippedCount = 0;
    
    for (final workerDoc in workersSnapshot.docs) {
      final workerId = workerDoc.id;
      
      // Check if wallet already exists
      final walletDoc = await firestore.collection('wallets').doc(workerId).get();
      
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
      
      await firestore.collection('wallets').doc(workerId).set(walletData);
      print('✓ Wallet created for worker: $workerId');
      createdCount++;
    }
    
    print('✅ Wallet population complete!');
    print('Created: $createdCount, Skipped: $skippedCount');
  } catch (e) {
    print('❌ Error populating wallets: $e');
    rethrow;
  }
}
