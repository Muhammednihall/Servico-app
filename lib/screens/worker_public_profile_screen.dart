import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import 'booking_request_screen.dart';
import '../widgets/modern_header.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          ModernHeader(
            title: widget.worker['name'] ?? 'Profile',
            subtitle: widget.worker['serviceType'] ?? 'Service Provider',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileOverview(),
                  const SizedBox(height: 32),
                  if (!_isLoadingStatus && _alreadyBookedByMe)
                    _buildAlreadyBookedBanner(),
                  if (!_isLoadingStatus && _isBusy && !_alreadyBookedByMe)
                    _buildBusyBanner(),
                  const SizedBox(height: 32),
                  Text('About Service', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(
                    widget.worker['bio'] ?? 'No description provided.',
                    style: TextStyle(color: Colors.grey.shade600, height: 1.6, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: _primaryColor.withOpacity(0.1),
            child: Icon(Icons.person, size: 40, color: _primaryColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.worker['rating'] ?? '5.0'}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${widget.worker['reviewsCount'] ?? '0'} reviews)',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.worker['experience'] ?? '5+'} Years Exp.',
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyBookedBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Booking Found',
                  style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w800),
                ),
                Text(
                  'Status: ${_myBookingStatus?.toUpperCase()}. New booking will be a token.',
                  style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusyBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Worker is Busy',
                  style: TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.w800),
                ),
                Text(
                  '$_tokenCount people in queue. Book a token now.',
                  style: const TextStyle(color: Color(0xFFC2410C), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoadingStatus ? null : _onBookNow,
        style: ElevatedButton.styleFrom(
          backgroundColor: (_isBusy || _alreadyBookedByMe) ? Colors.orange : const Color(0xFF1E293B),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(
          (_isBusy || _alreadyBookedByMe) ? 'Book Token' : 'Book Now',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
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
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

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
              const Text(
                'Schedule Arrival',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Date Select
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2463eb).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2463eb), size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                                Text(DateFormat('EEEE, MMM dd').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Time Select
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2463eb).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.access_time_rounded, color: Color(0xFF2463eb), size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Arrival Time', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                                Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'duration': selectedHours,
                  'startTime': DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  ),
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
