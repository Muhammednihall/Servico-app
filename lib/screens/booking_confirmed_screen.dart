import 'package:flutter/material.dart';
import 'customer_home_screen.dart';
import '../services/booking_service.dart';
import '../services/location_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BookingConfirmedScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingData;
  const BookingConfirmedScreen({super.key, this.bookingData});

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen> {
  final Color _primaryBlue = const Color(0xFF2463EB);
  final Color _accentGreen = const Color(0xFF10B981);
  final Color _bgLight = const Color(0xFFF8FAFC);
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    if (widget.bookingData?['id'] == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text(
                'No booking details found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _bookingService.streamBookingRequest(widget.bookingData!['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(backgroundColor: _bgLight, body: const Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';

        return Scaffold(
          backgroundColor: _bgLight,
          body: Column(
            children: [
              _buildModernHeader(status, data),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      _buildMainStatusCard(status, data),
                      const SizedBox(height: 20),
                      if (status == 'accepted' || status == 'completed')
                        _buildTrackingSection(data),
                      const SizedBox(height: 20),
                      _buildExtraTimeNotice(data),
                      _buildServiceSummaryCard(data),
                      const SizedBox(height: 20),
                      _buildPaymentSummaryCard(data),
                      const SizedBox(height: 32),
                      _buildBottomActions(context, data),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(String status, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.all(12),
            ),
          ),
          Column(
            children: [
              const Text(
                'Booking Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              Text(
                'ID: #${data['id'].toString().substring(0, 8).toUpperCase()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline_rounded, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatusCard(String status, Map<String, dynamic> data) {
    Color color;
    IconData icon;
    String title;
    String desc;

    switch (status) {
      case 'completed':
        color = _accentGreen;
        icon = Icons.verified_rounded;
        title = 'Job Completed';
        desc = 'Worker has finished the service.';
        break;
      case 'accepted':
        color = _primaryBlue;
        icon = Icons.local_shipping_rounded;
        title = 'Confirmed';
        desc = '${data['workerName'] ?? 'Pro'} is coming to you.';
        break;
      case 'cancelled':
        color = const Color(0xFFEF4444);
        icon = Icons.cancel_rounded;
        title = 'Cancelled';
        desc = 'This booking has been cancelled.';
        break;
      default:
        color = const Color(0xFFF59E0B);
        icon = Icons.hourglass_top_rounded;
        title = 'Pending';
        desc = 'Matching you with a pro...';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                ),
                Text(
                  desc,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingSection(Map<String, dynamic> data) {
    // Extract coordinates if available
    final Map<String, dynamic>? coords = data['customerCoordinates'];
    final double? lat = coords?['lat']?.toDouble();
    final double? lng = coords?['lng']?.toDouble();
    final bool hasLocation = lat != null && lng != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Tracking',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 200,
              width: double.infinity,
              color: const Color(0xFFF1F5F9),
              child: hasLocation 
                ? FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(lat!, lng!),
                      initialZoom: 15.0,
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
                            width: 60,
                            height: 60,
                            child: _buildMapPin(Icons.person_pin_circle_rounded, _primaryBlue),
                          ),
                        ],
                      ),
                    ],
                  )
                : const Center(child: Text('Map not available')),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _primaryBlue.withOpacity(0.1),
                child: Icon(Icons.person_rounded, color: _primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['workerName'] ?? 'Matching Provider...',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const Text('Professional Provider', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {}, // Future: Call
                icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981)),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFECFDF5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildExtraTimeNotice(Map<String, dynamic> data) {
    if (data['extraTimeRequest'] == null || data['extraTimeRequest']['status'] != 'pending') {
      return const SizedBox.shrink();
    }

    final int hours = data['extraTimeRequest']['hours'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFB923C), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_rounded, color: Color(0xFFEA580C)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Extra Time Requested',
                  style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF9A3412), fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The pro needs $hours more hour to complete the job perfectly.',
            style: const TextStyle(color: Color(0xFF9A3412), height: 1.4, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _bookingService.respondToExtraTime(data['id'], false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _bookingService.respondToExtraTime(data['id'], true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSummaryCard(Map<String, dynamic> data) {
    final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          _buildInfoTile(Icons.category_rounded, 'Service', data['serviceName'] ?? 'N/A'),
          _buildInfoTile(Icons.calendar_today_rounded, 'Scheduled', DateFormat('MMM dd, hh:mm a').format(date)),
          _buildInfoTile(Icons.timer_rounded, 'Duration', '${data['duration'] ?? 1} Hour(s)'),
          _buildInfoTile(Icons.location_on_rounded, 'Address', data['customerAddress'] ?? 'N/A', isLast: true),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF64748B), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(Map<String, dynamic> data) {
    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service Fee', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              Text('₹ ${price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              Text('₹ ${price.toStringAsFixed(0)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _primaryBlue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, Map<String, dynamic> data) {
    final status = data['status'];
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor: _primaryBlue.withOpacity(0.3),
            ),
            child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        if (status == 'accepted') ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _confirmCancellation(context, data['id']),
            child: const Text('Cancel Booking', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
          ),
        ],
      ],
    );
  }

  void _confirmCancellation(BuildContext context, String requestId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Cancel Booking?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            const Text(
              'Are you sure? A cancellation might result in a small fee if the provider is already on their way.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Keep Booking', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _bookingService.cancelBooking(requestId);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
