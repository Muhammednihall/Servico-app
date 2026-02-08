import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'booking_request_screen.dart';
import 'worker_public_profile_screen.dart';
import '../services/worker_service.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../widgets/modern_header.dart';

class SubCategoryModel {
  final String name;
  final IconData icon;

  const SubCategoryModel({required this.name, required this.icon});
}

class CategoryServiceScreen extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final Color categoryBgColor;
  final List<SubCategoryModel> subcategories;
  final String? initialSubcategory;

  const CategoryServiceScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.categoryBgColor,
    this.subcategories = const [],
    this.initialSubcategory,
  });

  @override
  State<CategoryServiceScreen> createState() => _CategoryServiceScreenState();
}

class _CategoryServiceScreenState extends State<CategoryServiceScreen> {
  final Color _primaryColor = const Color(0xFF2463eb);
  final Color _backgroundLight = const Color(0xFFf6f6f8);
  final WorkerService _workerService = WorkerService();
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();

  List<Map<String, dynamic>> _allWorkers = [];
  List<Map<String, dynamic>> _filteredWorkers = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String? _selectedSubcategory;

  @override
  void initState() {
    super.initState();
    _selectedSubcategory = widget.initialSubcategory;
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final workers = await _workerService.getWorkersByCategory(
        widget.categoryName,
      );

      setState(() {
        _allWorkers = workers;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      Iterable<Map<String, dynamic>> workers = _allWorkers;

      if (_selectedSubcategory != null && _selectedSubcategory != 'All') {
        workers = workers.where((worker) {
          final workerSubcategory = worker['subcategory'] as String? ?? '';
          return workerSubcategory.toLowerCase() ==
              _selectedSubcategory!.toLowerCase();
        });
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        workers = workers.where((worker) {
          final name = (worker['name'] as String? ?? '').toLowerCase();
          final sub = (worker['subcategory'] as String? ?? '').toLowerCase();
          final bio = (worker['bio'] as String? ?? '').toLowerCase();
          final service = (worker['serviceType'] as String? ?? '')
              .toLowerCase();
          return name.contains(query) ||
              sub.contains(query) ||
              bio.contains(query) ||
              service.contains(query);
        });
      }

      List<Map<String, dynamic>> workersList = workers.toList();

      if (_selectedFilter == 'Rating 4.0+') {
        workersList = workersList.where((worker) {
          final rating = (worker['rating'] as num?)?.toDouble() ?? 0.0;
          return rating >= 4.0;
        }).toList();
        workersList.sort(
          (a, b) => (b['rating'] as num).compareTo(a['rating'] as num),
        );
      } else if (_selectedFilter == 'Availability') {
        workersList = workersList.where((worker) {
          return worker['isAvailable'] == true;
        }).toList();
      } else if (_selectedFilter == 'Price: Low to High') {
        workersList.sort(
          (a, b) => (a['hourlyRate'] as num).compareTo(b['hourlyRate'] as num),
        );
      }

      _filteredWorkers = workersList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilters(),
          Expanded(child: _buildServiceList(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ModernHeader(
      title: _selectedSubcategory ?? widget.categoryName,
      subtitle: _selectedSubcategory != null ? widget.categoryName : 'Service Provider',
      showBackButton: true,
      bottom: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _applyFilters();
                },
                decoration: const InputDecoration(
                  hintText: 'Search for specialists...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Rating 4.0+'),
            const SizedBox(width: 12),
            _buildFilterChip('Price: Low to High'),
            const SizedBox(width: 12),
            _buildFilterChip('Availability'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = isSelected ? 'All' : label;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _primaryColor.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _primaryColor : Colors.grey.shade700,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: isSelected ? _primaryColor : Colors.grey.shade500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceList(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Error loading workers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadWorkers, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_filteredWorkers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No ${widget.categoryName} workers found',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredWorkers.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(context, _filteredWorkers[index]);
      },
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> worker) {
    final name = worker['name'] ?? 'Unknown';
    final rating = (worker['rating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews = worker['totalReviews'] ?? 0;
    final experience = worker['experience'] ?? '0';
    final isAvailable = worker['isAvailable'] ?? false;
    final price = (worker['price'] as num?)?.toDouble() ?? 250.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerPublicProfileScreen(worker: worker),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: widget.categoryBgColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          widget.categoryIcon,
                          size: 36,
                          color: widget.categoryColor,
                        ),
                      ),
                      if (isAvailable)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '₹${price.toInt()}/hr',
                                style: TextStyle(
                                  color: widget.categoryColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($totalReviews reviews)',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              '$experience yrs exp',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildInfoBadge(Icons.verified_user_outlined, 'Verified', Colors.blue),
                            _buildInfoBadge(Icons.timer_outlined, 'Quick Response', Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkerPublicProfileScreen(worker: worker),
                        ),
                      );
                    },
                    child: Text(
                      'Profile',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () => _handleBooking(worker),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.categoryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Future<void> _handleBooking(Map<String, dynamic> worker) async {
    final workerId = worker['id'] ?? worker['uid'] ?? '';
    
    // First check if worker is currently busy
    final currentBooking = await _workerService.getWorkerCurrentBooking(workerId);
    
    if (currentBooking != null) {
      // Worker is busy - show token booking dialog
      if (mounted) {
        final tokenResult = await _showTokenBookingDialog(context, worker, currentBooking);
        if (tokenResult == true) {
          await _createTokenBooking(worker);
        }
      }
      return;
    }
    
    // Worker is available - proceed with normal booking
    await _createNormalBooking(worker);
  }

  Future<void> _createNormalBooking(Map<String, dynamic> worker) async {
    try {
      final bookingData = await _showBookingPicker(context, worker);
      if (bookingData == null) return;

      final int duration = bookingData['hours'];
      final TimeOfDay selectedTime = bookingData['time'];
      final DateTime selectedDate = bookingData['date'];

      final scheduledDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final user = _authService.getCurrentUser();
      String? customerName;
      String? customerAddress;
      Map<String, double>? customerCoordinates;

      // Get customer data and location in parallel
      if (user != null) {
        final results = await Future.wait([
          FirebaseFirestore.instance.collection('customers').doc(user.uid).get(),
          _locationService.getCoordinatesMap(),
          _locationService.getCurrentAddress(),
        ]);

        final customerDoc = results[0] as DocumentSnapshot;
        customerCoordinates = results[1] as Map<String, double>?;
        final locationAddress = results[2] as String?;

        if (customerDoc.exists) {
          customerName = customerDoc.data() is Map ? (customerDoc.data() as Map)['name'] : null;
          // Use location-based address if available, otherwise use stored address
          customerAddress = locationAddress ?? (customerDoc.data() is Map ? (customerDoc.data() as Map)['address'] : null);
        } else {
          customerAddress = locationAddress;
        }
      }

      final pricePerHr = (worker['price'] as num?)?.toDouble() ?? 250.0;
      final requestId = await _bookingService.createBookingRequest(
        workerId: worker['id'] ?? worker['uid'] ?? '',
        workerName: worker['name'] ?? 'Worker',
        serviceName: widget.categoryName,
        price: pricePerHr * duration,
        duration: duration,
        customerId: user?.uid,
        customerName: customerName,
        customerAddress: customerAddress,
        customerCoordinates: customerCoordinates,
        startTime: scheduledDateTime,
      );

      if (mounted) Navigator.pop(context); // Dismiss loading

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingRequestScreen(requestId: requestId),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show token booking dialog when worker is busy
  Future<bool?> _showTokenBookingDialog(
    BuildContext context, 
    Map<String, dynamic> worker,
    Map<String, dynamic> currentBooking,
  ) async {
    final workerId = worker['id'] ?? worker['uid'] ?? '';
    final queueCount = await _workerService.getTokenQueueCount(workerId);
    final tokenPosition = queueCount + 1;
    
    // Calculate estimated end time of current job
    DateTime currentJobEnd = DateTime.now().add(const Duration(hours: 1));
    if (currentBooking['startTime'] != null) {
      final startTime = (currentBooking['startTime'] as dynamic).toDate();
      final duration = currentBooking['duration'] ?? 1;
      currentJobEnd = startTime.add(Duration(hours: duration));
    }
    
    // Add queue time
    final estimatedStart = currentJobEnd.add(Duration(hours: queueCount));

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Warning icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: Color(0xFFF97316),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            const Text(
              'Worker Currently Busy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              '${worker['name']} is working on another job',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // Current job info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.work_outline_rounded, 
                    'Current Job', 
                    currentBooking['serviceName'] ?? 'Service',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.access_time_rounded, 
                    'Estimated Free At', 
                    _formatTime(currentJobEnd),
                  ),
                  if (queueCount > 0) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.people_outline_rounded, 
                      'Queue', 
                      '$queueCount waiting',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Token booking card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2463EB), Color(0xFF1E40AF)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.confirmation_num_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Token #$tokenPosition',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Estimated start: ${_formatTime(estimatedStart)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.confirmation_num_rounded, size: 20),
                    label: const Text(
                      'Book Token',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2463eb).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2463eb), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF1E293B) : Colors.grey.shade400,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _createTokenBooking(Map<String, dynamic> worker) async {
    try {
      final bookingData = await _showBookingPicker(context, worker);
      if (bookingData == null) return;

      final int duration = bookingData['hours'];
      final workerId = worker['id'] ?? worker['uid'] ?? '';

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final user = _authService.getCurrentUser();
      String? customerName;
      String? customerAddress;
      Map<String, double>? customerCoordinates;

      // Get customer data and location
      if (user != null) {
        final results = await Future.wait([
          FirebaseFirestore.instance.collection('customers').doc(user.uid).get(),
          _locationService.getCoordinatesMap(),
          _locationService.getCurrentAddress(),
        ]);

        final customerDoc = results[0] as DocumentSnapshot;
        customerCoordinates = results[1] as Map<String, double>?;
        final locationAddress = results[2] as String?;

        if (customerDoc.exists) {
          customerName = customerDoc.data() is Map ? (customerDoc.data() as Map)['name'] : null;
          customerAddress = locationAddress ?? (customerDoc.data() is Map ? (customerDoc.data() as Map)['address'] : null);
        } else {
          customerAddress = locationAddress;
        }
      }

      // Get queue position and estimated start
      final queueCount = await _workerService.getTokenQueueCount(workerId);
      final tokenPosition = queueCount + 1;
      final estimatedStart = await _workerService.getEstimatedStartTime(workerId, duration);

      final pricePerHr = (worker['price'] as num?)?.toDouble() ?? 250.0;
      final requestId = await _bookingService.createBookingRequest(
        workerId: workerId,
        workerName: worker['name'] ?? 'Worker',
        serviceName: widget.categoryName,
        price: pricePerHr * duration,
        duration: duration,
        customerId: user?.uid,
        customerName: customerName,
        customerAddress: customerAddress,
        customerCoordinates: customerCoordinates,
        isTokenBooking: true,
        tokenPosition: tokenPosition,
        estimatedStartTime: estimatedStart,
      );

      if (mounted) Navigator.pop(context); // Dismiss loading

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Token #$tokenPosition booked! Estimated: ${_formatTime(estimatedStart)}'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Navigate to booking screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingRequestScreen(requestId: requestId),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showBookingPicker(BuildContext context, Map<String, dynamic> worker) async {
    int selectedHours = 1;
    DateTime? selectedDate = DateTime.now();
    TimeOfDay? selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    final pricePerHour = (worker['price'] as num?)?.toDouble() ?? 250.0;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final bool canConfirm = selectedTime != null && selectedDate != null && selectedHours > 0;
          final double totalPrice = pricePerHour * selectedHours;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Schedule Booking',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select arrival time and service duration',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),

                const SizedBox(height: 28),

                // Section 1: Scheduled Date & Time
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Date Selection
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF2463eb),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        child: _buildPickerButton(
                          icon: Icons.calendar_today_rounded,
                          label: 'Service Date',
                          value: selectedDate != null 
                              ? DateFormat('EEEE, MMM dd').format(selectedDate!)
                              : 'Select Date',
                          isSelected: selectedDate != null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      // Time Selection
                      GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF2463eb),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        child: _buildPickerButton(
                          icon: Icons.schedule_rounded,
                          label: 'Arrival Time',
                          value: selectedTime != null
                              ? selectedTime!.format(context)
                              : 'Select Time',
                          isSelected: selectedTime != null,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Section 2: Duration and Price
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: selectedHours > 0
                        ? const Color(0xFF10B981).withOpacity(0.05)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedHours > 0
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.timer_outlined, color: Color(0xFF10B981), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Service Duration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          // Price display
                          if (selectedHours > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '₹${totalPrice.toInt()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHourButton(
                            icon: Icons.remove,
                            onTap: selectedHours > 1
                                ? () => setState(() => selectedHours--)
                                : null,
                          ),
                          const SizedBox(width: 32),
                          Column(
                            children: [
                              Text(
                                '$selectedHours',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: selectedHours > 0 ? const Color(0xFF10B981) : Colors.grey.shade400,
                                ),
                              ),
                              Text(
                                'HOURS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              if (selectedHours > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '₹${pricePerHour.toInt()}/hr',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(width: 32),
                          _buildHourButton(
                            icon: Icons.add,
                            onTap: selectedHours < 8
                                ? () => setState(() => selectedHours++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Confirm Button
                ElevatedButton(
                  onPressed: canConfirm
                      ? () => Navigator.pop(context, {
                            'hours': selectedHours,
                            'time': selectedTime,
                            'date': selectedDate,
                          })
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canConfirm ? const Color(0xFF2463eb) : Colors.grey.shade300,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    canConfirm ? 'Confirm Booking • ₹${totalPrice.toInt()}' : 'Select Time & Duration',
                    style: TextStyle(
                      color: canConfirm ? Colors.white : Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Hint text
                if (!canConfirm) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Please select both arrival time and duration',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHourButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFF10B981).withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(
          icon,
          color: onTap != null ? const Color(0xFF10B981) : Colors.grey.shade400,
        ),
      ),
    );
  }
}
