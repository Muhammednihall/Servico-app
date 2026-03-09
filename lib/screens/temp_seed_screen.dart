import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TempSeedScreen extends StatefulWidget {
  const TempSeedScreen({super.key});

  @override
  State<TempSeedScreen> createState() => _TempSeedScreenState();
}

class _TempSeedScreenState extends State<TempSeedScreen> {
  bool _isSeeding = false;
  String _status = 'Ready to seed Gas Category';

  Future<void> _fixPaintingCategory() async {
    setState(() {
      _isSeeding = true;
      _status = 'Updating Painting Category...';
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Rename any existing 'Pest Control' to 'Painting'
      final snapshot = await firestore.collection('categories')
          .where('name', isEqualTo: 'Pest Control')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'name': 'Painting',
          'icon': 'format_paint',
          'color': '0xFFFFD700', // Gold/Yellow color for painting
        });
      }

      // 2. Ensure we have a high-quality painting category
      await firestore.collection('categories').doc('painting').set({
        'name': 'Painting',
        'icon': 'format_paint',
        'color': '0xFFFFD700',
        'order': 6,
        'isTop': false,
        'subcategories': [
          {'name': 'Full Home Painting', 'icon': 'format_paint'},
          {'name': 'Interior Wall Painting', 'icon': 'brush'},
          {'name': 'Exterior Painting', 'icon': 'home'},
          {'name': 'Door & Window Polish', 'icon': 'palette'},
          {'name': 'Waterproofing', 'icon': 'water_drop'},
        ]
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isSeeding = false;
          _status = 'Painting Category fixed successfully!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSeeding = false;
          _status = 'Error: $e';
        });
      }
    }
  }

  Future<void> _seedGasCategory() async {
    setState(() {
      _isSeeding = true;
      _status = 'Seeding...';
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Add Gas category to categories collection
      await firestore.collection('categories').doc('gas').set({
        'name': 'Gas',
        'icon': 'local_gas_station_rounded',
        'color': '0xFFFF5F00',
        'order': 5,
        'isTop': false,
      });

      // Seed Gas Providers
      final providers = [
        {
          'name': 'Indane Gas',
          'subtext': 'Indian Oil Corporation Ltd.',
          'primaryPhone': '1800-2333-555',
          'secondaryPhone': '8454955555',
          'color': '0xFFFF5F00',
        },
        {
          'name': 'Bharatgas',
          'subtext': 'Bharat Petroleum (BPCL)',
          'primaryPhone': '1800 22 4344',
          'secondaryPhone': '7715012345',
          'color': '0xFF0054A6',
        },
        {
          'name': 'HP Gas',
          'subtext': 'HPCL (Hindustan Petroleum)',
          'primaryPhone': '1800-2333-555',
          'secondaryPhone': '99610 23456',
          'color': '0xFF003D99',
        },
      ];

      for (var provider in providers) {
        await firestore.collection('gas_providers').add(provider);
      }

      if (mounted) {
        setState(() {
          _isSeeding = false;
          _status = 'Gas Category seeded successfully!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSeeding = false;
          _status = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Temporary Seed Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            const SizedBox(height: 20),
            if (_isSeeding)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _seedGasCategory,
                child: const Text('Seed Gas Category'),
              ),
            const SizedBox(height: 12),
            if (!_isSeeding)
              ElevatedButton(
                onPressed: _fixPaintingCategory,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Fix/Seed Painting Category', style: TextStyle(color: Colors.white)),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
