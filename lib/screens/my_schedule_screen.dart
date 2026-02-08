import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../widgets/modern_header.dart';
import 'job_details_screen.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  int _selectedTab = 0; // 0 = Upcoming, 1 = Completed
  final Color _primaryColor = const Color(0xFF2463eb);

  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _jobsByDay = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    if (user == null) {
      return const Center(child: Text('Please login'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          ModernHeader(
            title: 'Schedule',
            subtitle: 'Manage your',
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _selectedTab == 0
                  ? _bookingService.streamUpcomingSchedule(user.uid)
                  : _bookingService.streamWorkerCompletedJobs(user.uid),
              builder: (context, snapshot) {
                final allJobs = snapshot.data ?? [];
                _groupJobsByDay(allJobs);

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildCalendar(),
                    _buildTabs(),
                    _buildJobsList(
                      _selectedTab == 0 ? "Upcoming" : "Completed",
                    ),
                    const SizedBox(height: 120),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _groupJobsByDay(List<Map<String, dynamic>> jobs) {
    _jobsByDay = {};
    for (var job in jobs) {
      final timestamp = (job['startTime'] ?? job['createdAt']) as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        final day = DateTime(date.year, date.month, date.day);
        if (_jobsByDay[day] == null) _jobsByDay[day] = [];
        _jobsByDay[day]!.add(job);
      }
    }
  }

  Widget _buildCalendar() {
    final daysInMonth = DateTime(
      _focusedDay.year,
      _focusedDay.month + 1,
      0,
    ).day;
    final firstDayOfMonth =
        DateTime(_focusedDay.year, _focusedDay.month, 1).weekday % 7;
    
    // Calculate actual rows needed
    final totalCells = firstDayOfMonth + daysInMonth;
    final rowsNeeded = (totalCells / 7).ceil();
    final itemCount = rowsNeeded * 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(
                    () => _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month - 1,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedDay),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(
                    () => _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month + 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (d) => Text(
                      d,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 2),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 2.5,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final dayNum = index - firstDayOfMonth + 1;
                if (dayNum < 1 || dayNum > daysInMonth)
                  return const SizedBox.shrink();

                final date = DateTime(
                  _focusedDay.year,
                  _focusedDay.month,
                  dayNum,
                );
                final isSelected = _selectedDay == date;
                final hasJobs = _jobsByDay.containsKey(date);
                final isToday = DateTime.now().day == dayNum &&
                    DateTime.now().month == _focusedDay.month &&
                    DateTime.now().year == _focusedDay.year;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? Colors.white.withOpacity(0.1)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF1E293B)
                                : Colors.white.withOpacity(0.9),
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        if (hasJobs && !isSelected)
                          Positioned(
                            bottom: 6,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _TabItem(
            label: 'Upcoming',
            index: 0,
            isSelected: _selectedTab == 0,
            onTap: (i) => setState(() => _selectedTab = i),
          ),
          const SizedBox(width: 12),
          _TabItem(
            label: 'Completed',
            index: 1,
            isSelected: _selectedTab == 1,
            onTap: (i) => setState(() => _selectedTab = i),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList(String title) {
    final jobsAtDate = _jobsByDay[_selectedDay] ?? [];

    // Sort jobs at this date by time
    jobsAtDate.sort((a, b) {
      final t1 = (a['startTime'] ?? a['createdAt']) as Timestamp?;
      final t2 = (b['startTime'] ?? b['createdAt']) as Timestamp?;
      if (t1 == null || t2 == null) return 0;
      return t1.compareTo(t2);
    });

    if (jobsAtDate.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No jobs for this date',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobsAtDate.length,
      itemBuilder: (context, index) {
        final job = jobsAtDate[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailsScreen(jobData: job),
              ),
            );
          },
          child: _JobCard(job: job, primaryColor: _primaryColor),
        );
      },
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final int index;
  final bool isSelected;
  final Function(int) onTap;

  const _TabItem({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2463eb) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2463eb)
                  : Colors.grey.shade200,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final Color primaryColor;

  const _JobCard({required this.job, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final timestamp = (job['startTime'] ?? job['createdAt']) as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.settings_suggest_rounded,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['serviceName'] ?? 'Service',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      job['customerName'] ?? 'Customer',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (job['status'] == 'pending' ? Colors.orange : Colors.blue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (job['status'] ?? 'accepted').toString().toUpperCase(),
                        style: TextStyle(
                          color: (job['status'] == 'pending' ? Colors.orange : Colors.blue),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timeStr,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job['customerAddress'] ?? 'No address',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: job['status'] == 'completed'
                      ? Colors.green.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (job['status'] as String).toUpperCase(),
                  style: TextStyle(
                    color: job['status'] == 'completed'
                        ? Colors.green
                        : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
