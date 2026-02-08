import 'package:flutter/material.dart';
import 'worker_dashboard_screen.dart';
import 'my_schedule_screen.dart';
import 'earnings_payments_screen.dart';
import 'worker_profile_screen.dart';
import '../widgets/modern_nav_bar.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const WorkerDashboardScreen(),
    const MyScheduleScreen(),
    const EarningsPaymentsScreen(),
    const WorkerProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: ModernNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        items: [
          NavItem(Icons.dashboard_rounded, 'Home'),
          NavItem(Icons.calendar_month_rounded, 'Schedule'),
          NavItem(Icons.payments_rounded, 'Earnings'),
          NavItem(Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }
}
