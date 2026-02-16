import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'sub_category_selection_screen.dart';
import 'user_profile_screen.dart';
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
import '../services/user_service.dart';
import 'customer_bookings_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Cache these so they aren't recreated on every build
  late final List<Widget> _pages;
  Stream<Map<String, dynamic>?>? _userProfileStream;

  @override
  void initState() {
    super.initState();
    _registerFcmToken();
    _pages = [
      CustomerHomeContent(onNavigate: _onItemTapped),
      const CustomerBookingsScreen(),
      const UserProfileScreen(),
    ];

    // Cache the user profile stream
    final user = _authService.getCurrentUser();
    final customerId = user?.uid ?? '';
    if (customerId.isNotEmpty) {
      _userProfileStream = UserService().streamUserProfile(customerId);
    }
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
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _userProfileStream,
        builder: (context, userSnapshot) {
          final customerName = userSnapshot.data?['name'] ?? 'User';

          return Column(
            children: [
              if (_selectedIndex < 2)
                ModernHeader(
                  title: _selectedIndex == 0 ? customerName : 'My Bookings',
                  subtitle: _selectedIndex == 0
                      ? 'Welcome back,'
                      : 'Track your service requests',
                  showBackButton: false,
                  showNotifications: _selectedIndex == 0,
                ),
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  children: _pages,
                ),
              ),
            ],
          );
        },
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
      return CustomerNotificationPopup(customerId: customerId, child: scaffold);
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
  int _currentPromo = 0;
  String? _currentAddress;
  bool _isLoadingLocation = false;
  List<CarouselModel> _carousels = [];
  StreamSubscription? _carouselSubscription;
  final CarouselSliderController _carouselController = CarouselSliderController();

  // Cache streams so they aren't recreated on every build/setState
  late final Stream<List<CategoryModel>> _categoryStream;

  @override
  void initState() {
    super.initState();
    _categoryStream = CategoryService().streamCategories();
    _fetchLocation();
    _loadCarousels();
  }

  /// Load carousels from Firestore via a subscription (outside of build)
  void _loadCarousels() {
    final fallbackCarousels = [
      CarouselModel(
        id: '1',
        imageUrl:
            'https://images.unsplash.com/photo-1621905235292-0ba5476d6209?auto=format&fit=crop&q=80&w=800',
        order: 1,
      ),
      CarouselModel(
        id: '2',
        imageUrl:
            'https://images.unsplash.com/photo-1581578731548-c64695cc6954?auto=format&fit=crop&q=80&w=800',
        order: 2,
      ),
      CarouselModel(
        id: '3',
        imageUrl:
            'https://images.unsplash.com/photo-1556911220-e150213b1a3e?auto=format&fit=crop&q=80&w=800',
        order: 3,
      ),
    ];

    _carousels = fallbackCarousels;

    _carouselSubscription = CarouselService().streamCarousel().listen((data) {
      if (mounted) {
        final newCarousels = data.isNotEmpty ? data : fallbackCarousels;
        setState(() {
          _carousels = newCarousels;
        });
      }
    });
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
    _carouselSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<CategoryModel>>(
            stream: _categoryStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allCategories = snapshot.data ?? [];
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
                return (aIdx == -1 ? 1000 : aIdx).compareTo(
                  bIdx == -1 ? 1000 : bIdx,
                );
              });

              final topCategories = sortedForTop.take(4).toList();
              final topIds = topCategories.map((c) => c.id).toSet();
              final bottomCategories = allCategories
                  .where(
                    (c) =>
                        c.name != 'Health & Wellness' && !topIds.contains(c.id),
                  )
                  .toList();

              return RefreshIndicator(
                onRefresh: () async =>
                    await Future.delayed(const Duration(seconds: 1)),
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 8,
                    bottom: 100,
                  ),
                  children: [
                    _buildPromotions(context),
                    const SizedBox(height: 24),
                    _buildQuickActionCard(context),
                    const SizedBox(height: 28),
                    _buildTopCategories(context, topCategories),
                    const SizedBox(height: 28),
                    _buildServiceCategories(context, bottomCategories),
                    const SizedBox(height: 28),
                    const WeatherWidget(),
                    const SizedBox(height: 28),
                    _buildAboutServico(),
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
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.blue.shade300,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Text(
                          _isLoadingLocation
                              ? 'Fetching location...'
                              : (_currentAddress ?? 'Fetching location...'),
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
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 30,
                ),
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
                      MaterialPageRoute(
                        builder: (context) => const TrackOrderScreen(),
                      ),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.my_location_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          const SizedBox(width: 8),
                          const Text(
                            'Change Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
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
    final carousels = _carousels;

    if (carousels.isEmpty) {
      return const SizedBox(height: 240);
    }

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: carousels.length,
          options: CarouselOptions(
            height: 240,
            viewportFraction: 0.9,
            enlargeCenterPage: true,
            enlargeFactor: 0.15,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 500),
            autoPlayCurve: Curves.easeInOut,
            pauseAutoPlayOnTouch: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentPromo = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final carousel = carousels[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SizedBox.expand(
                      child: Image.network(
                        carousel.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImagePlaceholder(),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.25),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carousels.length,
            (index) => GestureDetector(
              onTap: () => _carouselController.animateToPage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentPromo == index ? 28 : 6,
                decoration: BoxDecoration(
                  color: _currentPromo == index
                      ? const Color(0xFF2463EB)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Image missing',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
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
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 16),
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
    // Map category names to 3D icon assets
    final String? customIconAsset = _getCategoryIconAsset(category.name);

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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: customIconAsset != null
                    ? Colors.transparent
                    : category.getColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: customIconAsset != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        customIconAsset,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(
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

  // ... (existing grid _buildServiceCategory code) ...

  /// Returns the asset path for categories that have custom 3D icons
  String? _getCategoryIconAsset(String categoryName) {
    if (categoryName.toLowerCase().contains('laundry')) {
      return 'assets/icon_laundry.png';
    }
    return null;
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
            Text('For you', style: Theme.of(context).textTheme.titleLarge),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 16),
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
    // Map category names to 3D icon assets (lowercase for matching)
    final String? customIconAsset = _getCategoryIconAsset(category.name);

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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: customIconAsset != null
                    ? Colors.transparent
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: customIconAsset != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        customIconAsset,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
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
