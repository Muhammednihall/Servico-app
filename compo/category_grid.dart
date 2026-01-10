import 'package:flutter/material.dart';
import '../../../models/category_model.dart';
import '../../../widgets/cards/category_card.dart';
import '../../../config/app_theme.dart';
import '../../../screens/emergency/emergency_categories_screen.dart';
import '../../../screens/shops/shop_categories_screen.dart';
import '../../../main.dart' show languageProvider;

class CategoryGrid extends StatefulWidget {
  const CategoryGrid({Key? key}) : super(key: key);

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  @override
  Widget build(BuildContext context) {
    // For now, we'll use hardcoded categories
    // In a real app, these would come from Firebase
    final List<CategoryModel> categories = [
      CategoryModel(
        id: '1',
        name: 'Emergency',
        nameMalayalam: 'അടിയന്തരം',
        imageUrl: 'assets/icons/emergency.png',
        collectionName: 'Emergencycategories',
      ),
      CategoryModel(
        id: '2',
        name: 'Shops',
        nameMalayalam: 'കടകൾ',
        imageUrl: 'assets/icons/shops.png',
        collectionName: 'Shopcategories',
      ),
      CategoryModel(
        id: '3',
        name: 'Services',
        nameMalayalam: 'സേവനങ്ങൾ',
        imageUrl: 'assets/icons/services.png',
        collectionName: 'Servicecategories',
      ),
      CategoryModel(
        id: '4',
        name: 'Healthcare',
        nameMalayalam: 'ആരോഗ്യം',
        imageUrl: 'assets/icons/hospitals.png',
        collectionName: 'Hospitalcategories',
      ),
      CategoryModel(
        id: '5',
        name: 'Transportation',
        nameMalayalam: 'ഗതാഗതം',
        imageUrl: 'assets/icons/taxis.png',
        collectionName: 'Taxicategories',
      ),
      CategoryModel(
        id: '6',
        name: 'Workers',
        nameMalayalam: 'തൊഴിലാളികൾ',
        imageUrl: 'assets/icons/workers.png',
        collectionName: 'Workerscategories',
      ),
      CategoryModel(
        id: '7',
        name: 'Institutions',
        nameMalayalam: 'സ്ഥാപനങ്ങൾ',
        imageUrl: 'assets/icons/institutions.png',
        collectionName: 'Institutioncategories',
      ),
      CategoryModel(
        id: '8',
        name: 'Offers',
        nameMalayalam: 'വിലക്കുറവുകൾ',
        imageUrl: 'assets/icons/offers.png',
        collectionName: 'Offersdetails',
      ),
      CategoryModel(
        id: '9',
        name: 'Leaders',
        nameMalayalam: 'നേതാക്കൾ',
        imageUrl: 'assets/icons/leaders.png',
        collectionName: 'Leadersdetails',
      ),
      CategoryModel(
        id: '10',
        name: 'Best Line',
        nameMalayalam: 'ബെസ്റ്റ് ലൈൻ',
        imageUrl: 'assets/icons/bestline.png',
        collectionName: 'Bestlinecategories',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageProvider.getText('categories'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Navigate to the appropriate category screen
                  _navigateToCategoryScreen(context, categories[index]);
                },
                child: CategoryCard(category: categories[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToCategoryScreen(BuildContext context, CategoryModel category) {
    switch (category.collectionName) {
      case 'Emergencycategories':
        Navigator.push(context, AppTheme.createRoute(const EmergencyCategoriesScreen()));
        break;
      case 'Shopcategories':
        Navigator.push(context, AppTheme.createRoute(const ShopCategoriesScreen()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to ${category.name}'),
            duration: const Duration(seconds: 1),
          ),
        );
    }
  }
}