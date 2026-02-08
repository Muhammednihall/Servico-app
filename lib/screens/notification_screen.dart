import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../widgets/modern_header.dart';
import 'job_details_screen.dart';
import 'new_job_request_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final AuthService _authService = AuthService();
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    if (user == null) return const Scaffold(body: Center(child: Text('Please Login')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const ModernHeader(
            title: 'Notifications',
            subtitle: 'Stay updated with',
            showBackButton: true,
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _bookingService.streamUpcomingSchedule(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final incoming = snapshot.data ?? [];
                
                // Fetch missed jobs (expired/rejected)
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _bookingService.streamCancelledJobs(user.uid),
                  builder: (context, cancelledSnapshot) {
                    final missed = cancelledSnapshot.data ?? [];
                    
                    final allNotifications = _processNotifications(incoming, missed);

                    if (allNotifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No notifications yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: allNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = allNotifications[index];
                        return _buildNotificationCard(notification);
                      },
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

  List<Map<String, dynamic>> _processNotifications(
    List<Map<String, dynamic>> incoming,
    List<Map<String, dynamic>> missed,
  ) {
    final List<Map<String, dynamic>> result = [];
    final now = DateTime.now();

    // 1. Job Requests Received (Pending)
    for (var job in incoming) {
      if (job['status'] == 'pending') {
        result.add({
          'type': 'request',
          'title': 'New Job Request',
          'body': 'You have a new request from ${job['customerName']} for ${job['serviceName']}.',
          'time': job['createdAt'],
          'data': job,
          'priority': 1,
        });
      }
      
      // 2. Job Reminders (Accepted and starting soon - next 12 hours for visibility in demo)
      if (job['status'] == 'accepted' || job['status'] == 'assigned') {
        final startTime = (job['startTime'] as Timestamp?)?.toDate();
        if (startTime != null) {
          final diff = startTime.difference(now);
          if (diff.inHours >= 0 && diff.inHours <= 12) {
            result.add({
              'type': 'reminder',
              'title': 'Upcoming Job Reminder',
              'body': 'Reminder: Your job for ${job['customerName']} starts at ${DateFormat('hh:mm a').format(startTime)}.',
              'time': job['startTime'],
              'data': job,
              'priority': 2,
            });
          }
        }
      }
    }

    // 3. Missed Jobs (Rejected/Expired)
    for (var job in missed) {
       result.add({
          'type': 'missed',
          'title': 'Job Alert',
          'body': 'Job request from ${job['customerName']} was ${job['status']}.',
          'time': job['updatedAt'] ?? job['createdAt'],
          'data': job,
          'priority': 3,
        });
    }

    // Sort by time (newest first)
    result.sort((a, b) {
      final t1 = (a['time'] as Timestamp?)?.toDate() ?? DateTime.now();
      final t2 = (b['time'] as Timestamp?)?.toDate() ?? DateTime.now();
      return t2.compareTo(t1);
    });

    return result;
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    Color iconBg;
    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'request':
        iconBg = const Color(0xFFeff6ff);
        icon = Icons.assignment_late_rounded;
        iconColor = Colors.blue;
        break;
      case 'reminder':
        iconBg = const Color(0xFFecfdf5);
        icon = Icons.access_time_filled_rounded;
        iconColor = Colors.green;
        break;
      case 'missed':
        iconBg = const Color(0xFFfff1f2);
        icon = Icons.notification_important_rounded;
        iconColor = Colors.red;
        break;
      default:
        iconBg = Colors.grey.shade100;
        icon = Icons.notifications_rounded;
        iconColor = Colors.grey;
    }

    final time = (notification['time'] as Timestamp?)?.toDate() ?? DateTime.now();

    return GestureDetector(
      onTap: () {
        if (notification['type'] == 'request') {
           Navigator.push(context, MaterialPageRoute(builder: (_) => NewJobRequestScreen(request: notification['data'])));
        } else {
           Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(jobData: notification['data'])));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification['title'],
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(time),
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['body'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
