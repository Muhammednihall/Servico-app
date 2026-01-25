import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubCategoryModel {
  final String id;
  final String name;
  final String icon;

  SubCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory SubCategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return SubCategoryModel(
      id: id,
      name: map['name'] ?? '',
      icon: map['icon'] ?? 'build',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
    };
  }

  IconData getIconData() {
    switch (icon) {
      case 'electrical_services': return Icons.electrical_services;
      case 'light': return Icons.lightbulb;
      case 'power': return Icons.power;
      case 'cable': return Icons.cable;
      case 'water_drop': return Icons.water_drop;
      case 'shower': return Icons.shower;
      case 'bathtub': return Icons.bathtub;
      case 'plumbing': return Icons.plumbing;
      case 'carpenter': return Icons.carpenter;
      case 'chair': return Icons.chair;
      case 'door_front': return Icons.door_sliding;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'home': return Icons.home;
      case 'local_laundry_service': return Icons.local_laundry_service;
      case 'format_paint': return Icons.format_paint;
      case 'palette': return Icons.palette;
      case 'brush': return Icons.brush;
      case 'palette_outlined': return Icons.palette_outlined;
      case 'grass': return Icons.grass;
      case 'local_florist': return Icons.local_florist;
      case 'ac_unit': return Icons.ac_unit;
      case 'hvac': return Icons.hvac;
      case 'thermostat': return Icons.thermostat;
      case 'local_shipping': return Icons.local_shipping;
      case 'moving': return Icons.local_shipping;
      case 'garage': return Icons.garage;
      case 'kitchen': return Icons.kitchen;
      case 'microwave': return Icons.microwave;
      case 'tv': return Icons.tv;
      case 'build': return Icons.build;
      case 'handyman': return Icons.handyman;
      case 'construction': return Icons.construction;
      case 'security': return Icons.security;
      case 'videocam': return Icons.videocam;
      case 'router': return Icons.router;
      case 'smartphone': return Icons.smartphone;
      case 'spa': return Icons.spa;
      case 'health_and_safety': return Icons.health_and_safety;
      case 'medical_services': return Icons.medical_services;
      case 'fitness_center': return Icons.fitness_center;
      case 'celebration': return Icons.celebration;
      case 'restaurant': return Icons.restaurant;
      case 'camera_alt': return Icons.camera_alt;
      case 'pest_control': return Icons.bug_report;
      case 'car_repair': return Icons.car_repair;
      default: return Icons.category;
    }
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String image;
  final String color;
  final List<SubCategoryModel> subcategories;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.image,
    required this.color,
    this.subcategories = const [],
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    
    List<SubCategoryModel> subs = [];
    if (data['subcategories'] != null && data['subcategories'] is List) {
      final subList = data['subcategories'] as List;
      subs = List.generate(subList.length, (index) {
        final subMap = subList[index] as Map<String, dynamic>;
        return SubCategoryModel.fromMap(subMap, '${doc.id}_$index');
      });
    }
    
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Category',
      icon: data['icon'] ?? 'category',
      image: data['image'] ?? '',
      color: data['color'] ?? '#2463eb',
      subcategories: subs,
    );
  }

  IconData getIconData() {
    switch (icon) {
      case 'electrical_services': return Icons.electrical_services;
      case 'water_drop': return Icons.water_drop;
      case 'carpenter': return Icons.carpenter;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'format_paint': return Icons.format_paint;
      case 'grass': return Icons.grass;
      case 'ac_unit': return Icons.ac_unit;
      case 'local_shipping': return Icons.local_shipping;
      case 'kitchen': return Icons.kitchen;
      case 'build': return Icons.build;
      case 'handyman': return Icons.handyman;
      case 'car_repair': return Icons.car_repair;
      case 'security': return Icons.security;
      case 'spa': return Icons.spa;
      case 'celebration': return Icons.celebration;
      case 'medical_services': return Icons.medical_services;
      default: return Icons.category;
    }
  }

  Color getColor() {
    final hexCode = color.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all categories from Firestore
  Stream<List<CategoryModel>> streamCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
    });
  }

  /// Get top categories for the home screen
  Stream<List<CategoryModel>> streamTopCategories({int limit = 5}) {
    return _firestore
        .collection('categories')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
    });
  }

  /// Initialize categories collection with default data (Useful for first-time setup)
  Future<void> initializeDefaultCategories() async {
    // Clear existing categories first to ensure only hardcoded ones exist
    final existingDocs = await _firestore.collection('categories').get();
    for (var doc in existingDocs.docs) {
      await doc.reference.delete();
    }

    final categories = [
      {
        'name': 'Electrical & Smart Home',
        'icon': 'electrical_services',
        'image': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400&h=400&fit=crop',
        'color': '#3b82f6',
        'subcategories': [
          {'name': 'Wiring & Rewiring', 'icon': 'cable'},
          {'name': 'Light Installation', 'icon': 'light'},
          {'name': 'Switch & Socket', 'icon': 'power'},
          {'name': 'CCTV & Security', 'icon': 'videocam'},
          {'name': 'WiFi & Networking', 'icon': 'router'},
          {'name': 'Inverter & Power', 'icon': 'power'},
        ]
      },
      {
        'name': 'Plumbing & Water',
        'icon': 'water_drop',
        'image': 'https://images.unsplash.com/photo-1505798577917-a65157d3320a?w=400&h=400&fit=crop',
        'color': '#06b6d4',
        'subcategories': [
          {'name': 'Tap & Leakage', 'icon': 'water_drop'},
          {'name': 'Toilet Repair', 'icon': 'plumbing'},
          {'name': 'Bathroom Fitting', 'icon': 'bathtub'},
          {'name': 'Water Tank', 'icon': 'water_drop'},
          {'name': 'Irrigation System', 'icon': 'grass'},
          {'name': 'Water Pump', 'icon': 'power'},
        ]
      },
      {
        'name': 'Appliance & IT',
        'icon': 'kitchen',
        'image': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=400&h=400&fit=crop',
        'color': '#f59e0b',
        'subcategories': [
          {'name': 'AC Servicing', 'icon': 'ac_unit'},
          {'name': 'Refrigerator', 'icon': 'kitchen'},
          {'name': 'Washing Machine', 'icon': 'local_laundry_service'},
          {'name': 'Microwave & Oven', 'icon': 'microwave'},
          {'name': 'TV & Home Theatre', 'icon': 'tv'},
          {'name': 'PC & Laptop Repair', 'icon': 'smartphone'},
        ]
      },
      {
        'name': 'Cleaning & Garden',
        'icon': 'cleaning_services',
        'image': 'https://images.unsplash.com/photo-1581578731548-c64695cc6954?w=400&h=400&fit=crop',
        'color': '#a855f7',
        'subcategories': [
          {'name': 'Full House Cleaning', 'icon': 'home'},
          {'name': 'Garden Maintenance', 'icon': 'grass'},
          {'name': 'Lawn & Plant Care', 'icon': 'local_florist'},
          {'name': 'Sofa & Carpet', 'icon': 'chair'},
          {'name': 'Water Tank Clean', 'icon': 'water_drop'},
          {'name': 'Pest Control', 'icon': 'pest_control'},
        ]
      },
      {
        'name': 'Interior & Decor',
        'icon': 'format_paint',
        'image': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=400&h=400&fit=crop',
        'color': '#ec4899',
        'subcategories': [
          {'name': 'House Painting', 'icon': 'format_paint'},
          {'name': 'Carpenter Service', 'icon': 'carpenter'},
          {'name': 'Furniture Assembly', 'icon': 'handyman'},
          {'name': 'Wallpaper Service', 'icon': 'palette'},
          {'name': 'Flooring Work', 'icon': 'construction'},
          {'name': 'Smart Locks', 'icon': 'security'},
        ]
      },
      {
        'name': 'Relocation Pro',
        'icon': 'local_shipping',
        'image': 'https://images.unsplash.com/photo-1600518464441-9154a4dba221?w=400&h=400&fit=crop',
        'color': '#6366f1',
        'subcategories': [
          {'name': 'Home Shifting', 'icon': 'home'},
          {'name': 'Office Moving', 'icon': 'local_shipping'},
          {'name': 'Packing Service', 'icon': 'moving'},
          {'name': 'Storage Solutions', 'icon': 'garage'},
          {'name': 'Vehicle Transport', 'icon': 'local_shipping'},
          {'name': 'Local Shifting', 'icon': 'moving'},
        ]
      },
      {
        'name': 'Automotive Care',
        'icon': 'car_repair',
        'image': 'https://images.unsplash.com/photo-1625047509168-a7026f36de04?w=400&h=400&fit=crop',
        'color': '#ef4444',
        'subcategories': [
          {'name': 'Car Washing', 'icon': 'water_drop'},
          {'name': 'Full Car Service', 'icon': 'car_repair'},
          {'name': 'Bike Service', 'icon': 'car_repair'},
          {'name': 'Battery & Jumpstart', 'icon': 'power'},
          {'name': 'Tyre & Puncture', 'icon': 'car_repair'},
          {'name': 'Car Spa/Detailing', 'icon': 'spa'},
        ]
      },
      {
        'name': 'Events & Decor',
        'icon': 'celebration',
        'image': 'https://images.unsplash.com/photo-1472653431158-6364773b2a56?w=400&h=400&fit=crop',
        'color': '#f43f5e',
        'subcategories': [
          {'name': 'Balloon Decor', 'icon': 'celebration'},
          {'name': 'Catering Service', 'icon': 'restaurant'},
          {'name': 'Party Cleaning', 'icon': 'cleaning_services'},
          {'name': 'Rental Furniture', 'icon': 'chair'},
          {'name': 'Photography', 'icon': 'camera_alt'},
          {'name': 'Event Staff', 'icon': 'handyman'},
        ]
      },
      {
        'name': 'Health & Wellness',
        'icon': 'medical_services',
        'image': 'https://images.unsplash.com/photo-1540555700478-4be289fbecee?w=400&h=400&fit=crop',
        'color': '#14b8a6',
        'subcategories': [
          {'name': 'Massage Therapy', 'icon': 'spa'},
          {'name': 'Salon at Home', 'icon': 'spa'},
          {'name': 'Yoga Trainer', 'icon': 'fitness_center'},
          {'name': 'Physiotherapy', 'icon': 'medical_services'},
          {'name': 'Nursing Care', 'icon': 'health_and_safety'},
          {'name': 'Elderly Support', 'icon': 'health_and_safety'},
        ]
      },
    ];

    for (var cat in categories) {
      await _firestore.collection('categories').doc(cat['name'].toString().toLowerCase().replaceAll('&', 'and').replaceAll(' ', '_')).set(cat);
    }
    print("Servico: Categories initialized successfully.");
  }
}
