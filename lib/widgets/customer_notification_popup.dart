import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/booking_service.dart';

/// Widget that shows popup notifications for customers
/// Displays alerts for worker status updates, etc.
class CustomerNotificationPopup extends StatefulWidget {
  final String customerId;
  final Widget child;

  const CustomerNotificationPopup({
    super.key,
    required this.customerId,
    required this.child,
  });

  @override
  State<CustomerNotificationPopup> createState() =>
      _CustomerNotificationPopupState();
}

class _CustomerNotificationPopupState extends State<CustomerNotificationPopup>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  StreamSubscription? _notificationSubscription;
  List<Map<String, dynamic>> _pendingNotifications = [];
  bool _isShowingPopup = false;
  late AnimationController _iconAnimationController;

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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

  Future<void> _showNotificationDialog(
    Map<String, dynamic> notification,
  ) async {
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
        primaryColor = const Color(0xFF3B82F6); // Modern Blue
        icon = Icons.directions_car_rounded;
        break;
      case 'worker_arrived':
        primaryColor = const Color(0xFF10B981); // Emerald Green
        icon = Icons.location_on_rounded;
        break;
      case 'booking_confirmed':
        primaryColor = const Color(0xFF10B981); // Emerald Green
        icon = Icons.check_circle_rounded;
        break;
      case 'job_completed':
        primaryColor = const Color(0xFF10B981); // Emerald Green
        icon = Icons.verified_rounded;
        break;
      case 'extra_time_requested':
        primaryColor = const Color(0xFFF59E0B); // Amber
        icon = Icons.more_time_rounded;
        break;
      default:
        primaryColor = const Color(0xFF6366F1); // Indigo
        icon = Icons.notifications_rounded;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Subtle background glow
                  Positioned(
                    top: -50,
                    left: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.15),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.15),
                      ),
                    ),
                  ),

                  // Main Content
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Icon Container
                        AnimatedBuilder(
                          animation: _iconAnimationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -5 * _iconAnimationController.value),
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withOpacity(0.15),
                                  primaryColor.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              size: 48,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Message
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),

                        if (imageUrl != null && imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                imageUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 36),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _bookingService.markCustomerNotificationAsRead(
                                notificationId,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              shadowColor: primaryColor.withOpacity(0.4),
                            ),
                            child: const Text(
                              'Got it',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _bookingService.markCustomerNotificationAsRead(
                          notificationId,
                        );
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                        size: 24,
                      ),
                      splashRadius: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
