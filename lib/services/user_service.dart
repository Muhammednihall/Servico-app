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
      return {
        'uid': user.uid,
        'role': 'customer',
        ...doc.data() as Map<String, dynamic>,
      };
    }

    // Try workers collection
    doc = await _firestore.collection('workers').doc(user.uid).get();
    if (doc.exists) {
      return {
        'uid': user.uid,
        'role': 'worker',
        ...doc.data() as Map<String, dynamic>,
      };
    }

    return null;
  }

  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    // We'll check customers first, then workers. For simplicity in streaming,
    // we can use a merge or just stream the common user info if we had a users collection,
    // but here we check the role first or just stream the customer one specifically for this task.
    // Given the context, we mostly need it for the name in the header.
    return _firestore.collection('customers').doc(uid).snapshots().map((doc) {
      if (doc.exists) return doc.data();
      return null;
    });
  }

  Future<void> updateUserProfile({
    required String name,
    required String phone,
    String? address, // Not applicable for workers
    String? serviceArea, // Applicable for workers
    double? latitude,
    double? longitude,
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
    } else if (role == 'worker') {
      if (serviceArea != null) updateData['serviceArea'] = serviceArea;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (latitude != null) updateData['lat'] = latitude; // Compatibility
      if (longitude != null) updateData['lng'] = longitude; // Compatibility
    }

    await _firestore.collection(collection).doc(user.uid).update(updateData);
  }
}
