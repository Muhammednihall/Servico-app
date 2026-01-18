import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script to populate workers with The Office character names
/// This creates workers directly in Firestore with complete registration data
Future<void> populateOfficeWorkers() async {
  final firestore = FirebaseFirestore.instance;
  
  // Define workers from The Office - organized by region
  // Each region will have 3-4 workers with different service types
  final List<Map<String, dynamic>> officeWorkers = [
    // Kozhikode - Beypore Region (4 workers)
    {
      'name': 'Michael Scott',
      'email': 'michael.scott@dundermifflin.com',
      'phone': '9876543001',
      'serviceType': 'Electrician',
      'experience': '8',
      'serviceArea': 'region_beypore',
      'city': 'city_kozhikode',
      'rating': 4.8,
      'totalReviews': 127,
      'isAvailable': true,
    },
    {
      'name': 'Jim Halpert',
      'email': 'jim.halpert@dundermifflin.com',
      'phone': '9876543002',
      'serviceType': 'Plumber',
      'experience': '5',
      'serviceArea': 'region_beypore',
      'city': 'city_kozhikode',
      'rating': 4.6,
      'totalReviews': 89,
      'isAvailable': true,
    },
    {
      'name': 'Dwight Schrute',
      'email': 'dwight.schrute@dundermifflin.com',
      'phone': '9876543003',
      'serviceType': 'Carpenter,Electrician',
      'experience': '12',
      'serviceArea': 'region_beypore',
      'city': 'city_kozhikode',
      'rating': 4.9,
      'totalReviews': 203,
      'isAvailable': true,
    },
    {
      'name': 'Stanley Hudson',
      'email': 'stanley.hudson@dundermifflin.com',
      'phone': '9876543004',
      'serviceType': 'Home Cleaner',
      'experience': '15',
      'serviceArea': 'region_beypore',
      'city': 'city_kozhikode',
      'rating': 4.3,
      'totalReviews': 156,
      'isAvailable': false,
    },
    
    // Kozhikode - Nadakkavu Region (4 workers)
    {
      'name': 'Andy Bernard',
      'email': 'andy.bernard@dundermifflin.com',
      'phone': '9876543005',
      'serviceType': 'Mechanic',
      'experience': '6',
      'serviceArea': 'region_nadakkavu',
      'city': 'city_kozhikode',
      'rating': 4.5,
      'totalReviews': 67,
      'isAvailable': true,
    },
    {
      'name': 'Kevin Malone',
      'email': 'kevin.malone@dundermifflin.com',
      'phone': '9876543006',
      'serviceType': 'Gardener',
      'experience': '4',
      'serviceArea': 'region_nadakkavu',
      'city': 'city_kozhikode',
      'rating': 4.2,
      'totalReviews': 45,
      'isAvailable': true,
    },
    {
      'name': 'Oscar Martinez',
      'email': 'oscar.martinez@dundermifflin.com',
      'phone': '9876543007',
      'serviceType': 'Electrician,Plumber',
      'experience': '9',
      'serviceArea': 'region_nadakkavu',
      'city': 'city_kozhikode',
      'rating': 4.7,
      'totalReviews': 112,
      'isAvailable': true,
    },
    {
      'name': 'Angela Martin',
      'email': 'angela.martin@dundermifflin.com',
      'phone': '9876543008',
      'serviceType': 'Home Cleaner',
      'experience': '7',
      'serviceArea': 'region_nadakkavu',
      'city': 'city_kozhikode',
      'rating': 4.8,
      'totalReviews': 98,
      'isAvailable': false,
    },
    
    // Kozhikode - Palazhi Region (3 workers)
    {
      'name': 'Pam Beesly',
      'email': 'pam.beesly@dundermifflin.com',
      'phone': '9876543009',
      'serviceType': 'Home Cleaner,Gardener',
      'experience': '4',
      'serviceArea': 'region_palazhi',
      'city': 'city_kozhikode',
      'rating': 4.9,
      'totalReviews': 134,
      'isAvailable': true,
    },
    {
      'name': 'Darryl Philbin',
      'email': 'darryl.philbin@dundermifflin.com',
      'phone': '9876543010',
      'serviceType': 'Carpenter',
      'experience': '10',
      'serviceArea': 'region_palazhi',
      'city': 'city_kozhikode',
      'rating': 4.6,
      'totalReviews': 87,
      'isAvailable': true,
    },
    {
      'name': 'Toby Flenderson',
      'email': 'toby.flenderson@dundermifflin.com',
      'phone': '9876543011',
      'serviceType': 'Plumber',
      'experience': '11',
      'serviceArea': 'region_palazhi',
      'city': 'city_kozhikode',
      'rating': 4.4,
      'totalReviews': 76,
      'isAvailable': true,
    },
    
    // Kozhikode - Feroke Region (3 workers)
    {
      'name': 'Ryan Howard',
      'email': 'ryan.howard@dundermifflin.com',
      'phone': '9876543012',
      'serviceType': 'Electrician',
      'experience': '3',
      'serviceArea': 'region_feroke',
      'city': 'city_kozhikode',
      'rating': 4.1,
      'totalReviews': 34,
      'isAvailable': true,
    },
    {
      'name': 'Kelly Kapoor',
      'email': 'kelly.kapoor@dundermifflin.com',
      'phone': '9876543013',
      'serviceType': 'Home Cleaner',
      'experience': '5',
      'serviceArea': 'region_feroke',
      'city': 'city_kozhikode',
      'rating': 4.5,
      'totalReviews': 56,
      'isAvailable': true,
    },
    {
      'name': 'Creed Bratton',
      'email': 'creed.bratton@dundermifflin.com',
      'phone': '9876543014',
      'serviceType': 'Mechanic,Carpenter',
      'experience': '20',
      'serviceArea': 'region_feroke',
      'city': 'city_kozhikode',
      'rating': 4.0,
      'totalReviews': 28,
      'isAvailable': false,
    },
    
    // Kozhikode - Ramanattukara Region (4 workers)
    {
      'name': 'Phyllis Vance',
      'email': 'phyllis.vance@dundermifflin.com',
      'phone': '9876543015',
      'serviceType': 'Gardener',
      'experience': '8',
      'serviceArea': 'region_ramanattukara',
      'city': 'city_kozhikode',
      'rating': 4.7,
      'totalReviews': 92,
      'isAvailable': true,
    },
    {
      'name': 'Meredith Palmer',
      'email': 'meredith.palmer@dundermifflin.com',
      'phone': '9876543016',
      'serviceType': 'Plumber',
      'experience': '6',
      'serviceArea': 'region_ramanattukara',
      'city': 'city_kozhikode',
      'rating': 4.3,
      'totalReviews': 54,
      'isAvailable': true,
    },
    {
      'name': 'Erin Hannon',
      'email': 'erin.hannon@dundermifflin.com',
      'phone': '9876543017',
      'serviceType': 'Home Cleaner,Gardener',
      'experience': '2',
      'serviceArea': 'region_ramanattukara',
      'city': 'city_kozhikode',
      'rating': 4.8,
      'totalReviews': 41,
      'isAvailable': true,
    },
    {
      'name': 'Pete Miller',
      'email': 'pete.miller@dundermifflin.com',
      'phone': '9876543018',
      'serviceType': 'Mechanic',
      'experience': '4',
      'serviceArea': 'region_ramanattukara',
      'city': 'city_kozhikode',
      'rating': 4.4,
      'totalReviews': 38,
      'isAvailable': true,
    },
  ];
  
  try {
    print('📝 Starting to populate The Office workers...');
    print('Total workers to create: ${officeWorkers.length}');
    
    int createdCount = 0;
    int skippedCount = 0;
    
    for (final worker in officeWorkers) {
      // Generate a unique ID for the worker (simulating what Firebase Auth would create)
      final workerId = 'office_${worker['email'].toString().split('@')[0].replaceAll('.', '_')}';
      
      // Check if worker already exists
      final existingDoc = await firestore.collection('workers').doc(workerId).get();
      
      if (existingDoc.exists) {
        print('⏭️  Worker already exists: ${worker['name']}');
        skippedCount++;
        continue;
      }
      
      // Create worker document
      final workerData = {
        'uid': workerId,
        'name': worker['name'],
        'email': worker['email'],
        'phone': worker['phone'],
        'role': 'worker',
        'serviceType': worker['serviceType'],
        'experience': worker['experience'],
        'serviceArea': worker['serviceArea'],
        'city': worker['city'],
        'isAvailable': worker['isAvailable'],
        'rating': worker['rating'],
        'totalReviews': worker['totalReviews'],
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      
      await firestore.collection('workers').doc(workerId).set(workerData);
      print('✓ Worker created: ${worker['name']} (${worker['serviceType']}) - ${worker['serviceArea']}');
      
      // Create wallet for this worker
      final walletData = {
        'userId': workerId,
        'userType': 'worker',
        'balance': (worker['totalReviews'] as int) * 50.0, // Some initial balance based on reviews
        'totalEarned': (worker['totalReviews'] as int) * 150.0,
        'totalSpent': 0.0,
        'currency': 'INR',
        'payoutMethod': 'bank_transfer',
        'payoutDetails': {
          'accountHolder': worker['name'],
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
      print('  💳 Wallet created for: ${worker['name']}');
      
      createdCount++;
    }
    
    print('');
    print('✅ The Office workers population complete!');
    print('Created: $createdCount workers');
    print('Skipped: $skippedCount workers (already existed)');
    print('');
    print('Workers are distributed across regions:');
    print('  • Beypore: 4 workers');
    print('  • Nadakkavu: 4 workers');
    print('  • Palazhi: 3 workers');
    print('  • Feroke: 3 workers');
    print('  • Ramanattukara: 4 workers');
  } catch (e) {
    print('❌ Error populating workers: $e');
    rethrow;
  }
}
