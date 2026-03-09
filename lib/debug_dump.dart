import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final snapshot = await FirebaseFirestore.instance.collection('categories').get();
  for (var doc in snapshot.docs) {
    final name = doc.data()['name'];
    final subs = doc.data()['subcategories'] as List?;
    print('Category: $name');
    if (subs != null) {
      for (var sub in subs) {
        print('  - ${sub['name']}');
      }
    }
  }
}
