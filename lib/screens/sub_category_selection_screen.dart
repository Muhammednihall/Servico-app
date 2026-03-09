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
    final String? customIconAsset = _getSubCategoryIconAsset(name, category.name);

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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(8), // Reduced padding to let the image be larger
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: customIconAsset != null
                  ? Image.asset(
                      customIconAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(icon, color: primaryColor, size: 32),
                    )
                  : Icon(icon, color: primaryColor, size: 32),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getSubCategoryIconAsset(String subName, String mainCategory) {
    debugPrint('DEBUG: Mapping subName: "$subName", mainCategory: "$mainCategory"');
    final subLower = subName.toLowerCase();
    final mainLower = mainCategory.toLowerCase();

    // Map subcategories to assets
    // If it's the "All" option, use the main category icon
    if (subLower == 'all') {
      if (mainLower.contains('laundry')) return 'assets/icon_laundry.png';
      if (mainLower.contains('electric')) return 'assets/icon_electrical.png';
      if (mainLower.contains('cleaning')) return 'assets/icon_cleaning.png';
      if (mainLower.contains('plumbing')) return 'assets/icon_plumbing.png';
      if (mainLower.contains('gas')) return 'assets/icon_gas.png';
      if (mainLower.contains('paint')) return 'assets/icon_painting.png';
      if (mainLower.contains('ac')) return 'assets/icon_ac.png';
      if (mainLower.contains('security')) return 'assets/icon_security.png';
      if (mainLower.contains('garden')) return 'assets/icon_gardening.png';
      if (mainLower.contains('carpenter')) return 'assets/icon_carpentry.png';
      if (mainLower.contains('furniture')) return 'assets/icon_furniture.png';
      if (mainLower.contains('appliance')) return 'assets/icon_appliances.png';
      if (mainLower.contains('automotive')) return 'assets/icon_automotive.png';
      if (mainLower.contains('wifi')) return 'assets/icon_wifi.png';
      if (mainLower.contains('pest')) return 'assets/icon_pest_control.png';
    }

    // Automotive specific matches
    if (subLower.contains('wash') || subLower.contains('clean')) return 'assets/icon_car_wash.png';
    if (subLower.contains('tire') || subLower.contains('tyre') || subLower.contains('wheel') || subLower.contains('alignment')) return 'assets/icon_tire_service.png';
    if (subLower.contains('engine') || subLower.contains('oil') || subLower.contains('mechanic') || subLower.contains('repair')) return 'assets/icon_engine_repair.png';
    if (subLower.contains('battery') || subLower.contains('electrical') || subLower.contains('power')) return 'assets/icon_battery_service.png';
    if (subLower.contains('bike') || subLower.contains('motorcycle') || subLower.contains('two wheeler')) return 'assets/icon_bike_service.png';

    // General subcategory keyword matches
    if (subLower.contains('ac') || subLower.contains('air')) return 'assets/icon_ac.png';
    if (subLower.contains('paint')) return 'assets/icon_painting.png';
    if (subLower.contains('plumbing') || subLower.contains('pipe')) return 'assets/icon_plumbing.png';
    if (subLower.contains('electric')) return 'assets/icon_electrical.png';
    if (subLower.contains('furniture')) return 'assets/icon_furniture.png';
    if (subLower.contains('garden')) return 'assets/icon_gardening.png';
    if (subLower.contains('automotive') || subLower.contains('car')) return 'assets/icon_automotive.png';
    if (subLower.contains('appliance') || subLower.contains('fridge') || subLower.contains('oven')) return 'assets/icon_appliances.png';
    if (subLower.contains('lock') || subLower.contains('security')) return 'assets/icon_security.png';
    if (subLower.contains('pest')) return 'assets/icon_pest_control.png';
    if (subLower.contains('wifi') || subLower.contains('internet')) return 'assets/icon_wifi.png';

    // Default to main category icon if no specific subcategory match
    if (mainLower.contains('laundry')) return 'assets/icon_laundry.png';
    if (mainLower.contains('electric')) return 'assets/icon_electrical.png';
    if (mainLower.contains('cleaning')) return 'assets/icon_cleaning.png';
    if (mainLower.contains('plumbing')) return 'assets/icon_plumbing.png';
    if (mainLower.contains('gas')) return 'assets/icon_gas.png';
    if (mainLower.contains('paint')) return 'assets/icon_painting.png';
    if (mainLower.contains('ac')) return 'assets/icon_ac.png';
    if (mainLower.contains('security')) return 'assets/icon_security.png';
    if (mainLower.contains('garden')) return 'assets/icon_gardening.png';
    if (mainLower.contains('carpenter')) return 'assets/icon_carpentry.png';
    if (mainLower.contains('furniture')) return 'assets/icon_furniture.png';
    if (mainLower.contains('appliance')) return 'assets/icon_appliances.png';
    if (mainLower.contains('automotive')) return 'assets/icon_automotive.png';
    if (mainLower.contains('wifi')) return 'assets/icon_wifi.png';
    if (mainLower.contains('pest')) return 'assets/icon_pest_control.png';

    return null;
  }
}
