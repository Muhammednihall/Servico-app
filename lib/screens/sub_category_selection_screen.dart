import 'package:flutter/material.dart';
import '../services/category_service.dart';
import 'category_pages.dart';
import '../widgets/modern_header.dart';

class SubCategorySelectionScreen extends StatelessWidget {
  final CategoryModel category;

  const SubCategorySelectionScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = category.getColor();
    final Color bgColor = primaryColor.withOpacity(0.08);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          ModernHeader(
            title: category.name,
            subtitle: 'Explore services in',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What kind of ${category.name.toLowerCase()} service do you need today?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: category.subcategories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildSubCategoryCard(
                          context,
                          'All',
                          category.getIconData(),
                          primaryColor,
                          bgColor,
                          isAll: true,
                        );
                      }

                      final sub = category.subcategories[index - 1];
                      return _buildSubCategoryCard(
                        context,
                        sub.name,
                        sub.getIconData(),
                        primaryColor,
                        bgColor,
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryCard(
    BuildContext context,
    String name,
    IconData icon,
    Color primaryColor,
    Color bgColor, {
    bool isAll = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryServiceScreen(
              categoryName: category.name,
              categoryIcon: category.getIconData(),
              categoryColor: primaryColor,
              categoryBgColor: bgColor,
              initialSubcategory: isAll ? null : name,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: primaryColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
