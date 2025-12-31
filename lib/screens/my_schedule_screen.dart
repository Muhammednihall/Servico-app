import 'package:flutter/material.dart';
import 'job_details_screen.dart';
import 'worker_dashboard_screen.dart';
import 'earnings_payments_screen.dart';
import 'worker_profile_screen.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  int _selectedTab = 0; // 0 = Upcoming, 1 = Completed
  final Color _primaryColor = const Color(0xFF2463eb);
  final Color _backgroundLight = const Color(0xFFf6f6f8);
  final Color _surfaceDark = const Color(0xFF1e2330);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: Column(
        children: [
          _buildHeader(),
          _buildCalendar(),
          _buildTabs(),
          Expanded(
            child: _buildJobsList(),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, const Color(0xFF60a5fa)],
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: _primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Color(0xFFbfdbfe),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: Colors.grey.shade600),
                    onPressed: () {},
                  ),
                  const Text(
                    'Month 0000',
                    style: TextStyle(
                      color: Color(0xFF1e293b),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: Colors.grey.shade600),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map((day) => Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 35,
                itemBuilder: (context, index) {
                  if (index < 3) {
                    return const SizedBox.shrink();
                  }
                  final day = index - 2;
                  final isSelected = day == 5;
                  final hasJob = [3, 7, 11].contains(day);

                  if (isSelected) {
                    return Container(
                      alignment: Alignment.center,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(36, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hasJob)
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab('Upcoming', 0),
          ),
          Expanded(
            child: _buildTab('Completed', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? _primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? _primaryColor : Colors.grey.shade500,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildJobsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Jobs",
                style: TextStyle(
                  color: Color(0xFF1e293b),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '0',
                  style: TextStyle(
                    color: Color(0xFF64748b),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildJobCard(
                icon: Icons.electric_bolt,
                iconColor: _primaryColor,
                iconBg: const Color(0xFFeff6ff),
                title: 'Electrician Service',
                status: 'Pending',
                statusColor: const Color(0xFFea580c),
                statusBg: const Color(0xFFfff7ed),
                time: '00:00',
                period: 'AM',
              ),
              const SizedBox(height: 16),
              _buildJobCard(
                icon: Icons.plumbing,
                iconColor: const Color(0xFFa855f7),
                iconBg: const Color(0xFFfaf5ff),
                title: 'Plumbing Repair',
                status: 'Confirmed',
                statusColor: const Color(0xFF10b981),
                statusBg: const Color(0xFFecfdf5),
                time: '00:00',
                period: 'PM',
              ),
              const SizedBox(height: 16),
              _buildJobCard(
                icon: Icons.hvac,
                iconColor: const Color(0xFFea580c),
                iconBg: const Color(0xFFfff7ed),
                title: 'HVAC Maintenance',
                status: 'Pending',
                statusColor: const Color(0xFFea580c),
                statusBg: const Color(0xFFfff7ed),
                time: '00:00',
                period: 'PM',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String status,
    required Color statusColor,
    required Color statusBg,
    required String time,
    required String period,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1e293b),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF1e293b),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      period,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade100,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Customer: ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Name',
                      style: TextStyle(
                        color: Color(0xFF1e293b),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Address',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade100,
                  width: 1,
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JobDetailsScreen(),
                    ),
                  );
                },
                child: Text(
                  'View Details',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                isSelected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerDashboardScreen(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.calendar_month,
                label: 'Schedule',
                isSelected: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.attach_money,
                label: 'Earnings',
                isSelected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EarningsPaymentsScreen(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isSelected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? _primaryColor : Colors.grey.shade400,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? _primaryColor : Colors.grey.shade400,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

