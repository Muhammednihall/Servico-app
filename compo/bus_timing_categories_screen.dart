import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/cards/category_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../categories/generic_detail_screen.dart';
import '../../routes/app_routes.dart';
import '../../main.dart' show languageProvider, themeProvider, primary, primaryGradient;

class BusTimingCategoriesScreen extends StatefulWidget {
  const BusTimingCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<BusTimingCategoriesScreen> createState() => _BusTimingCategoriesScreenState();
}

class _BusTimingCategoriesScreenState extends State<BusTimingCategoriesScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getText('bus_timings')),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _firebaseService.getCategories('Bustimecategories'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(
              isLoading: true,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return CustomErrorWidget(
              errorMessage: 'Failed to load bus timing categories: ${snapshot.error}',
              onRetry: () => setState(() {}), // Rebuild to retry
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              title: languageProvider.getText('no_categories'),
              message: languageProvider.getText('no_bus_timing_categories'),
              icon: Icons.directions_bus,
              onRetry: () => setState(() {}), // Rebuild to retry
            );
          }

          final categories = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Navigate to the detail screen for this category
                  try {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.genericCategory,
                      arguments: {
                        'title': categories[index].name,
                        'collectionName': 'Bustimedetails',
                        'mainCategoryId': categories[index].id,
                      },
                    ).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to open category: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Navigation error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: CategoryCard(category: categories[index]),
              );
            },
          );
        },
      ),
    );
  }
}