import 'package:flutter/material.dart';
import 'worker_dashboard_screen.dart';
import 'my_schedule_screen.dart';
import 'earnings_payments_screen.dart';
import 'worker_profile_screen.dart';
import '../widgets/worker_bottom_nav_bar.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  int _selectedIndex = 0;
  final Color _primaryColor = const Color(0xFF2463eb);

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
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: WorkerBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        primaryColor: _primaryColor,
      ),
    );
  }
}
