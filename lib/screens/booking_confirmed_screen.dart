import 'package:flutter/material.dart';
import 'customer_home_screen.dart';

class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key});

  final Color _primaryColor = const Color(0xFF2463eb);
  final Color _backgroundLight = const Color(0xFFf6f6f8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                children: [
                  _buildSuccessIcon(),
                  _buildTitle(),
                  _buildServiceSummary(),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
          _buildBottomNavigation(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, const Color(0xFF3b82f6)],
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
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
        child: Row(
          children: [
            IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Text(
                'Confirmation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Transform.translate(
      offset: const Offset(0, -32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFecfdf5),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF10b981),
                size: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'Booking Confirmed!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0e121b),
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long,
                color: _primaryColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Ref ID: 0',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceSummary() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SERVICE SUMMARY',
                style: TextStyle(
                  color: Color(0xFF64748b),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View Details',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.build,
                  size: 48,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Electrician Service',
                      style: TextStyle(
                        color: Color(0xFF0e121b),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Name',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFeef2ff),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFc7d2fe),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smart_toy,
                            size: 14,
                            color: const Color(0xFF6366f1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI Matched',
                            style: TextStyle(
                              color: const Color(0xFF6366f1),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade100,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  icon: Icons.calendar_month,
                  iconColor: const Color(0xFFea580c),
                  iconBg: const Color(0xFFfff7ed),
                  label: 'Date & Time',
                  value: '00/00/0000 • 00:00 AM',
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  icon: Icons.location_on,
                  iconColor: _primaryColor,
                  iconBg: const Color(0xFFeff6ff),
                  label: 'Location',
                  value: '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Row(
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
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (value.isNotEmpty)
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0e121b),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const CustomerHomeScreen(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              shadowColor: _primaryColor.withOpacity(0.3),
            ),
            child: const Text(
              'Go to Bookings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Colors.red.shade200,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel Booking',
              style: TextStyle(
                color: Color(0xFFef4444),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Free cancellation available until 00:00 AM on 00/00/0000.\nAfter that, a fee may apply.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade100,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                isSelected: false,
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const CustomerHomeScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.search_outlined,
                label: 'Search',
                isSelected: false,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.calendar_today,
                label: 'Bookings',
                isSelected: true,
                onTap: () {},
                showDot: true,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isSelected: false,
                onTap: () {},
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
    bool showDot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(
                icon,
                color: isSelected ? _primaryColor : Colors.grey.shade400,
                size: 24,
              ),
              if (showDot)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
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

