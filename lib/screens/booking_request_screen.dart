import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/booking_service.dart';
import 'booking_confirmed_screen.dart';

class BookingRequestScreen extends StatefulWidget {
  final String requestId;

  const BookingRequestScreen({super.key, required this.requestId});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final BookingService _bookingService = BookingService();
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isExpired = false;
  DateTime? _lastSyncedExpiresAt;

  void _syncTimer(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now).inSeconds;

    if (difference <= 0) {
      if (!_isExpired) {
        setState(() {
          _secondsRemaining = 0;
          _isExpired = true;
        });
        _bookingService.updateRequestStatus(widget.requestId, 'expired');
      }
      return;
    }

    setState(() {
      _secondsRemaining = difference;
      _lastSyncedExpiresAt = expiresAt;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _timer?.cancel();
        if (!_isExpired) {
          if (mounted) {
            setState(() {
              _isExpired = true;
            });
          }
          _bookingService.updateRequestStatus(widget.requestId, 'expired');
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: StreamBuilder<DocumentSnapshot>(
          stream: _bookingService.streamBookingRequest(widget.requestId),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final status = data['status'];
            final expiresAt = (data['expiresAt'] as Timestamp).toDate();

            if (status == 'pending' && !_isExpired && _lastSyncedExpiresAt != expiresAt) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _syncTimer(expiresAt);
              });
            }

            if (status == 'accepted') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingConfirmedScreen(
                        bookingData: {
                          ...data,
                          if (data['createdAt'] != null)
                            'createdAt': (data['createdAt'] as Timestamp).toDate(),
                        },
                      ),
                    ),
                  );
                }
              });
            }

            if (status == 'rejected' || status == 'expired') {
              return _buildStatusScreen(
                icon: status == 'rejected' ? Icons.cancel_rounded : Icons.timer_off_rounded,
                color: Colors.red,
                title: status == 'rejected' ? 'Request Declined' : 'Request Expired',
                message: status == 'rejected'
                    ? 'The worker is currently unavailable. Please try another provider.'
                    : 'The worker did not respond in time. Please try again.',
              );
            }

            return _buildWaitingScreen(data);
          },
        ),
    );
  }

  Widget _buildWaitingScreen(Map<String, dynamic> data) {
    final bool isToken = data['isTokenBooking'] ?? false;
    final Timestamp? startTimeStamp = data['startTime'];
    final DateTime? startTime = startTimeStamp?.toDate();

    return Column(
      children: [
        const SizedBox(height: 60),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: _secondsRemaining / 60,
                        strokeWidth: 4,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(isToken ? Colors.orange : const Color(0xFF2463EB)),
                      ),
                    ),
                    const Icon(Icons.bolt_rounded, size: 60, color: Color(0xFF1E293B)),
                  ],
                ),
                const SizedBox(height: 48),
                Text(
                  isToken ? 'Token Issued' : 'Finding Provider',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  isToken
                      ? 'Scheduled for ${startTime != null ? TimeOfDay.fromDateTime(startTime).format(context) : 'later'}. Wait for worker to confirm.'
                      : 'We\'ve sent your request. The worker has 60s to respond.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, height: 1.5),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_rounded, color: Color(0xFF2463EB), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${(_secondsRemaining % 60).toString().padLeft(2, '0')}s',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Go back to home without cancelling the request
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text('Continue in Background', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                _bookingService.updateRequestStatus(widget.requestId, 'cancelled');
                Navigator.pop(context);
              },
              child: const Text('Cancel Request', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusScreen({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 60, color: color),
          ),
          const SizedBox(height: 32),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, height: 1.5)),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Go Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
