import 'dart:async';
import 'package:flutter/material.dart';
import '../services/booking_service.dart';

/// Widget that shows popup notifications for customers
/// Displays alerts for worker status updates, rescue job assignments, etc.
class CustomerNotificationPopup extends StatefulWidget {
  final String customerId;
  final Widget child;

  const CustomerNotificationPopup({
    super.key,
    required this.customerId,
    required this.child,
  });

  @override
  State<CustomerNotificationPopup> createState() => _CustomerNotificationPopupState();
}

class _CustomerNotificationPopupState extends State<CustomerNotificationPopup> {
  final BookingService _bookingService = BookingService();
  StreamSubscription? _notificationSubscription;
  List<Map<String, dynamic>> _pendingNotifications = [];
  bool _isShowingPopup = false;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription = _bookingService
        .streamCustomerNotifications(widget.customerId)
        .listen((notifications) {
      if (notifications.isNotEmpty && !_isShowingPopup) {
        _pendingNotifications = notifications;
        _showNextNotification();
      }
    });
  }

  void _showNextNotification() {
    if (_pendingNotifications.isEmpty || _isShowingPopup) return;
    
    final notification = _pendingNotifications.first;
    _isShowingPopup = true;
    
    _showNotificationDialog(notification).then((_) {
      _isShowingPopup = false;
      _pendingNotifications.removeAt(0);
      // Show next notification if any
      if (_pendingNotifications.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _showNextNotification();
        });
      }
    });
  }

  Future<void> _showNotificationDialog(Map<String, dynamic> notification) async {
    final type = notification['type'] as String? ?? '';
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final imageUrl = notification['imageUrl'] as String?;
    final notificationId = notification['id'] as String;

    // Determine colors and icons based on type
    Color primaryColor;
    IconData icon;
    
    switch (type) {
      case 'worker_on_the_way':
        primaryColor = const Color(0xFF2463EB); // Blue
        icon = Icons.directions_car_rounded;
        break;
      case 'worker_arrived':
        primaryColor = const Color(0xFF10B981); // Green
        icon = Icons.location_on_rounded;
        break;
      case 'rescue_worker_assigned':
        primaryColor = const Color(0xFFFF6B35); // Rescue orange
        icon = Icons.local_fire_department_rounded;
        break;
      case 'booking_confirmed':
        primaryColor = const Color(0xFF10B981); // Green
        icon = Icons.check_circle_rounded;
        break;
      case 'job_completed':
        primaryColor = const Color(0xFF10B981); // Green
        icon = Icons.verified_rounded;
        break;
      case 'extra_time_requested':
        primaryColor = const Color(0xFF2463EB); // Blue
        icon = Icons.more_time_rounded;
        break;
      default:
        primaryColor = const Color(0xFF2463EB); // Default blue
        icon = Icons.notifications_rounded;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient Header with Icon
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                      ),
                      Positioned(
                        top: 70,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: primaryColor, size: 32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Text Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        if (imageUrl != null && imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              imageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                        ],
                        
                        if (type == 'rescue_worker_assigned') ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.stars_rounded, size: 18, color: Color(0xFF10B981)),
                                SizedBox(width: 8),
                                Text(
                                  'Premium Discount Unlocked!',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // Primary Action
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _bookingService.markCustomerNotificationAsRead(notificationId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Close Button using Modern UI style
              Positioned(
                top: 15,
                right: 15,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _bookingService.markCustomerNotificationAsRead(notificationId);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
