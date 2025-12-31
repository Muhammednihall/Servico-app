import 'package:flutter/material.dart';
import 'category_pages.dart';
import 'user_profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;
  final Color _primaryColor = const Color(0xFF2463eb);
  final Color _backgroundLight = const Color(0xFFf6f6f8);

  static const List<Widget> _widgetOptions = <Widget>[
    CustomerHomeContent(),
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
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
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
          child: SizedBox(
            height: 64,
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
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
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

  final Color _primaryColor = const Color(0xFF2463eb);
  final Color _backgroundLight = const Color(0xFFf6f6f8);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 32),
                  _buildPromotions(context),
                  const SizedBox(height: 32),
                  _buildServiceCategories(context),
                  const SizedBox(height: 32),
                  _buildAboutServico(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 80),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFF2463eb), Color(0xFF0ea5e9)],
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 32,
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
                Text(
                  'City Service Finder',
                  style: TextStyle(
                    color: Color(0xFFbfdbfe),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Transform.translate(
      offset: const Offset(0, -40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade100,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.search,
                color: Colors.grey.shade400,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for services...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 176,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildPromoCard(
                width: constraints.maxWidth * 0.85,
                badge: 'LIMITED TIME',
                title: 'Get 20% off\ncleaning',
                subtitle: 'Book now for summer specials',
                gradient: const [Color(0xFF6366f1), Color(0xFF9333ea)],
              ),
              const SizedBox(width: 16),
              _buildPromoCard(
                width: constraints.maxWidth * 0.85,
                badge: 'URGENT CARE',
                title: 'Emergency Plumbers\n24/7 Service',
                subtitle: 'We arrive in under 30 mins',
                gradient: const [Color(0xFF2563eb), Color(0xFF06b6d4)],
              ),
              const SizedBox(width: 16),
              _buildPromoCard(
                width: constraints.maxWidth * 0.85,
                badge: 'NEW FEATURE',
                title: 'AI-Powered\nDiagnostics',
                subtitle: 'Identify issues with a photo',
                gradient: const [Color(0xFF10b981), Color(0xFF0d9488)],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromoCard({
    required double width,
    required String badge,
    required String title,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCategories(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Service Categories',
                style: TextStyle(
                  color: Color(0xFF1e293b),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildServiceCategory(
                context: context,
                icon: Icons.build,
                label: 'Electrician',
                color: _primaryColor,
                bgColor: const Color(0xFFeff6ff),
              ),
              _buildServiceCategory(
                context: context,
                icon: Icons.water_drop,
                label: 'Plumber',
                color: const Color(0xFF06b6d4),
                bgColor: const Color(0xFFecfeff),
              ),
              _buildServiceCategory(
                context: context,
                icon: Icons.carpenter,
                label: 'Carpenter',
                color: const Color(0xFFea580c),
                bgColor: const Color(0xFFfff7ed),
              ),
              _buildServiceCategory(
                context: context,
                icon: Icons.cleaning_services,
                label: 'Cleaning',
                color: const Color(0xFFa855f7),
                bgColor: const Color(0xFFfaf5ff),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade100,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.more_horiz,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Other Services',
                        style: TextStyle(
                          color: Color(0xFF1e293b),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gardening, Painting, Moving...',
                        style: TextStyle(
                          color: Color(0xFF64748b),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
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
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: () {
        Widget? categoryScreen;
        switch (label) {
          case 'Electrician':
            categoryScreen = const ElectricianListScreen();
            break;
          case 'Plumber':
            categoryScreen = const PlumberListScreen();
            break;
          case 'Carpenter':
            categoryScreen = const CarpenterListScreen();
            break;
          case 'Cleaning':
            categoryScreen = const CleaningListScreen();
            break;
          default:
            categoryScreen = const ElectricianListScreen();
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => categoryScreen!,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFeff6ff),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFdbeafe),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
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
              'Your AI-enabled city companion. We connect you with top-rated local professionals instantly, ensuring quality and trust.',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildAboutPoint('Fast & Easy Booking'),
            _buildAboutPoint('100% Verified Professionals'),
            _buildAboutPoint('Secure AI-Powered Payments'),
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
          const Icon(
            Icons.check_circle,
            color: Color(0xFF10b981),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1e293b),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
