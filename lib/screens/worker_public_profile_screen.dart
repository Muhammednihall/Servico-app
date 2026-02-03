import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import 'booking_request_screen.dart';

class WorkerPublicProfileScreen extends StatefulWidget {
  final Map<String, dynamic> worker;
  const WorkerPublicProfileScreen({super.key, required this.worker});

  @override
  State<WorkerPublicProfileScreen> createState() =>
      _WorkerPublicProfileScreenState();
}

class _WorkerPublicProfileScreenState extends State<WorkerPublicProfileScreen> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  final Color _primaryColor = const Color(0xFF2463eb);
  bool _isBusy = false;
  bool _isLoadingStatus = true;
  int _tokenCount = 0;
  bool _alreadyBookedByMe = false;
  String? _myBookingStatus;

  @override
  void initState() {
    super.initState();
    _checkWorkerStatus();
  }

  Future<void> _checkWorkerStatus() async {
    try {
      final workerId = widget.worker['id'];
      if (workerId == null) return;

      // Check for active jobs
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('booking_requests')
          .where('workerId', isEqualTo: workerId)
          .where('status', isEqualTo: 'accepted')
          .get();

      // Check for token bookings today
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final tokensSnapshot = await FirebaseFirestore.instance
          .collection('booking_requests')
          .where('workerId', isEqualTo: workerId)
          .where('isTokenBooking', isEqualTo: true)
          .where('status', isEqualTo: 'pending')
          .get();

      // Check if current user has an active/pending booking with this worker
      final user = _authService.getCurrentUser();
      bool userHasBooking = false;
      String? userBookingStatus;

      if (user != null) {
        final myBookingsSnapshot = await FirebaseFirestore.instance
            .collection('booking_requests')
            .where('workerId', isEqualTo: workerId)
            .where('customerId', isEqualTo: user.uid)
            .where('status', whereIn: ['pending', 'accepted'])
            .get();

        if (myBookingsSnapshot.docs.isNotEmpty) {
          userHasBooking = true;
          userBookingStatus = myBookingsSnapshot.docs.first.data()['status'];
        }
      }

      if (mounted) {
        setState(() {
          _isBusy = jobsSnapshot.docs.isNotEmpty;
          _tokenCount = tokensSnapshot.docs.length;
          _alreadyBookedByMe = userHasBooking;
          _myBookingStatus = userBookingStatus;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      print('Error checking worker status: $e');
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }

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
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
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
              'About Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.worker['bio'] ?? 'No description provided.',
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            if (!_isLoadingStatus && _alreadyBookedByMe)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.blue.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You have an active booking',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Status: ${_myBookingStatus?.toUpperCase() ?? 'PENDING'}. Next booking will be added as a token.',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (!_isLoadingStatus && _isBusy)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Worker is currently in work',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'You can book a token for later. Currently $_tokenCount people in queue.',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoadingStatus ? null : _onBookNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isBusy || _alreadyBookedByMe)
                      ? Colors.orange
                      : _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  (_isBusy || _alreadyBookedByMe) ? 'Book Token' : 'Book Now',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
      final result = await _showBookingDetailsPicker(context);
      if (result == null) return;

      final int duration = result['duration'];
      final DateTime? startTime = result['startTime'];
      final bool isToken = _isBusy || _alreadyBookedByMe;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get customer info
      final user = _authService.getCurrentUser();
      String? customerName;
      String? customerAddress;

      if (user != null) {
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();
        if (customerDoc.exists) {
          customerName = customerDoc.data()?['name'];
          customerAddress = customerDoc.data()?['address'];
        }
      }

      final requestId = await _bookingService.createBookingRequest(
        workerId: widget.worker['id'] ?? '',
        workerName: widget.worker['name'] ?? 'Worker',
        serviceName: widget.worker['serviceType'] ?? 'Service',
        price: 35.0 * duration, // Base price per hour * duration
        duration: duration,
        customerName: customerName,
        customerAddress: customerAddress,
        isTokenBooking: isToken,
        startTime: startTime,
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
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showBookingDetailsPicker(
    BuildContext context,
  ) async {
    int selectedHours = 1;
    DateTime selectedTime = DateTime.now().add(const Duration(hours: 1));
    // Round to next hour
    selectedTime = DateTime(
      selectedTime.year,
      selectedTime.month,
      selectedTime.day,
      selectedTime.hour,
      0,
    );

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                (_isBusy || _alreadyBookedByMe) ? 'Token Booking' : 'Select Duration',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1e293b),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _alreadyBookedByMe
                    ? 'You already have an active booking. This will be added as a token.'
                    : _isBusy
                        ? 'Worker is busy. Select your preferred time period.'
                        : 'Select how many hours you need the service.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),
              const Text(
                'Duration (Hours)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHourButton(
                    icon: Icons.remove,
                    onTap: selectedHours > 1
                        ? () => setState(() => selectedHours--)
                        : null,
                  ),
                  const SizedBox(width: 32),
                  Column(
                    children: [
                      Text(
                        '$selectedHours',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2463eb),
                        ),
                      ),
                      const Text(
                        'HOURS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                  _buildHourButton(
                    icon: Icons.add,
                    onTap: selectedHours < 6
                        ? () => setState(() => selectedHours++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_isBusy || _alreadyBookedByMe) ...[
                const Text(
                  'Select Time Period',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedTime),
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = DateTime(
                          selectedTime.year,
                          selectedTime.month,
                          selectedTime.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.blue),
                            const SizedBox(width: 12),
                            Text(
                              'Starts at: ${TimeOfDay.fromDateTime(selectedTime).format(context)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'duration': selectedHours,
                  'startTime': (_isBusy || _alreadyBookedByMe) ? selectedTime : null,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isBusy || _alreadyBookedByMe) ? Colors.orange : const Color(0xFF2463eb),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  (_isBusy || _alreadyBookedByMe) ? 'Confirm Token Booking' : 'Confirm Booking',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFF2463eb).withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: onTap != null ? const Color(0xFF2463eb) : Colors.grey.shade400,
        ),
      ),
    );
  }
}
