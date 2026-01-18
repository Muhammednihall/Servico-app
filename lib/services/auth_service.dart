import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register Customer
  Future<bool> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      // Validate inputs
      if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty || address.isEmpty) {
        throw 'All fields are required';
      }

      print('📝 Starting customer registration for: $email');

      // Create user in Firebase Authentication
      try {
        await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✓ User created in Firebase Auth');
      } catch (e) {
        // Catch all errors including PigeonUserDetails casting errors
        if (e.toString().contains('PigeonUserDetails')) {
          print('⚠️ Firebase plugin issue detected, but user may be created');
          // Continue anyway - user might be created despite the error
        } else {
          print('❌ Auth error: $e');
          rethrow;
        }
      }

      // Add delay to ensure user is set
      await Future.delayed(const Duration(milliseconds: 500));

      // Get current user
      String? uid;
      try {
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser == null) {
          throw 'Failed to get current user after registration';
        }
        uid = currentUser.uid;
        print('✓ Got UID: $uid');
      } catch (e) {
        print('❌ Error getting user: $e');
        rethrow;
      }

      // Store customer details in Firestore
      print('📝 Writing customer document to Firestore...');
      final customerData = {
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'role': 'customer',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await _firestore.collection('customers').doc(uid).set(customerData);
      print('✓ Customer document created in Firestore successfully');

      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        throw 'The account already exists for that email.';
      } else {
        throw e.message ?? 'An error occurred during registration';
      }
    } catch (e) {
      print('❌ Registration error: $e');
      throw 'Registration failed: $e';
    }
  }

  // Register Worker
  Future<bool> registerWorker({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String serviceType,
    required String experience,
    required String serviceArea,
  }) async {
    try {
      // Validate inputs
      if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty || 
          serviceType.isEmpty || experience.isEmpty || serviceArea.isEmpty) {
        throw 'All fields are required';
      }

      print('📝 Starting worker registration for: $email');

      // Create user in Firebase Authentication
      try {
        await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✓ User created in Firebase Auth');
      } catch (e) {
        // Catch all errors including PigeonUserDetails casting errors
        if (e.toString().contains('PigeonUserDetails')) {
          print('⚠️ Firebase plugin issue detected, but user may be created');
          // Continue anyway - user might be created despite the error
        } else {
          print('❌ Auth error: $e');
          rethrow;
        }
      }

      // Add delay to ensure user is set
      await Future.delayed(const Duration(milliseconds: 500));

      // Get current user
      String? uid;
      try {
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser == null) {
          throw 'Failed to get current user after registration';
        }
        uid = currentUser.uid;
        print('✓ Got UID: $uid');
      } catch (e) {
        print('❌ Error getting user: $e');
        rethrow;
      }

      // Store worker details in Firestore
      print('📝 Writing worker document to Firestore...');
      final workerData = {
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'worker',
        'serviceType': serviceType.trim(),
        'experience': experience.trim(),
        'serviceArea': serviceArea.trim(),
        'isAvailable': false,
        'rating': 0.0,
        'totalReviews': 0,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await _firestore.collection('workers').doc(uid).set(workerData);
      print('✓ Worker document created in Firestore successfully');

      // Create wallet for worker
      print('📝 Creating wallet for worker...');
      final walletData = {
        'userId': uid,
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

      await _firestore.collection('wallets').doc(uid).set(walletData);
      print('✓ Wallet created successfully');

      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        throw 'The account already exists for that email.';
      } else {
        throw e.message ?? 'An error occurred during registration';
      }
    } catch (e) {
      print('❌ Registration error: $e');
      throw 'Registration failed: $e';
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('📝 Starting login for: $email');

      try {
        await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✓ User signed in');
      } catch (e) {
        // Catch all errors including PigeonUserDetails casting errors
        if (e.toString().contains('PigeonUserDetails')) {
          print('⚠️ Firebase plugin issue detected, but user may be signed in');
          // Continue anyway - user might be signed in despite the error
        } else {
          print('❌ Sign in error: $e');
          rethrow;
        }
      }

      // Add delay to ensure user is set
      await Future.delayed(const Duration(milliseconds: 500));

      // Get current user
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw 'Failed to get current user after login';
      }

      final uid = currentUser.uid;
      final userEmail = currentUser.email;
      print('✓ Got UID: $uid');

      // Determine user role by checking both collections
      print('📝 Checking user role...');
      DocumentSnapshot customerDoc = await _firestore
          .collection('customers')
          .doc(uid)
          .get();

      DocumentSnapshot workerDoc = await _firestore
          .collection('workers')
          .doc(uid)
          .get();

      String role = 'customer'; // default
      if (workerDoc.exists) {
        role = 'worker';
      } else if (customerDoc.exists) {
        role = 'customer';
      }

      print('✓ User role: $role');

      return {
        'success': true,
        'uid': uid,
        'email': userEmail,
        'role': role,
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        throw 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        throw 'Invalid email or password.';
      } else {
        throw e.message ?? 'Login failed';
      }
    } catch (e) {
      print('❌ Login error: $e');
      throw 'Login failed: $e';
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Logout failed: $e';
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot customerDoc = await _firestore.collection('customers').doc(uid).get();
      if (customerDoc.exists) {
        return 'customer';
      }

      DocumentSnapshot workerDoc = await _firestore.collection('workers').doc(uid).get();
      if (workerDoc.exists) {
        return 'worker';
      }

      return null;
    } catch (e) {
      throw 'Failed to get user role: $e';
    }
  }

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _firebaseAuth.currentUser != null;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (email.isEmpty) {
        throw 'Please enter your email address';
      }

      print('📝 Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print('✓ Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        throw 'No account found with this email address.';
      } else {
        throw e.message ?? 'Failed to send password reset email';
      }
    } catch (e) {
      print('❌ Error sending password reset email: $e');
      throw 'Failed to send password reset email: $e';
    }
  }

  // Update worker availability status
  Future<void> updateWorkerAvailability(String uid, bool isAvailable) async {
    try {
      print('📝 Updating worker availability to: $isAvailable');
      await _firestore.collection('workers').doc(uid).update({
        'isAvailable': isAvailable,
        'updatedAt': DateTime.now(),
      });
      print('✓ Worker availability updated successfully');
    } catch (e) {
      print('❌ Error updating availability: $e');
      throw 'Failed to update availability: $e';
    }
  }
}
