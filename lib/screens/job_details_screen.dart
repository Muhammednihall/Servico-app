import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'worker_main_screen.dart';
import '../services/booking_service.dart';
import '../services/location_service.dart';
import '../widgets/modern_header.dart';
import '../widgets/worker_status_update_card.dart';

class JobDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const JobDetailsScreen({super.key, required this.jobData});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final BookingService _bookingService = BookingService();
  final LocationService _locationService = LocationService();
  final Color _primaryBlue = const Color(0xFF2463EB);
  final Color _accentGreen = const Color(0xFF10B981);
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.jobData['status'] ?? 'accepted';
    final createdAt = (widget.jobData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    // Extract coordinates
    final Map<String, dynamic>? coords = widget.jobData['customerCoordinates'];
    final double? customerLat = coords?['lat']?.toDouble();
    final double? customerLng = coords?['lng']?.toDouble();
    final bool hasLocation = customerLat != null && customerLng != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _bookingService.streamBookingRequest(widget.jobData['id']),
        builder: (context, snapshot) {
          final data = snapshot.hasData && snapshot.data!.exists 
              ? snapshot.data!.data() as Map<String, dynamic> 
              : widget.jobData;
          
          final currentStatus = data['status'] ?? 'accepted';
          final workerStatus = data['workerStatus'] ?? 'pending';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          
          // Extract coordinates
          final Map<String, dynamic>? coords = data['customerCoordinates'];
          final double? customerLat = coords?['lat']?.toDouble();
          final double? customerLng = coords?['lng']?.toDouble();
          final bool hasLocation = customerLat != null && customerLng != null;

          return Column(
            children: [
              ModernHeader(
                title: 'Job Details',
                subtitle: 'ID: ${data['id']?.toString().substring(0, 8).toUpperCase() ?? "N/A"}',
                showBackButton: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBadge(currentStatus),
                      const SizedBox(height: 20),
                      
                      // Worker status update card - shown for all active jobs
                      if (currentStatus == 'accepted' || currentStatus == 'assigned' || currentStatus == 'working') ...[
                        WorkerStatusUpdateCard(
                          booking: data,
                          onStatusUpdated: () {
                            // StreamBuilder will handle the update
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      _buildCustomerSection(data),
                      const SizedBox(height: 20),
                      _buildServiceDetailsSection(currentStatus, data, createdAt),
                      const SizedBox(height: 20),
                      _buildLocationSection(data, hasLocation, customerLat, customerLng),
                      const SizedBox(height: 32),
                      if (currentStatus == 'accepted' || currentStatus == 'working') _buildActionButtons(data, workerStatus),
                      if (currentStatus == 'completed') _buildCompletedSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String label = status.toUpperCase();

    if (status == 'completed') {
      color = _accentGreen;
      icon = Icons.check_circle_rounded;
    } else if (status == 'accepted') {
      color = _primaryBlue;
      icon = Icons.run_circle_outlined;
    } else {
      color = Colors.orange;
      icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(Map<String, dynamic> data) {
    final customerName = data['customerName'] ?? 'Customer';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                customerName[0].toUpperCase(),
                style: TextStyle(
                  color: _primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '5.0 Customer Rating',
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
        ],
      ),
    );
  }

  Widget _buildServiceDetailsSection(String status, Map<String, dynamic> data, DateTime date) {
    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final int duration = (data['duration'] as num?)?.toInt() ?? 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailTile(
            Icons.work_rounded,
            'Service Category',
            data['serviceName'] ?? 'General Task',
          ),
          _buildDetailTile(
            Icons.calendar_today_rounded,
            'Schedule Date',
            DateFormat('EEEE, MMM dd').format(date),
          ),
          _buildDetailTile(
            Icons.access_time_rounded,
            'Schedule Time',
            DateFormat('hh:mm a').format(date),
          ),
          _buildDetailTile(
            Icons.timer_rounded,
            'Estimated Duration',
            '$duration Hour(s)',
            valueColor: data['extraTimeRequest']?['status'] == 'approved' ? _primaryBlue : null,
          ),
          _buildDetailTile(
            Icons.payments_rounded,
            'Total Price',
            '₹ ${price.toStringAsFixed(0)}',
            valueColor: _accentGreen,
          ),
          if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
            const Divider(height: 32),
            const Text(
              'Instruction Notes',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Text(
              data['notes'],
              style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF1E293B),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(Map<String, dynamic> data, bool hasLocation, double? lat, double? lng) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data['customerAddress'] ?? 'No address provided',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  if (hasLocation)
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat!, lng!),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
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
                              child: _buildMapPin(),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Text('Map location not available'),
                      ),
                    ),
                  
                  // Navigate Overlay Button
                  if (hasLocation)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _accentGreen,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentGreen.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.directions_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Navigate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> data, String workerStatus) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: (_isProcessing || workerStatus != 'working') ? null : () => _handleCompleteJob(data),
            style: ElevatedButton.styleFrom(
              backgroundColor: workerStatus == 'working' ? _accentGreen : Colors.grey.shade300,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text(
                    'Mark as Completed',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: TextButton(
            onPressed: _isProcessing ? null : () => _handleCancelJob(data),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: const Color(0xFFFFEBEB),
            ),
            child: const Text('Cancel Job', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, color: _accentGreen, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Mission Completed!',
            style: TextStyle(
              color: Color(0xFF065F46),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'The payment has been credited to your wallet.',
            style: TextStyle(color: Color(0xFF065F46), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelJob(Map<String, dynamic> data) async {
    final acceptedAt = (data['acceptedAt'] as Timestamp?)?.toDate();
    if (acceptedAt == null) return;

    final now = DateTime.now();
    final difference = now.difference(acceptedAt);
    final isWithinGracePeriod = difference.inMinutes < 3;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isWithinGracePeriod ? 'Cancel Job?' : 'Late Cancellation',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isWithinGracePeriod
                  ? 'Are you sure you want to cancel? You have ${3 - difference.inMinutes} minutes left to cancel without penalty.'
                  : 'The 3-minute grace period for free cancellation has expired. Cancelling now WILL affect your pro rating.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (!isWithinGracePeriod) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your rating will be slightly reduced.',
                        style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Job', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performCancellation(data['id'], !isWithinGracePeriod);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm Cancellation', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancellation(String requestId, bool penalized) async {
    setState(() => _isProcessing = true);
    try {
      await _bookingService.cancelBookingByWorker(requestId, penalized: penalized);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(penalized 
              ? 'Job cancelled. Your rating has been updated.' 
              : 'Job cancelled successfully.'),
            backgroundColor: penalized ? Colors.orange : Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCompleteJob(Map<String, dynamic> data) async {
    setState(() => _isProcessing = true);
    try {
      await _bookingService.completeJob(data['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job successfuly completed!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WorkerMainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
