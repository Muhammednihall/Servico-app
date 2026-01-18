import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PopulateLocationsScreen extends StatelessWidget {
  PopulateLocationsScreen({Key? key}) : super(key: key);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> populateKozhikodeLocation(BuildContext context) async {
    try {
      await _firestore.collection('Locations').doc('city_kozhikode').set({
        'cityName': 'Kozhikode',
        'state': 'Kerala',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),

        'regions': {
          'kunnamangalam': {
            'regionName': 'Kunnamangalam',
            'pincode': '673571',
            'latitude': 11.3040,
            'longitude': 75.8750,
            'isActive': true,
          },
          'chevayur': {
            'regionName': 'Chevayur',
            'pincode': '673017',
            'latitude': 11.2693,
            'longitude': 75.8361,
            'isActive': true,
          },
          'medical_college': {
            'regionName': 'Medical College',
            'pincode': '673008',
            'latitude': 11.2835,
            'longitude': 75.8365,
            'isActive': true,
          },
          'parambil_bazar': {
            'regionName': 'Parambil Bazar',
            'pincode': '673012',
            'latitude': 11.2638,
            'longitude': 75.7959,
            'isActive': true,
          },
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kozhikode location added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Populate Location Data'),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.cloud_upload),
          label: const Text('Add Kozhikode Location'),
          onPressed: () => populateKozhikodeLocation(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
    );
  }
}
