import 'package:flutter/material.dart';
import '../services/category_service.dart';
import 'category_pages.dart';

class SubCategorySelectionScreen extends StatelessWidget {
  final CategoryModel category;

  const SubCategorySelectionScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = category.getColor();
    final Color bgColor = primaryColor.withOpacity(0.05);

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, primaryColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What kind of ${category.name.toLowerCase()} service do you need?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1e293b),
                      letterSpacing: -0.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a sub-category to find the right professional for your needs.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                // Add an "All" option at the beginning
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
              }, childCount: category.subcategories.length + 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          category.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Pattern or Image
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                ),
              ),
            ),
            // Decorative Icon
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                category.getIconData(),
                size: 180,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ],
        ),
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
        // Navigate to CategoryServiceScreen with the selected subcategory
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: primaryColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
