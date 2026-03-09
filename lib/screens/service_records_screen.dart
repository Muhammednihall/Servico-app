import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../widgets/modern_header.dart';

class ServiceRecordsScreen extends StatelessWidget {
  final String userRole; // 'customer' or 'worker'
  
  const ServiceRecordsScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final BookingService bookingService = BookingService();
    final AuthService authService = AuthService();
    final user = authService.getCurrentUser();

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login to view records')));
    }

    final Color primaryColor = const Color(0xFF2463eb);
    final Color accentGreen = const Color(0xFF10b981);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          ModernHeader(
            title: userRole == 'customer' ? 'My Receipts' : 'Service Records',
            subtitle: 'History of completed services',
            showBackButton: true,
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: bookingService.streamServiceRecords(user.uid, userRole: userRole),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No records found',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final date = (record['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final amount = userRole == 'customer'
                        ? ((record['customerPayment'] ?? record['finalAmount']) as num?)?.toDouble() ?? 0.0
                        : ((record['workerEarnings'] ?? record['finalAmount']) as num?)?.toDouble() ?? 0.0;
                    final serviceName = record['serviceName'] ?? 'Service';
                    final otherPartyName = userRole == 'customer' 
                        ? (record['workerName'] ?? 'Provider')
                        : (record['customerName'] ?? 'Customer');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.receipt_rounded, color: primaryColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  serviceName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${userRole == 'customer' ? 'With' : 'For'}: $otherPartyName',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM d, yyyy • hh:mm a').format(date),
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${amount.toInt()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: accentGreen,
                                ),
                              ),
                              if (record['isReassigned'] == true)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Discounted',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
