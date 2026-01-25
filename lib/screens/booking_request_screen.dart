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
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _bookingService.streamBookingRequest(widget.requestId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'];
          final expiresAt = (data['expiresAt'] as Timestamp).toDate();

          // Sync timer with Firestore expiration time
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
              icon: status == 'rejected' ? Icons.cancel : Icons.timer_off,
              color: Colors.red,
              title: status == 'rejected' ? 'Request Rejected' : 'Request Expired',
              message: status == 'rejected' 
                ? 'The worker is currently unavailable. Please try another worker.' 
                : 'The worker did not respond in time. Please try again or choose another worker.',
            );
          }

          return _buildWaitingScreen(data);
        },
      ),
    );
  }

  Widget _buildWaitingScreen(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2463eb)),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Booking Request Sent!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0e121b),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for the worker to accept your ${data['duration'] ?? 1} hour request...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFf3f4f6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFF2463eb)),
                const SizedBox(width: 8),
                Text(
                  '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2463eb),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _bookingService.updateRequestStatus(widget.requestId, 'cancelled');
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Cancel Request',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusScreen({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2463eb),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go Back', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
