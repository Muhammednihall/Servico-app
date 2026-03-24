import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/worker_service.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import 'job_details_screen.dart';
import '../widgets/modern_header.dart';
import '../widgets/worker_notification_popup.dart';
import 'new_job_request_screen.dart';
import 'worker_reviews_screen.dart';
import 'service_records_screen.dart';
import 'dart:async';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  final AuthService _authService = AuthService();
  final WorkerService _workerService = WorkerService();
  final BookingService _bookingService = BookingService();

  late String _workerId;
  String? _workerName;
  String? _workerCategory;
  bool _isAvailable = false;
  bool _isLoading = true;
  StreamSubscription? _requestSubscription;
  String? _lastRequestId;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      _workerId = user.uid;
      final profile = await _workerService.getWorkerProfile(_workerId);
      if (profile != null) {
        if (mounted) {
          setState(() {
            _workerName = profile['name'];
            _workerCategory = profile['category'] ?? profile['serviceType'];
            _isAvailable = profile['isAvailable'] ?? false;
            _isLoading = false;
          });
          _setupRequestAutoShow();

          // Register FCM token for push notifications
          NotificationService().getAndSaveToken(
            userId: _workerId,
            userType: 'worker',
          );

          // Start client-side notification sync (backup for Cloud Functions)
          NotificationService().startListeningToFirestoreNotifications(
            _workerId, 
            'worker',
          );
        }
      }
    }
  }

  void _setupRequestAutoShow() {
    _requestSubscription?.cancel();
    _requestSubscription = _bookingService
        .streamWorkerRequests(_workerId, workerCategory: _workerCategory)
        .listen((requests) {
          _processIncomingRequests(requests);
        });
  }

  void _processIncomingRequests(List<Map<String, dynamic>> requests) {
    if (requests.isNotEmpty) {
      final newestRequest = requests.first;
      final requestId = newestRequest['id'];

      // Only show if it's a new request we haven't popped up for yet
      if (requestId != _lastRequestId) {
        _lastRequestId = requestId;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
            builder: (context) => NewJobRequestScreen(
              request: newestRequest,
              workerId: _workerId,
              workerName: _workerName ?? 'Worker',
            ),
            ),
          ).then((_) {
            if (mounted) setState(() {});
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return WorkerNotificationPopup(
      workerId: _workerId,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            StreamBuilder<Map<String, dynamic>?>(
              stream: _workerService.streamWorkerProfile(_workerId),
              builder: (context, snapshot) {
                final name = snapshot.data?['name'] ?? 'Worker';
                return ModernHeader(
                  title: name,
                  subtitle: 'Welcome back,',
                  actions: [_buildAvailabilityToggle()],
                );
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadWorkerData();
                  setState(() {});
                },
                color: const Color(0xFF2463EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBanner(),
                      const SizedBox(height: 32),
                      _buildIncomingRequests(),
                      const SizedBox(height: 32),
                      _buildActiveJobs(),
                      const SizedBox(height: 32),
                      _buildStatsGrid(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return GestureDetector(
      onTap: () async {
        final newStatus = !_isAvailable;
        setState(() => _isAvailable = newStatus);
        await _workerService.updateAvailability(_workerId, newStatus);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isAvailable
              ? const Color(0xFF10B981).withOpacity(0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isAvailable
                ? const Color(0xFF10B981).withOpacity(0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isAvailable ? const Color(0xFF10B981) : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isAvailable ? 'Online' : 'Offline',
              style: TextStyle(
                color: _isAvailable
                    ? const Color(0xFF065F46)
                    : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return StreamBuilder<double>(
      stream: _workerService.streamTodaysEarnings(_workerId),
      builder: (context, snapshot) {
        final todaysEarning = snapshot.data ?? 0.0;
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Today's Earning",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹ ${todaysEarning.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF10B981),
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(height: 1, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 24),
              StreamBuilder<Map<String, dynamic>?>(
                stream: _workerService.streamWorkerProfile(_workerId),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final accepted = (profile?['acceptedRequests'] as num?)?.toInt() ?? 0;
                  final rate = (profile?['acceptanceRate'] as num?)?.toDouble();
                  final rateStr = rate != null ? '${rate.toStringAsFixed(0)}%' : '--';

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickStat(
                        Icons.task_alt_rounded,
                        'Accepted',
                        '$accepted Jobs',
                      ),
                      _buildQuickStat(
                        Icons.percent_rounded,
                        'Accept Rate',
                        rateStr,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.5), size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncomingRequests() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bookingService.streamWorkerRequests(_workerId, workerCategory: _workerCategory),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Requests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _buildBadge('${snapshot.data!.length}', Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            ...snapshot.data!.map((req) => _buildRequestCard(req)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildActiveJobs() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bookingService.streamActiveJobs(_workerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Jobs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...snapshot.data!.map((job) => _buildJobCard(job)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final double price = (req['price'] as num?)?.toDouble() ?? 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewJobRequestScreen(
              request: req,
              workerId: _workerId,
              workerName: _workerName ?? 'Worker',
            ),
          ),
        );
        if (mounted) setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.person, color: Color(0xFF475569)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            req['customerName'] ?? 'Customer',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (req['isRescueJob'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                'RESCUE JOB',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.blue.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, hh:mm a').format(
                              (req['startTime'] ??
                                          req['scheduledTime'] ??
                                          req['estimatedStartTime'] ??
                                          req['createdAt'] as Timestamp?)
                                      ?.toDate() ??
                                  DateTime.now(),
                            ),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBadge('₹ ${price.toInt()}', Colors.blue),
                    if (req['isRescueJob'] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ₹150 Bonus',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _bookingService.acceptBooking(
                        req['id'],
                        _workerId,
                        _workerName ?? 'Worker',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _bookingService.rejectBooking(
                        req['id'],
                        _workerId,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailsScreen(jobData: job)),
        );
        if (mounted) setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.work_rounded, color: Color(0xFF2463EB), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['customerName'] ?? 'Ongoing Job',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reach by: ${DateFormat('MMM dd, hh:mm a').format((job['startTime'] ?? job['scheduledTime'] ?? job['estimatedStartTime'] ?? job['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now())}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Insights', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        StreamBuilder<Map<String, dynamic>?>(
          stream: _workerService.streamWorkerProfile(_workerId),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final rating = (profile?['rating'] as num?)?.toDouble() ?? 0.0;
            final totalReviews = (profile?['totalReviews'] as num?)?.toInt() ?? 0;
            final acceptedRequests = (profile?['acceptedRequests'] as num?)?.toInt() ?? 0;
            final acceptanceRate = (profile?['acceptanceRate'] as num?)?.toDouble();

            final ratingStr = ((rating == 0.0 && totalReviews == 0) || profile?['rating'] == null)
                ? '5.0'
                : rating.toStringAsFixed(1);
            final acceptanceStr = acceptanceRate != null
                ? '${acceptanceRate.toStringAsFixed(0)}%'
                : '--';

            return Column(
              children: [
                Row(
                  children: [
                    StreamBuilder<int>(
                      stream: _bookingService.streamCompletedJobsCount(_workerId),
                      builder: (context, countSnapshot) {
                        return _buildInsightCard(
                          'Completed',
                          '${countSnapshot.data ?? 0}',
                          Icons.receipt_long_rounded,
                          Colors.purple,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ServiceRecordsScreen(userRole: 'worker')),
                          ),
                        );
                      }
                    ),
                    const SizedBox(width: 12),
                    _buildInsightCard(
                      'Rating',
                      ratingStr,
                      Icons.star_rounded,
                      Colors.amber,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WorkerReviewsScreen(workerId: _workerId)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInsightCard(
                      'Reviews',
                      '$totalReviews',
                      Icons.reviews_rounded,
                      Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WorkerReviewsScreen(workerId: _workerId)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildInsightCard(
                      'Acceptance',
                      acceptanceStr,
                      Icons.check_circle_rounded,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
