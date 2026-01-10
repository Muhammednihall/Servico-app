import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/taxi_service.dart';
import '../../widgets/cards/category_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../categories/generic_detail_screen.dart';

class TransportCategoriesScreen extends StatefulWidget {
  const TransportCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<TransportCategoriesScreen> createState() => _TransportCategoriesScreenState();
}

class _TransportCategoriesScreenState extends State<TransportCategoriesScreen> {
  final TaxiService _taxiService = TaxiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transportation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _taxiService.getTaxiCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(
              isLoading: true,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return CustomErrorWidget(
              errorMessage: 'Failed to load transport categories',
              onRetry: () => setState(() {}), // Rebuild to retry
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              title: 'No Transport Categories',
              message: 'There are no transport categories available at the moment.',
              icon: Icons.directions_car,
              onRetry: () => setState(() {}), // Rebuild to retry
            );
          }

          final categories = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Navigate to the detail screen for this category
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenericDetailScreen(category: categories[index]),
                      ),
                    );
                  },
                  child: CategoryCard(category: categories[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}