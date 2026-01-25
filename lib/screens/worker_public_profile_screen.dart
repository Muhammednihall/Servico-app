import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import 'booking_request_screen.dart';

class WorkerPublicProfileScreen extends StatefulWidget {
  final Map<String, dynamic> worker;
  const WorkerPublicProfileScreen({super.key, required this.worker});

  @override
  State<WorkerPublicProfileScreen> createState() => _WorkerPublicProfileScreenState();
}

class _WorkerPublicProfileScreenState extends State<WorkerPublicProfileScreen> {
  final BookingService _bookingService = BookingService();
  final Color _primaryColor = const Color(0xFF2463eb);
  int _selectedDuration = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.worker['name'] ?? 'Worker Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _primaryColor.withOpacity(0.1),
                child: Icon(Icons.person, size: 50, color: _primaryColor),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.worker['serviceType'] ?? 'Service Provider',
              style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.worker['name'] ?? 'Name',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${widget.worker['rating'] ?? 0.0} (${widget.worker['totalReviews'] ?? 0} reviews)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.work, color: Colors.grey, size: 20),
                const SizedBox(width: 4),
                Text('${widget.worker['experience'] ?? 0} years exp.'),
              ],
            ),
            const Divider(height: 48),
            const Text(
              'Select Duration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: List.generate(8, (index) {
                final duration = index + 1;
                final isSelected = _selectedDuration == duration;
                return ChoiceChip(
                  label: Text('$duration Hr'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDuration = duration;
                      });
                    }
                  },
                  selectedColor: _primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onBookNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onBookNow() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final requestId = await _bookingService.createBookingRequest(
        workerId: widget.worker['id'] ?? '',
        workerName: widget.worker['name'] ?? 'Worker',
        serviceName: widget.worker['serviceType'] ?? 'Service',
        price: 35.0, // Base price per hour
        duration: _selectedDuration,
      );

      if (mounted) Navigator.pop(context); // Pop loader

      if (mounted) {
        Navigator.pushReplacement(
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
          SnackBar(content: Text('Booking failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
