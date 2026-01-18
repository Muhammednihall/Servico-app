import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_dashboard_screen.dart';
import 'my_schedule_screen.dart';
import 'worker_profile_screen.dart';
import '../widgets/worker_bottom_nav_bar.dart';
import '../utils/custom_page_route.dart';
import '../services/auth_service.dart';
import '../services/worker_service.dart';

class EarningsPaymentsScreen extends StatefulWidget {
  const EarningsPaymentsScreen({super.key});

  @override
  State<EarningsPaymentsScreen> createState() => _EarningsPaymentsScreenState();
}

class _EarningsPaymentsScreenState extends State<EarningsPaymentsScreen> {
  final Color _primaryColor = const Color(0xFF2463eb);
  final Color _backgroundLight = const Color(0xFFf6f6f8);
  final int _selectedNavIndex = 2; // Earnings is index 2
  
  final AuthService _authService = AuthService();
  final WorkerService _workerService = WorkerService();
  
  late String _workerId;
  double _totalBalance = 0.0;
  double _totalEarned = 0.0;
  DateTime? _nextPayoutDate;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      _workerId = user.uid;
      
      try {
        // Load wallet data
        final wallet = await _workerService.getWorkerWallet(_workerId);
        if (wallet != null) {
          setState(() {
            _totalBalance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
            _totalEarned = (wallet['totalEarned'] as num?)?.toDouble() ?? 0.0;
            if (wallet['nextPayoutDate'] != null) {
              final payoutDate = wallet['nextPayoutDate'];
              if (payoutDate is Timestamp) {
                _nextPayoutDate = payoutDate.toDate();
              } else if (payoutDate is DateTime) {
                _nextPayoutDate = payoutDate;
              }
            }
          });
        }
        
        // Load transactions
        final transactions = await _workerService.getWorkerTransactions(_workerId, limit: 20);
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading earnings data: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        FastPageRoute(
          builder: (context) => const WorkerDashboardScreen(),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        FastPageRoute(
          builder: (context) => const MyScheduleScreen(),
        ),
      );
    } else if (index == 2) {
      // Already on earnings
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        FastPageRoute(
          builder: (context) => const WorkerProfileScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 210, 16, 100),
                  child: Column(
                    children: [
                      _buildPayoutDetailsCard(),
                      const SizedBox(height: 20),
                      _buildRecentTransactions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Card positioned to overlap header
          Positioned(
            top: 120,
            left: 32,
            right: 32,
            child: _buildTotalEarningsCard(),
          ),
        ],
      ),
      bottomNavigationBar: WorkerBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onItemTapped: _onNavItemTapped,
        primaryColor: _primaryColor,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 46),
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Earnings & Payments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalEarningsCard() {
    return AspectRatio(
      aspectRatio: 1.587, // Standard VISA card ratio (3.375 / 2.125)
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1a5f4a),
              const Color(0xFF0d3d2e),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0d3d2e).withValues(alpha: 0.4),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row with chip and logo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chip
                Container(
                  width: 40,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade600,
                        Colors.amber.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade800,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade800,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // VISA Logo
                Text(
                  'VISA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Balance text and amount
            Text(
              'Total Balance',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            // Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  _totalBalance.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Card holder and expiry
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARD HOLDER',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Worker Account',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'VALID THRU',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '12/25',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFeff6ff),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payout Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1e293b),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            icon: Icons.calendar_today,
            title: 'Next Payout',
            value: _nextPayoutDate != null 
                ? '${_nextPayoutDate!.month}/${_nextPayoutDate!.day}/${_nextPayoutDate!.year}'
                : 'Not scheduled',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.account_balance,
            title: 'Total Earned',
            value: '\$${_totalEarned.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Manage Payout Methods',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1e293b),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No transactions yet',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ..._transactions.map((transaction) {
              final isCredit = transaction['type'] == 'credit';
              final amount = (transaction['amount'] as num).toDouble();
              final description = transaction['description'] ?? 'Transaction';
              final createdAt = (transaction['createdAt'] as Timestamp?)?.toDate();
              
              return _buildTransactionItem(
                service: description,
                date: createdAt != null 
                    ? '${createdAt.month}/${createdAt.day}/${createdAt.year}'
                    : 'Unknown date',
                amount: '${isCredit ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                isCredit: isCredit,
                icon: isCredit ? Icons.add_circle : Icons.remove_circle,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String service,
    required String date,
    required String amount,
    required bool isCredit,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCredit
                  ? const Color(0xFFecfdf5)
                  : const Color(0xFFfef2f2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isCredit
                  ? const Color(0xFF10b981)
                  : const Color(0xFFef4444),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isCredit
                  ? const Color(0xFF10b981)
                  : const Color(0xFFef4444),
            ),
          ),
        ],
      ),
    );
  }

}
