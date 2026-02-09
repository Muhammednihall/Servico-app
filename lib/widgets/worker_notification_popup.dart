import 'dart:async';
import 'package:flutter/material.dart';
import '../services/booking_service.dart';

/// Widget that shows popup notifications for workers
/// Displays alerts for delay reports, penalties, and rescue job opportunities
class WorkerNotificationPopup extends StatefulWidget {
  final String workerId;
  final Widget child;

  const WorkerNotificationPopup({
    super.key,
    required this.workerId,
    required this.child,
  });

  @override
  State<WorkerNotificationPopup> createState() => _WorkerNotificationPopupState();
}

class _WorkerNotificationPopupState extends State<WorkerNotificationPopup> {
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
        .streamWorkerNotifications(widget.workerId)
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
      case 'delay_reported':
        primaryColor = const Color(0xFFF59E0B); // Orange for warnings
        icon = Icons.warning_rounded;
        break;
      case 'delay_penalty':
        primaryColor = const Color(0xFFEF4444); // Red for penalties
        icon = Icons.error_rounded;
        break;
      case 'rescue_job':
        primaryColor = const Color(0xFFFF6B35); // Rescue job orange
        icon = Icons.local_fire_department_rounded;
        break;
      case 'extra_time_response':
        primaryColor = const Color(0xFF10B981); // Green
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
                        
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        Row(
                          children: [
                            if (type == 'delay_reported')
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                    height: 58,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _bookingService.markNotificationAsRead(notificationId);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: primaryColor.withOpacity(0.5), width: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: Icon(Icons.phone_rounded, color: primaryColor),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 58,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _bookingService.markNotificationAsRead(notificationId);
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
                                    'Got It',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                    _bookingService.markNotificationAsRead(notificationId);
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

/// Compact notification badge for showing in app bars
class NotificationBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF475569),
              size: 22,
            ),
          ),
          if (count > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
