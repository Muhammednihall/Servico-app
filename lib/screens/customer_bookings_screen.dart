import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../widgets/modern_header.dart';
import 'booking_confirmed_screen.dart';
import 'booking_request_screen.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Please login to view bookings',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const ModernHeader(
            title: 'My Bookings',
            subtitle: 'Track your service requests',
            showBackButton: false,
            showNotifications: false,
          ),
          _buildTabs(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _bookingService.streamCustomerBookings(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allBookings = snapshot.data ?? [];

                // Categorize bookings
                final pending = allBookings.where((b) => b['status'] == 'pending').toList();
                final active = allBookings.where((b) => b['status'] == 'accepted').toList();
                final history = allBookings.where((b) => 
                  ['completed', 'cancelled', 'rejected', 'expired'].contains(b['status'])
                ).toList();

                return PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _tabController.animateTo(index);
                  },
                  children: [
                    _buildBookingList(pending, 'pending'),
                    _buildBookingList(active, 'active'),
                    _buildBookingList(history, 'history'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF2463EB),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerHeight: 0,
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Active'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<Map<String, dynamic>> bookings, String type) {
    if (bookings.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _buildBookingCard(bookings[index], type),
    );
  }

  Widget _buildEmptyState(String type) {
    IconData icon;
    String title;
    String message;

    switch (type) {
      case 'pending':
        icon = Icons.hourglass_empty_rounded;
        title = 'No pending requests';
        message = 'Your booking requests will appear here';
        break;
      case 'active':
        icon = Icons.work_outline_rounded;
        title = 'No active bookings';
        message = 'Currently no services in progress';
        break;
      default:
        icon = Icons.history_rounded;
        title = 'No booking history';
        message = 'Your completed services will show here';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, String sectionType) {
    final status = booking['status'] ?? 'pending';
    final createdAt = (booking['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(createdAt);
    final price = (booking['price'] as num?)?.toDouble() ?? 0;
    final duration = booking['duration'] ?? 1;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.schedule_rounded;
        statusLabel = 'Waiting';
        break;
      case 'accepted':
        statusColor = const Color(0xFF2463EB);
        statusIcon = Icons.check_circle_outline_rounded;
        statusLabel = 'In Progress';
        break;
      case 'completed':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.verified_rounded;
        statusLabel = 'Completed';
        break;
      case 'cancelled':
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_outlined;
        statusLabel = status == 'cancelled' ? 'Cancelled' : 'Declined';
        break;
      case 'expired':
        statusColor = const Color(0xFF6B7280);
        statusIcon = Icons.timer_off_outlined;
        statusLabel = 'Expired';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusLabel = status;
    }

    return GestureDetector(
      onTap: () => _navigateToBooking(booking, status),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main Info Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Service Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.15),
                          statusColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getIconForService(booking['serviceName'] ?? ''),
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['serviceName'] ?? 'Service',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              booking['workerName'] ?? 'Finding...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Info Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date & Duration
                  Row(
                    children: [
                      _buildInfoChip(Icons.calendar_today, dateStr),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.timer_outlined, '${duration}h'),
                    ],
                  ),
                  // Price
                  Text(
                    '₹${price.toInt()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            // Action Button for pending
            if (status == 'pending') _buildPendingActions(booking),
            // Active booking actions (delay reporting)
            if (status == 'accepted') _buildActiveActions(booking),
            // Rating for completed
            if (status == 'completed') _buildCompletedActions(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingActions(Map<String, dynamic> booking) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(booking['id']),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _navigateToBooking(booking, 'pending'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2463EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('View Status', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Build active booking actions with delay reporting
  Widget _buildActiveActions(Map<String, dynamic> booking) {
    final startTime = (booking['startTime'] as Timestamp?)?.toDate();
    final delayStatus = booking['delayStatus'] as String?;
    final showDelayButton = _bookingService.shouldShowDelayButton(booking);
    final showNotReachedButton = _bookingService.shouldShowNotReachedButton(booking);
    final workerPhone = booking['workerPhone'] as String? ?? '';
    
    // If we haven't reached start time yet, show a simple view button
    if (!showDelayButton) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToBooking(booking, 'accepted'),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2463EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      );
    }

    // After scheduled time - show delay reporting options
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // Phase 1 & 2: Delay reported - show call section
          if (delayStatus == 'reported' || delayStatus == 'called') ...[
            // Call Worker Section
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.phone_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Worker',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              workerPhone.isNotEmpty ? workerPhone : 'Phone not available',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _callWorker(booking),
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  
                  // Show timer or Not Reached button
                  if (delayStatus == 'called') ...[
                    const SizedBox(height: 12),
                    if (!showNotReachedButton)
                      _buildWaitingTimer(booking)
                    else
                      _buildNotReachedButton(booking),
                  ],
                ],
              ),
            ),
          ],
          
          // Phase 1: Worker Delayed button (not yet reported)
          if (delayStatus == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDelayReportDialog(booking),
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: const Text('Worker Delayed?', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build waiting timer widget
  Widget _buildWaitingTimer(Map<String, dynamic> booking) {
    final remaining = _bookingService.getTimeUntilNotReachedButtonShows(booking);
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            'Wait ${minutes}:${seconds.toString().padLeft(2, '0')} for worker to reach',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build "Worker Not Reached" button
  Widget _buildNotReachedButton(Map<String, dynamic> booking) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showNotReachedConfirmation(booking),
        icon: const Icon(Icons.warning_rounded, size: 18),
        label: const Text('Worker Not Reached', style: TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// Show delay report dialog
  void _showDelayReportDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.schedule_rounded, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 12),
            const Text('Worker Delayed?', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Has the scheduled time passed and the worker hasn\'t arrived yet?\n\nYou can contact the worker to check their status.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _bookingService.reportWorkerDelay(booking['id']);
              setState(() {}); // Refresh UI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Worker has been notified. You can now call them.'),
                  backgroundColor: Color(0xFFF59E0B),
                ),
              );
            },
            icon: const Icon(Icons.phone_rounded, size: 18),
            label: const Text('Yes, Contact Worker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Call the worker
  Future<void> _callWorker(Map<String, dynamic> booking) async {
    final workerPhone = booking['workerPhone'] as String? ?? '';
    
    if (workerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Record that call was initiated
    await _bookingService.recordCallToWorker(booking['id']);
    
    // Open phone dialer
    final phoneUri = Uri(scheme: 'tel', path: workerPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() {}); // Refresh UI
  }

  /// Show "Worker Not Reached" confirmation dialog
  void _showNotReachedConfirmation(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Worker Not Reached?', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Are you sure you want to mark this worker as unreachable?',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              '• This will affect the worker\'s rating\n'
              '• We will find you a new worker (Rescue Job)\n'
              '• You will receive a discount for the delay',
              style: TextStyle(color: Color(0xFF64748B), height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Wait More'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _callWorker(booking);
            },
            icon: const Icon(Icons.phone_rounded, size: 16),
            label: const Text('Call Again'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Report worker not reached
              final success = await _bookingService.reportWorkerNotReached(booking['id']);
              
              Navigator.pop(context); // Close loading
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Finding you a new worker...'),
                    backgroundColor: Color(0xFF2463EB),
                  ),
                );
                setState(() {}); // Refresh UI
              }
            },
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Mark as Delayed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedActions(Map<String, dynamic> booking) {
    final hasRating = booking['rating'] != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: hasRating
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  'You rated ${booking['rating']} stars',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRatingDialog(booking),
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: const Text('Rate This Service', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
    );
  }

  void _navigateToBooking(Map<String, dynamic> booking, String status) {
    if (status == 'pending') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingRequestScreen(requestId: booking['id']),
        ),
      );
    } else if (status == 'accepted' || status == 'completed') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmedScreen(bookingData: booking),
        ),
      );
    }
  }

  IconData _getIconForService(String service) {
    service = service.toLowerCase();
    if (service.contains('clean')) return Icons.cleaning_services_rounded;
    if (service.contains('plumb')) return Icons.plumbing_rounded;
    if (service.contains('elect')) return Icons.electrical_services_rounded;
    if (service.contains('paint')) return Icons.format_paint_rounded;
    if (service.contains('pest')) return Icons.bug_report_rounded;
    if (service.contains('ac') || service.contains('repair')) return Icons.home_repair_service_rounded;
    return Icons.handyman_rounded;
  }

  void _showCancelDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cancel Booking?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to cancel this service request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep It', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              _bookingService.cancelBooking(requestId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(Map<String, dynamic> booking) {
    double selectedRating = 5.0;
    final TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                'Rate Your Experience',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'How was the service with ${booking['workerName']}?',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: isSubmitting
                        ? null
                        : () => setModalState(() => selectedRating = index + 1.0),
                    icon: Icon(
                      index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: reviewController,
                enabled: !isSubmitting,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            final user = _authService.getCurrentUser();
                            if (user != null) {
                              await _bookingService.submitReview(
                                requestId: booking['id'],
                                workerId: booking['workerId'],
                                customerId: user.uid,
                                customerName: booking['customerName'] ?? 'User',
                                rating: selectedRating,
                                review: reviewController.text.trim(),
                              );
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Thank you for your review!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2463EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Review',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
