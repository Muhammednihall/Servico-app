import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Try customers collection first
    var doc = await _firestore.collection('customers').doc(user.uid).get();
    if (doc.exists) {
      return {'uid': user.uid, 'role': 'customer', ...doc.data() as Map<String, dynamic>};
    }

    // Try workers collection
    doc = await _firestore.collection('workers').doc(user.uid).get();
    if (doc.exists) {
      return {'uid': user.uid, 'role': 'worker', ...doc.data() as Map<String, dynamic>};
    }

    return null;
  }

  Future<void> updateUserProfile({
    required String name,
    required String phone,
    String? address, // Not applicable for workers
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not logged in';

    final profile = await getUserProfile();
    if (profile == null) throw 'User profile not found';

    final role = profile['role'];
    final collection = role == 'customer' ? 'customers' : 'workers';

    final updateData = {
      'name': name,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (role == 'customer' && address != null) {
      updateData['address'] = address;
    }

    await _firestore.collection(collection).doc(user.uid).update(updateData);
  }
}
