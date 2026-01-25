import 'package:flutter/material.dart';
import 'customer_home_screen.dart';
import '../services/booking_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingConfirmedScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingData;
  const BookingConfirmedScreen({super.key, this.bookingData});

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen> {
  final Color _primaryColor = const Color(0xFF2463eb);
  final Color _backgroundLight = const Color(0xFFf6f6f8);
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    if (widget.bookingData?['id'] == null) {
      return const Scaffold(body: Center(child: Text('No booking data found')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _bookingService.streamBookingRequest(widget.bookingData!['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        return Scaffold(
          backgroundColor: _backgroundLight,
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    children: [
                      _buildSuccessIcon(),
                      _buildTitle(data),
                      _buildExtraTimeCard(data),
                      _buildServiceSummary(data),
                      const SizedBox(height: 24),
                      _buildActionButtons(context, data),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, const Color(0xFF60a5fa)],
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Text(
                'Booking Status',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Transform.translate(
      offset: const Offset(0, -32),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
        ),
        child: const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 64),
      ),
    );
  }

  Widget _buildTitle(Map<String, dynamic> data) {
    final status = data['status'];
    String title = 'Confirmed!';
    if (status == 'completed') title = 'Job Completed!';
    if (status == 'cancelled') title = 'Cancelled';

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Ref ID: ${data['id'].substring(0, 8)}', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildExtraTimeCard(Map<String, dynamic> data) {
    if (data['extraTimeRequest'] == null || data['extraTimeRequest']['status'] != 'pending') {
      return const SizedBox.shrink();
    }

    final int extraHours = data['extraTimeRequest']['hours'];

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFfffbeb),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFfcd34d)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFd97706)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The worker is requesting $extraHours additional hour(s) for this job.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _bookingService.respondToExtraTime(data['id'], false),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _bookingService.respondToExtraTime(data['id'], true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFd97706), foregroundColor: Colors.white),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSummary(Map<String, dynamic> data) {
    final createdAt = data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy • hh:mm a').format(createdAt);

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SERVICE SUMMARY', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 16),
          _buildRow(Icons.build, data['serviceName'], 'Worker: ${data['workerName']}'),
          const Divider(height: 32),
          _buildRow(Icons.access_time, '${data['duration']} Hour(s)', 'Total duration'),
          const Divider(height: 32),
          _buildRow(Icons.calendar_today, 'Date', formattedDate),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> data) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        if (data['status'] == 'accepted')
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _bookingService.cancelBooking(data['id']),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Cancel Booking'),
            ),
          ),
      ],
    );
  }
}
