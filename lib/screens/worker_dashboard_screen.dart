import 'package:flutter/material.dart';
import 'earnings_payments_screen.dart';
import 'worker_profile_screen.dart';
import 'my_schedule_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _isAvailable = false;
  int _selectedIndex = 0;
  final Color _primaryColor = const Color(0xFF2463eb);
  final Color _backgroundLight = const Color(0xFFf6f6f8);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      // Schedule - navigate to schedule screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyScheduleScreen()),
      ).then((_) {
        setState(() {
          _selectedIndex = 0; // Reset to dashboard after returning
        });
      });
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EarningsPaymentsScreen()),
      ).then((_) {
        setState(() {
          _selectedIndex = 0; // Reset to dashboard after returning
        });
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WorkerProfileScreen()),
      ).then((_) {
        setState(() {
          _selectedIndex = 0; // Reset to dashboard after returning
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 100),
              child: Column(
                children: [
                  _buildAvailabilityStatus(),
                  const SizedBox(height: 20),
                  _buildStatsCards(),
                  const SizedBox(height: 20),
                  _buildOverallRating(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 8),
                  _buildNoRecentActivity(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 64),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, const Color(0xFF3b7bf7), const Color(0xFF60a5fa)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF2463eb),
                  size: 28,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Worker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Positioned(
                top: 8,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _primaryColor,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityStatus() {
    return Transform.translate(
      offset: const Offset(0, -32),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Availability Status',
                    style: TextStyle(
                      color: Color(0xFF1e293b),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'You are currently unavailable',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
                });
              },
              activeColor: _primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.assignment_outlined,
            iconColor: _primaryColor,
            iconBg: const Color(0xFFeff6ff),
            label: 'Current Jobs',
            value: '0',
            badge: 'New',
            badgeColor: _primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.attach_money,
            iconColor: const Color(0xFF10b981),
            iconBg: const Color(0xFFecfdf5),
            label: "Today's Earnings",
            value: '\$0.00',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor?.withOpacity(0.1) ?? iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor ?? iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1e293b),
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFfef3c7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(0xFFf59e0b),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Rating',
                    style: TextStyle(
                      color: Color(0xFF64748b),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '0.0',
                        style: TextStyle(
                          color: Color(0xFF1e293b),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '(0 reviews)',
                        style: TextStyle(
                          color: Color(0xFF94a3b8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'View',
              style: TextStyle(
                color: _primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              color: Color(0xFF1e293b),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.qr_code_scanner,
                label: 'Scan QR',
                color: const Color(0xFFa855f7),
                bgColor: const Color(0xFFfaf5ff),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.headset_mic,
                label: 'Support',
                color: const Color(0xFFea580c),
                bgColor: const Color(0xFFfff7ed),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.calendar_month,
                label: 'Calendar',
                color: const Color(0xFFec4899),
                bgColor: const Color(0xFFfdf2f8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.grey.shade400,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            "No recent activity. Turn on your availability to start receiving jobs.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
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
                isSelected: _selectedIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              _buildNavItem(
                icon: Icons.calendar_month,
                label: 'Schedule',
                isSelected: _selectedIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              _buildNavItem(
                icon: Icons.attach_money,
                label: 'Earnings',
                isSelected: _selectedIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isSelected: _selectedIndex == 3,
                onTap: () => _onItemTapped(3),
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
