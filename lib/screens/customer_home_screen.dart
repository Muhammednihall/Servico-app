import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'sub_category_selection_screen.dart';
import 'gas_directory_screen.dart';
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
import 'temp_seed_screen.dart';

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

      // Start client-side notification sync (backup for Cloud Functions)
      NotificationService().startListeningToFirestoreNotifications(
        user.uid, 
        'customer',
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
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

          return SafeArea(
            bottom: true,
            child: Column(
              children: [
                ModernHeader(
                  title: _selectedIndex == 0
                      ? customerName
                      : (_selectedIndex == 1 ? 'My Bookings' : 'My Profile'),
                  subtitle: _selectedIndex == 0
                      ? 'Welcome back,'
                      : (_selectedIndex == 1
                          ? 'Track your service requests'
                          : 'Manage your account'),
                  showBackButton: false,
                  showNotifications: _selectedIndex == 0,
                ),
                Expanded(
                  child: PageView(
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
            ),
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
    _carouselSubscription = CarouselService().streamCarousel().listen((data) {
      if (mounted) {
        setState(() {
          _carousels = data;
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

              List<CategoryModel> allCategories = (snapshot.data ?? []).toList();

              if (allCategories.isEmpty) {
                return const Center(child: Text('No categories available'));
              }

              // Filter out unwanted categories
              final filteredCategories = allCategories.where((c) {
                final name = c.name.toLowerCase();
                return !name.contains('event') &&
                    !name.contains('decor') &&
                    name != 'health & wellness';
              }).toList();

              final priorityNames = [
                'Plumbing',
                'Electrical',
                'Cleaning',
              ];

              // Separate into Top (matches) and Bottom (nonMatches)
              List<CategoryModel> matches = filteredCategories.where((c) {
                final name = c.name.toLowerCase();
                return priorityNames.any((p) => name.contains(p.toLowerCase()));
              }).toList();

              List<CategoryModel> nonMatches = filteredCategories.where((c) {
                final name = c.name.toLowerCase();
                return !priorityNames.any((p) => name.contains(p.toLowerCase()));
              }).toList();

              // Sort the matches based on priorityNames
              matches.sort((a, b) {
                int aIdx = priorityNames.indexWhere(
                  (name) => a.name.toLowerCase().contains(name.toLowerCase()),
                );
                int bIdx = priorityNames.indexWhere(
                  (name) => b.name.toLowerCase().contains(name.toLowerCase()),
                );
                // Synthetic gas ('Gas') will get index 0
                return (aIdx == -1 ? 1000 : aIdx).compareTo(bIdx == -1 ? 1000 : bIdx);
              });

              final topCategories = matches.take(4).toList();
              final topIds = topCategories.map((c) => c.id).toSet();

              // Bottom categories are everything else (discarded matches + non-matches)
              final remainingMatches =
                  matches.where((c) => !topIds.contains(c.id)).toList();
              final bottomCategoriesFull = [...remainingMatches, ...nonMatches];
              
              // Deduplicate by name to prevent multiple records for same service (e.g. Painting)
              final seenNames = <String>{};
              final bottomCategories = bottomCategoriesFull.where((c) {
                return seenNames.add(c.name.toLowerCase());
              }).toList();

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
      padding: const EdgeInsets.all(16),
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
                    'Track Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2463EB),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
      return const SizedBox(height: 210);
    }

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: carousels.length,
          options: CarouselOptions(
            height: 210,
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
        Text(
          'Emergency services',
          style: Theme.of(context).textTheme.titleLarge,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: customIconAsset != null
                  ? Image.asset(
                      customIconAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          category.getIconData(),
                          color: category.getColor(),
                          size: 20,
                        );
                      },
                    )
                  : Icon(
                      category.getIconData(),
                      color: category.getColor(),
                      size: 20,
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
    final name = categoryName.toLowerCase();
    if (name.contains('laundry')) return 'assets/icon_laundry.png';
    if (name.contains('electric')) return 'assets/icon_electrical.png';
    if (name.contains('cleaning')) return 'assets/icon_cleaning.png';
    if (name.contains('plumbing') || name.contains('water')) {
      return 'assets/icon_plumbing.png';
    }
    if (name.contains('gas') || name.contains('cylinder') || name.contains('lpg') || name.contains('cooking') || name.contains('fire')) {
      return 'assets/icon_gas.png';
    }
    if (name.contains('paint')) return 'assets/icon_painting.png';
    if (name.contains('ac') || name.contains('hvac')) return 'assets/icon_ac.png';
    if (name.contains('security') || name.contains('lock')) return 'assets/icon_security.png';
    if (name.contains('garden') || name.contains('grass')) return 'assets/icon_gardening.png';
    if (name.contains('carpenter')) return 'assets/icon_carpentry.png';
    if (name.contains('furniture')) return 'assets/icon_furniture.png';
    if (name.contains('appliance')) return 'assets/icon_appliances.png';
    if (name.contains('automotive') || name.contains('car')) return 'assets/icon_automotive.png';
    if (name.contains('tire') || name.contains('tyre')) return 'assets/icon_tire_service.png';
    if (name.contains('wifi') || name.contains('router')) return 'assets/icon_wifi.png';
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
        Text('Other Services', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.94,
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
    final String? customIconAsset = _getCategoryIconAsset(category.name);

    return GestureDetector(
      onTap: () {
        if (category.name.toLowerCase() == 'gas') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GasDirectoryScreen(),
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SubCategorySelectionScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: customIconAsset != null
                  ? Image.asset(
                      customIconAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(icon, color: color, size: 24);
                      },
                    )
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF2463eb), size: 20),
              const SizedBox(width: 8),
              const Text(
                'About Servico',
                style: TextStyle(
                  color: Color(0xFF1e293b),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.grey, size: 18),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TempSeedScreen()),
                  );
                },
                tooltip: 'Developer Settings',
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
