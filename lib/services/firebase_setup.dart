import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSetup {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initializeFirebase() async {
    print('🔄 Initializing Firebase collections...');
    
    try {
      // Initialize collections by creating metadata documents
      await _initializeCollections();
      
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
    } catch (e) {
      print('  ❌ Error initializing collections: $e');
      rethrow;
    }
  }
}
