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
import 'rescue_job_request_screen.dart';
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
  String? _serviceType;
  bool _isAvailable = false;
  bool _isLoading = true;
  StreamSubscription? _requestSubscription;
  StreamSubscription? _rescueBroadcastSubscription;
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
            _serviceType = profile['serviceType'];
            _isAvailable = profile['isAvailable'] ?? false;
            _isLoading = false;
          });
          _setupRequestAutoShow();
          
          // Register FCM token for push notifications
          NotificationService().getAndSaveToken(
            userId: _workerId,
            userType: 'worker',
          );
        }
      }
    }
  }

  void _setupRequestAutoShow() {
    _requestSubscription?.cancel();
    _requestSubscription = _bookingService.streamWorkerRequests(_workerId).listen((requests) {
      _processIncomingRequests(requests);
    });

    // Also listen for broadcast rescue jobs in this worker's category
    if (_serviceType != null) {
      _rescueBroadcastSubscription?.cancel();
      _rescueBroadcastSubscription = _bookingService.streamRescueBroadcasts(_serviceType!).listen((requests) {
        // Only show rescue jobs if worker is available
        if (_isAvailable) {
          _processIncomingRequests(requests);
        }
      });
    }
  }

  void _processIncomingRequests(List<Map<String, dynamic>> requests) {
    if (requests.isNotEmpty) {
      final newestRequest = requests.first;
      final requestId = newestRequest['id'];
      
      // Only show if it's a new request we haven't popped up for yet
      if (requestId != _lastRequestId) {
        _lastRequestId = requestId;
        if (mounted) {
          // Check if this is a rescue job
          final isRescueJob = newestRequest['isRescueJob'] ?? false;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isRescueJob
                  ? RescueJobRequestScreen(request: newestRequest)
                  : NewJobRequestScreen(request: newestRequest),
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
    _rescueBroadcastSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
                  actions: [
                    _buildAvailabilityToggle(),
                  ],
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
          color: _isAvailable ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isAvailable ? const Color(0xFF10B981).withOpacity(0.2) : Colors.transparent,
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
                color: _isAvailable ? const Color(0xFF065F46) : Colors.grey.shade600,
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
    return FutureBuilder<double>(
      future: _workerService.getTodaysEarnings(_workerId),
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
                            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹ ${todaysEarning.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickStat(Icons.trending_up_rounded, 'Earnings', '+12%'),
                  _buildQuickStat(Icons.task_alt_rounded, 'Tasks', '48 Done'),
                ],
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
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildIncomingRequests() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bookingService.streamWorkerRequests(_workerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('New Requests', style: Theme.of(context).textTheme.titleLarge),
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

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
    final bool isRescueJob = req['isRescueJob'] ?? false;
    final int rescueLevel = req['rescueLevel'] ?? 1;
    final double price = (req['price'] as num?)?.toDouble() ?? 0;
    final double bonusAmount = isRescueJob ? price * (rescueLevel == 1 ? 0.05 : rescueLevel == 2 ? 0.07 : 0.10) : 0;
    
    // Rescue job colors
    const Color rescueOrange = Color(0xFFFF6B35);
    const Color rescueOrangeLight = Color(0xFFFF9F6B);
    
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => isRescueJob
                ? RescueJobRequestScreen(request: req)
                : NewJobRequestScreen(request: req),
          ),
        );
        if (mounted) setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: isRescueJob
              ? const LinearGradient(
                  colors: [rescueOrange, rescueOrangeLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isRescueJob
              ? [
                  BoxShadow(
                    color: rescueOrange.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Container(
          margin: isRescueJob ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isRescueJob ? 25.5 : 28),
            border: isRescueJob ? null : Border.all(color: Colors.grey.shade100, width: 1.5),
          ),
          child: Column(
            children: [
              // Rescue Job Badge
              if (isRescueJob)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [rescueOrange, rescueOrangeLight]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🦸', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      const Text(
                        'RESCUE JOB',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      if (bonusAmount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+₹${bonusAmount.toInt()} BONUS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isRescueJob ? rescueOrange.withOpacity(0.1) : const Color(0xFFF1F5F9),
                    child: Icon(
                      isRescueJob ? Icons.local_fire_department_rounded : Icons.person,
                      color: isRescueJob ? rescueOrange : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req['customerName'] ?? 'Customer',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: isRescueJob ? rescueOrange : Colors.blue.shade400),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, hh:mm a').format((req['startTime'] as Timestamp).toDate()),
                              style: TextStyle(color: isRescueJob ? rescueOrange : Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBadge('₹ ${price.toInt()}', isRescueJob ? rescueOrange : Colors.blue),
                      if (isRescueJob && bonusAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+₹${bonusAmount.toInt()} bonus',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
                        _bookingService.updateRequestStatus(req['id'], 'accepted');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRescueJob ? rescueOrange : const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(isRescueJob ? 'Accept & Earn' : 'Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _bookingService.updateRequestStatus(req['id'], 'rejected');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isRescueJob ? rescueOrange : null,
                        side: isRescueJob ? const BorderSide(color: rescueOrange) : null,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(jobData: job)));
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
                  Text(job['customerName'] ?? 'Ongoing Job', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Reach by: ${DateFormat('MMM dd, hh:mm a').format((job['startTime'] as Timestamp).toDate())}',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Insights', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildInsightCard('Orders', '124', Icons.receipt_long_rounded, Colors.purple),
            const SizedBox(width: 12),
            _buildInsightCard('Rating', '4.9', Icons.star_rounded, Colors.amber),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(String label, String value, IconData icon, Color color) {
    return Expanded(
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
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
