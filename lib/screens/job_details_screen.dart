import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../widgets/abstract_map_widget.dart';

class JobDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const JobDetailsScreen({super.key, required this.jobData});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final BookingService _bookingService = BookingService();
  final Color _primaryColor = const Color(0xFF2463eb);
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.jobData['status'] ?? 'accepted';
    final createdAt =
        (widget.jobData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: const Text(
          'Job Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerInfoCard(),
            const SizedBox(height: 20),
            _buildJobDetailsCard(createdAt),
            const SizedBox(height: 20),
            _buildLocationCard(),
            const SizedBox(height: 32),
            if (status == 'accepted') _buildActionButtons(context),
            if (status == 'completed') _buildCompletedBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _primaryColor.withOpacity(0.1),
            child: Icon(Icons.person, color: _primaryColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.jobData['customerName'] ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '5.0 Rating',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFf0fdf4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.message_rounded,
              color: Color(0xFF22c55e),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetailsCard(DateTime date) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1e293b),
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            Icons.category_rounded,
            'Service',
            widget.jobData['serviceName'] ?? 'General Service',
          ),
          _buildDetailRow(
            Icons.calendar_today_rounded,
            'Date',
            DateFormat('MMM dd, yyyy').format(date),
          ),
          _buildDetailRow(
            Icons.access_time_rounded,
            'Time',
            DateFormat('hh:mm a').format(date),
          ),
          _buildDetailRow(
            Icons.hourglass_bottom_rounded,
            'Duration',
            '${widget.jobData['duration'] ?? 1} Hour(s)',
          ),
          const Divider(height: 32),
          const Text(
            'Notes:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.jobData['notes'] ??
                'No special instructions provided for this job.',
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFef4444),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Job Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.jobData['customerAddress'] ?? 'Address not available',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const AbstractMapWidget(height: 150, showLiveTag: false),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handleCompleteJob,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Complete Job',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: OutlinedButton(
            onPressed: () {
              // Show cancel dialog
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Color(0xFFfee2e2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: const Color(0xFFfef2f2),
            ),
            child: const Text(
              'Cancel Job',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFecfdf5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.2)),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle_rounded, color: Color(0xFF10b981)),
          SizedBox(width: 12),
          Text(
            'This job has been completed.',
            style: TextStyle(
              color: Color(0xFF065f46),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCompleteJob() async {
    setState(() => _isProcessing = true);
    try {
      await _bookingService.completeJob(widget.jobData['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job marked as completed!'),
            backgroundColor: Color(0xFF10b981),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
