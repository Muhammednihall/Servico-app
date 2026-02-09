import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../widgets/modern_header.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'customer_home_screen.dart';

class TrackOrderScreen extends StatefulWidget {
  final String? bookingId;
  const TrackOrderScreen({super.key, this.bookingId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  final Color _primaryBlue = const Color(0xFF2463EB);
  final Color _accentGreen = const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final userId = _authService.getCurrentUser()?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const ModernHeader(
            title: 'Track Order',
            subtitle: 'Real-time status updates',
            showBackButton: true,
            showNotifications: false,
          ),
          Expanded(
            child: widget.bookingId != null
                ? _buildTrackingView(widget.bookingId!)
                : _buildLatestActiveBookingTracker(userId),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestActiveBookingTracker(String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bookingService.streamCustomerBookings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];
        final activeBookings = bookings.where((b) => 
          ['pending', 'accepted'].contains(b['status']) || 
          ['on_the_way', 'arrived', 'working'].contains(b['workerStatus'])
        ).toList();

        if (activeBookings.isEmpty) {
          return _buildNoActiveBookings();
        }

        // Show the latest one
        final latest = activeBookings.first;
        return _buildTrackingContent(latest);
      },
    );
  }

  Widget _buildTrackingView(String bookingId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _bookingService.streamBookingRequest(bookingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Booking not found'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        data['id'] = snapshot.data!.id;
        return _buildTrackingContent(data);
      },
    );
  }

  Widget _buildNoActiveBookings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(Icons.track_changes_rounded, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Active Orders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          Text(
            'You don\'t have any active orders to track right now.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingContent(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'pending';
    final workerStatus = booking['workerStatus'] as String? ?? 'pending';
    final workerName = booking['workerName'] ?? 'Matching...';
    final serviceName = booking['serviceName'] ?? 'Service';
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Worker Message Bubble (Latest Update)
          _buildWorkerMessageBubble(workerStatus, booking),
          const SizedBox(height: 24),
          
          // Service Card
          _buildInfoCard(booking),
          const SizedBox(height: 24),
          
          // Status Stepper
          _buildStatusTimeline(status, workerStatus, booking),
          const SizedBox(height: 24),
          
          // Live Map if on the way
          if (workerStatus == 'on_the_way') _buildMiniMap(booking),
          
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildWorkerMessageBubble(String workerStatus, Map<String, dynamic> booking) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _bookingService.streamLatestBookingNotification(booking['id']),
      builder: (context, snapshot) {
        String message = "Waiting for worker to start...";
        IconData icon = Icons.info_outline_rounded;
        Color color = _primaryBlue;

        if (snapshot.hasData && snapshot.data != null) {
          final notification = snapshot.data!;
          message = notification['message'] ?? message;
          final type = notification['type']?.toString() ?? '';
          
          if (type.contains('onTheWay')) {
            icon = Icons.directions_car_rounded;
            color = _primaryBlue;
          } else if (type.contains('arrived')) {
            icon = Icons.location_on_rounded;
            color = _accentGreen;
          } else if (workerStatus == 'working') {
            icon = Icons.handyman_rounded;
            color = Colors.orange;
          } else if (workerStatus == 'completed') {
            icon = Icons.check_circle_rounded;
            color = _accentGreen;
          }
        } else {
          // Fallback to basic status-based messages if no notification found yet
          switch (workerStatus) {
            case 'on_the_way':
              message = "I'm on my way! I'll be there soon.";
              icon = Icons.directions_car_rounded;
              break;
            case 'arrived':
              message = "I have reached your location.";
              icon = Icons.location_on_rounded;
              color = _accentGreen;
              break;
            case 'working':
              message = "I'm currently working on your request.";
              icon = Icons.handyman_rounded;
              color = Colors.orange;
              break;
            case 'completed':
              message = "Service completed! Thank you.";
              icon = Icons.check_circle_rounded;
              color = _accentGreen;
              break;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Message from Worker',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_getServiceIcon(booking['serviceName']), color: _primaryBlue, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['serviceName'] ?? 'Service',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Worker: ${booking['workerName'] ?? 'Finding...'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_rounded, color: Color(0xFF10B981), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String status, String workerStatus, Map<String, dynamic> booking) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 24),
          _buildTimelineItem(
            'Order Confirmed',
            'Your request has been received',
            true,
            isLast: false,
            isActive: true,
          ),
          _buildTimelineItem(
            'Worker Assigned',
            booking['workerName'] != null ? '${booking['workerName']} is assigned to your job' : 'Finding the best worker for you',
            booking['workerName'] != null,
            isLast: false,
            isActive: booking['workerStatus'] != null || booking['status'] == 'accepted',
          ),
          _buildTimelineItem(
            'On My Way',
            workerStatus == 'on_the_way' 
              ? 'Worker is heading your way (ETA: ${booking['estimatedMinutes'] ?? '15'} mins)' 
              : 'Worker will start travel soon',
            workerStatus == 'on_the_way' || workerStatus == 'arrived' || workerStatus == 'working' || workerStatus == 'completed',
            isLast: false,
            isActive: workerStatus == 'on_the_way',
          ),
          _buildTimelineItem(
            'Reached Location',
            workerStatus == 'arrived' || workerStatus == 'working' || workerStatus == 'completed'
              ? 'Worker has reached your destination'
              : 'Waiting for worker to arrive',
            workerStatus == 'arrived' || workerStatus == 'working' || workerStatus == 'completed',
            isLast: false,
            isActive: workerStatus == 'arrived',
          ),
          _buildTimelineItem(
            'Work in Progress',
            workerStatus == 'working' || workerStatus == 'completed'
              ? 'Expert is working on your service'
              : 'Service will start shortly',
            workerStatus == 'working' || workerStatus == 'completed',
            isLast: false,
            isActive: workerStatus == 'working',
          ),
          _buildTimelineItem(
            'Completed',
            status == 'completed' || workerStatus == 'completed'
              ? 'Job finished successfully'
              : 'Awaiting completion',
            status == 'completed' || workerStatus == 'completed',
            isLast: true,
            isActive: status == 'completed',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, bool isDone, {required bool isLast, required bool isActive}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? _accentGreen : (isActive ? _primaryBlue : Colors.grey.shade200),
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: _primaryBlue.withOpacity(0.2), width: 4) : null,
              ),
              child: isDone 
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : (isActive ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), margin: const EdgeInsets.all(6)) : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isDone ? _accentGreen : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isActive || isDone ? const Color(0xFF1E293B) : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive || isDone ? const Color(0xFF64748B) : Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMap(Map<String, dynamic> booking) {
    final Map<String, dynamic>? coords = booking['customerCoordinates'];
    final double? lat = coords?['lat']?.toDouble();
    final double? lng = coords?['lng']?.toDouble();
    
    if (lat == null || lng == null) return const SizedBox.shrink();

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.servico.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lng),
                  width: 40,
                  height: 40,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon(String? name) {
    final n = name?.toLowerCase() ?? '';
    if (n.contains('water')) return Icons.water_drop_rounded;
    if (n.contains('gas')) return Icons.local_fire_department_rounded;
    if (n.contains('clean')) return Icons.cleaning_services_rounded;
    if (n.contains('plum')) return Icons.plumbing_rounded;
    if (n.contains('elect')) return Icons.electrical_services_rounded;
    return Icons.build_circle_rounded;
  }
}
