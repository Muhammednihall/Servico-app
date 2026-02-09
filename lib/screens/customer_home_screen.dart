import 'package:flutter/material.dart';
import 'sub_category_selection_screen.dart';
import 'user_profile_screen.dart';
import 'customer_bookings_screen.dart';
import 'track_order_screen.dart';
import '../services/category_service.dart';
import '../services/carousel_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/weather_widget.dart';
import '../widgets/modern_header.dart';
import '../widgets/modern_nav_bar.dart';
import '../widgets/customer_notification_popup.dart';
import '../services/location_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  List<Widget> _widgetOptions(Function(int) onNavigate) => [
    CustomerHomeContent(onNavigate: onNavigate),
    const CustomerBookingsScreen(),
    const UserProfileScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    _registerFcmToken();
  }
  
  /// Register FCM token for push notifications
  Future<void> _registerFcmToken() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      await NotificationService().getAndSaveToken(
        userId: user.uid,
        userType: 'customer',
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    final customerId = user?.uid ?? '';
    
    // Wrap with notification popup only if user is logged in
    Widget scaffold = Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions(_onItemTapped),
      ),
      bottomNavigationBar: ModernNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        items: [
          NavItem(Icons.home_rounded, 'Home'),
          NavItem(Icons.assignment_rounded, 'Bookings'),
          NavItem(Icons.person_rounded, 'Profile'),
        ],
      ),
    );
    
    // Only wrap with notification popup if user is logged in
    if (customerId.isNotEmpty) {
      return CustomerNotificationPopup(
        customerId: customerId,
        child: scaffold,
      );
    }
    
    return scaffold;
  }

}

class CustomerHomeContent extends StatefulWidget {
  final Function(int)? onNavigate;
  const CustomerHomeContent({super.key, this.onNavigate});

  @override
  State<CustomerHomeContent> createState() => _CustomerHomeContentState();
}

class _CustomerHomeContentState extends State<CustomerHomeContent> {
  final PageController _promoController = PageController();
  int _currentPromo = 0;
  String? _currentAddress;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation({bool force = false}) async {
    if (force) {
      LocationService().clearCache();
    }
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final address = await LocationService().getCurrentAddress();
      if (mounted) {
        setState(() {
          _currentAddress = address ?? 'Location not available';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Error getting location';
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModernHeader(
          title: 'Find Top Services',
          subtitle: 'Welcome back, User 👋',
          actions: [],
        ),
        Expanded(
          child: StreamBuilder<List<CategoryModel>>(
            stream: CategoryService().streamCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allCategories = snapshot.data ?? [];
              final priorityNames = ['Water', 'Gas', 'Electricity', 'Cleaning', 'Plumbing', 'Electrical'];
              final sortedForTop = [...allCategories];
              sortedForTop.sort((a, b) {
                int aIdx = priorityNames.indexWhere((name) => a.name.toLowerCase().contains(name.toLowerCase()));
                int bIdx = priorityNames.indexWhere((name) => b.name.toLowerCase().contains(name.toLowerCase()));
                return (aIdx == -1 ? 1000 : aIdx).compareTo(bIdx == -1 ? 1000 : bIdx);
              });

              final topCategories = sortedForTop.take(4).toList();
              final topIds = topCategories.map((c) => c.id).toSet();
              final bottomCategories = allCategories.where((c) => c.name != 'Health & Wellness' && !topIds.contains(c.id)).toList();

              return RefreshIndicator(
                onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  children: [
                    _buildPromotions(context),
                    const SizedBox(height: 32),
                    _buildQuickActionCard(context),
                    const SizedBox(height: 32),
                    _buildTopCategories(context, topCategories),
                    const SizedBox(height: 32),
                    _buildServiceCategories(context, bottomCategories),
                    const SizedBox(height: 32),
                    const WeatherWidget(),
                    const SizedBox(height: 32),
                    _buildAboutServico(),
                    const SizedBox(height: 120),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instant Service',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track Order',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.blue.shade300, size: 14),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Text(
                          _isLoadingLocation ? 'Fetching location...' : (_currentAddress ?? 'Fetching location...'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2463EB),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TrackOrderScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Track Order',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _fetchLocation(force: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoadingLocation)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.my_location_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 8),
                          const Text(
                            'Change Location',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final carousels = snapshot.data ?? [];
        if (carousels.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SizedBox(
              height: 176,
              child: PageView.builder(
                controller: _promoController,
                itemCount: carousels.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPromo = index;
                  });
                },
                itemBuilder: (context, index) {
                  final carousel = carousels[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
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
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                carousels.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentPromo == index ? 20 : 6,
                  decoration: BoxDecoration(
                    color: _currentPromo == index ? const Color(0xFF2463EB) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopCategories(
    BuildContext context,
    List<CategoryModel> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Emergency services',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: categories.asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < categories.length - 1 ? 12 : 0,
                ),
                child: _buildTopCategoryCard(context: context, category: cat),
              ),
            );
          }).toList(),
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'For you',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
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
            builder: (context) => SubCategorySelectionScreen(category: category),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
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
