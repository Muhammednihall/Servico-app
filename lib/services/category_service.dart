import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubCategoryModel {
  final String id;
  final String name;
  final String icon;

  SubCategoryModel({required this.id, required this.name, required this.icon});

  factory SubCategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return SubCategoryModel(
      id: id,
      name: map['name'] ?? '',
      icon: map['icon'] ?? 'build',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'icon': icon};
  }

  IconData getIconData() {
    switch (icon) {
      case 'electrical_services':
        return Icons.electrical_services;
      case 'light':
        return Icons.lightbulb;
      case 'power':
        return Icons.power;
      case 'cable':
        return Icons.cable;
      case 'water_drop':
        return Icons.water_drop;
      case 'shower':
        return Icons.shower;
      case 'bathtub':
        return Icons.bathtub;
      case 'plumbing':
        return Icons.plumbing;
      case 'carpenter':
        return Icons.carpenter;
      case 'chair':
        return Icons.chair;
      case 'door_front':
        return Icons.door_sliding;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'home':
        return Icons.home;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'format_paint':
        return Icons.format_paint;
      case 'palette':
        return Icons.palette;
      case 'brush':
        return Icons.brush;
      case 'palette_outlined':
        return Icons.palette_outlined;
      case 'grass':
        return Icons.grass;
      case 'local_florist':
        return Icons.local_florist;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'hvac':
        return Icons.hvac;
      case 'thermostat':
        return Icons.thermostat;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'moving':
        return Icons.local_shipping;
      case 'garage':
        return Icons.garage;
      case 'kitchen':
        return Icons.kitchen;
      case 'microwave':
        return Icons.microwave;
      case 'tv':
        return Icons.tv;
      case 'build':
        return Icons.build;
      case 'handyman':
        return Icons.handyman;
      case 'construction':
        return Icons.construction;
      case 'security':
        return Icons.security;
      case 'videocam':
        return Icons.videocam;
      case 'router':
        return Icons.router;
      case 'smartphone':
        return Icons.smartphone;
      case 'spa':
        return Icons.spa;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'medical_services':
        return Icons.medical_services;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'celebration':
        return Icons.celebration;
      case 'restaurant':
        return Icons.restaurant;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'pest_control':
        return Icons.bug_report;
      case 'car_repair':
        return Icons.car_repair;
      case 'lock':
        return Icons.lock_outline;
      case 'wifi':
        return Icons.wifi;
      case 'chair_outlined':
        return Icons.chair_outlined;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'vpn_key':
        return Icons.vpn_key;
      case 'lock_open':
        return Icons.lock_open;
      default:
        return Icons.category;
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
      case 'electrical_services':
        return Icons.electrical_services;
      case 'water_drop':
        return Icons.water_drop;
      case 'carpenter':
        return Icons.carpenter;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'format_paint':
        return Icons.format_paint;
      case 'grass':
        return Icons.grass;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'kitchen':
        return Icons.kitchen;
      case 'build':
        return Icons.build;
      case 'handyman':
        return Icons.handyman;
      case 'car_repair':
        return Icons.car_repair;
      case 'security':
        return Icons.security;
      case 'spa':
        return Icons.spa;
      case 'celebration':
        return Icons.celebration;
      case 'medical_services':
        return Icons.medical_services;
      case 'router':
        return Icons.router;
      case 'lock':
        return Icons.lock_outline;
      case 'bug_report':
        return Icons.bug_report_outlined;
      case 'chair':
        return Icons.chair_outlined;
      case 'laundry':
        return Icons.local_laundry_service;
      default:
        return Icons.category;
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
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get top categories for the home screen
  Stream<List<CategoryModel>> streamTopCategories({int limit = 5}) {
    return _firestore.collection('categories').limit(limit).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    });
  }
}
