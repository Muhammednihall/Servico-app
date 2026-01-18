import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/migration_helper.dart';
import '../scripts/populate_office_workers.dart';

class FirebaseSetup {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initializeFirebase() async {
    print('🔄 Initializing Firebase collections...');
    
    try {
      // Initialize collections by creating metadata documents
      await _initializeCollections();
      
      // Run migration for existing workers
      await MigrationHelper.migrateExistingWorkers();
      
      // Populate The Office workers (only creates if they don't exist)
      await populateOfficeWorkers();
      
      print('✅ Firebase initialization complete!');
    } catch (e) {
      print('❌ Error during Firebase initialization: $e');
    }
  }

  static Future<void> _initializeCollections() async {
    try {
      print('  → Initializing customers collection...');
      // Create a metadata document for customers collection
      await _firestore.collection('customers').doc('_metadata').set({
        'initialized': true,
        'createdAt': DateTime.now(),
      }, SetOptions(merge: true));
      print('  ✓ Customers collection initialized');

      print('  → Initializing workers collection...');
      // Create a metadata document for workers collection
      await _firestore.collection('workers').doc('_metadata').set({
        'initialized': true,
        'createdAt': DateTime.now(),
      }, SetOptions(merge: true));
      print('  ✓ Workers collection initialized');

      print('  → Initializing wallets collection...');
      // Create a metadata document for wallets collection
      await _firestore.collection('wallets').doc('_metadata').set({
        'initialized': true,
        'createdAt': DateTime.now(),
      }, SetOptions(merge: true));
      print('  ✓ Wallets collection initialized');

      print('  → Initializing jobs collection...');
      // Create a metadata document for jobs collection
      await _firestore.collection('jobs').doc('_metadata').set({
        'initialized': true,
        'createdAt': DateTime.now(),
      }, SetOptions(merge: true));
      print('  ✓ Jobs collection initialized');

      print('  → Initializing transactions collection...');
      // Create a metadata document for transactions collection
      await _firestore.collection('transactions').doc('_metadata').set({
        'initialized': true,
        'createdAt': DateTime.now(),
      }, SetOptions(merge: true));
      print('  ✓ Transactions collection initialized');

      print('  → Initializing ratings collection...');
      // Create a metadata document for ratings collection
      await _firestore.collection('ratings').doc('_metadata').set({
        'initialized': true,
        'createdAt': DateTime.now(),
      }, SetOptions(merge: true));
      print('  ✓ Ratings collection initialized');
    } catch (e) {
      print('  ❌ Error initializing collections: $e');
      rethrow;
    }
  }
}
