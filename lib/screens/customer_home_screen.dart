import 'package:flutter/material.dart';
import 'sub_category_selection_screen.dart';
import 'user_profile_screen.dart';
import 'customer_bookings_screen.dart';
import '../services/category_service.dart';
import '../services/carousel_service.dart';
import '../widgets/weather_widget.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;
  final Color _primaryColor = const Color(0xFF2463eb);

  static const List<Widget> _widgetOptions = <Widget>[
    CustomerHomeContent(),
    CustomerBookingsScreen(),
    UserProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_repair_service,
                  label: 'Home',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
                _buildNavItem(
                  icon: Icons.assignment_outlined,
                  label: 'Bookings',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? _primaryColor : Colors.grey.shade400,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? _primaryColor : Colors.grey.shade400,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerHomeContent extends StatelessWidget {
  const CustomerHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<List<CategoryModel>>(
            stream: CategoryService().streamCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allCategories = snapshot.data ?? [];

              // Calculate Top Categories (Emergency & Daily)
              final priorityNames = [
                'Water',
                'Gas',
                'Electricity',
                'Cleaning',
                'Plumbing',
                'Electrical',
              ];

              final sortedForTop = [...allCategories];
              sortedForTop.sort((a, b) {
                int aIdx = priorityNames.indexWhere(
                  (name) => a.name.toLowerCase().contains(name.toLowerCase()),
                );
                int bIdx = priorityNames.indexWhere(
                  (name) => b.name.toLowerCase().contains(name.toLowerCase()),
                );
                if (aIdx == -1) aIdx = 1000;
                if (bIdx == -1) bIdx = 1000;
                return aIdx.compareTo(bIdx);
              });

              final topCategories = sortedForTop.take(4).toList();
              final topIds = topCategories.map((c) => c.id).toSet();

              // Calculate Bottom Categories (Filtered & Non-Duplicate)
              final bottomCategories = allCategories
                  .where(
                    (c) =>
                        c.name != 'Health & Wellness' && !topIds.contains(c.id),
                  )
                  .toList();

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 16),
                    _buildPromotions(context),
                    const SizedBox(height: 20),
                    _buildTopCategories(context, topCategories),
                    const SizedBox(height: 24),
                    _buildServiceCategories(context, bottomCategories),
                    const SizedBox(height: 24),
                    const WeatherWidget(),
                    const SizedBox(height: 20),
                    _buildAboutServico(),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFF2463eb), Color(0xFF0ea5e9)],
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.home_repair_service,
                      color: Color(0xFF2463eb),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Servico',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for services...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotions(BuildContext context) {
    return StreamBuilder<List<CarouselModel>>(
      stream: CarouselService().streamCarousel(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 176,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final carousels = snapshot.data ?? [];
        if (carousels.isEmpty) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: carousels.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final carousel = carousels[index];
                  return Container(
                    width: constraints.maxWidth * 0.85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        carousel.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopCategories(
    BuildContext context,
    List<CategoryModel> categories,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency & Daily Services',
            style: TextStyle(
              color: Color(0xFF1e293b),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: categories.asMap().entries.map((entry) {
              final index = entry.key;
              final cat = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < categories.length - 1 ? 8 : 0,
                  ),
                  child: _buildTopCategoryCard(context: context, category: cat),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoryCard({
    required BuildContext context,
    required CategoryModel category,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SubCategorySelectionScreen(category: category),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: category.getColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                category.getIconData(),
                color: category.getColor(),
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategories(
    BuildContext context,
    List<CategoryModel> categories,
  ) {
    final displayCategories = categories.take(9).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Categories',
            style: TextStyle(
              color: Color(0xFF1e293b),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.88,
            ),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final cat = displayCategories[index];
              return _buildServiceCategory(
                context: context,
                icon: cat.getIconData(),
                label: cat.name,
                color: cat.getColor(),
                category: cat,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCategory({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required CategoryModel category,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SubCategorySelectionScreen(category: category),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutServico() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFeff6ff),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFdbeafe), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2463eb), size: 20),
                SizedBox(width: 8),
                Text(
                  'About Servico',
                  style: TextStyle(
                    color: Color(0xFF1e293b),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Your AI-enabled city companion. We connect you with top-rated local professionals instantly.',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildAboutPoint('Fast & Easy Booking'),
            _buildAboutPoint('100% Verified Professionals'),
            _buildAboutPoint('Secure Payments'),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF1e293b), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
