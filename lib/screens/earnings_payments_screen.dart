import 'package:flutter/material.dart';

class EarningsPaymentsScreen extends StatelessWidget {
  const EarningsPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Payments'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTotalEarningsCard(),
          const SizedBox(height: 20),
          _buildPayoutDetailsCard(),
          const SizedBox(height: 20),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildTotalEarningsCard() {
    return Card(
      elevation: 4,
      color: Colors.deepPurple[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Total Earnings',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            SizedBox(height: 10),
            Text(
              '\$1,234.56',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payout Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildDetailRow(title: 'Next Payout', value: 'Jan 5, 2026'),
            _buildDetailRow(title: 'Payout Method', value: 'Bank Account **** 1234'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement Manage Payout
              },
              child: const Text('Manage Payout Methods'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildTransactionItem(
          service: 'House Cleaning',
          date: 'Dec 28, 2025',
          amount: '+\$50.00',
          isCredit: true,
        ),
        _buildTransactionItem(
          service: 'Plumbing Fix',
          date: 'Dec 27, 2025',
          amount: '+\$75.00',
          isCredit: true,
        ),
        _buildTransactionItem(
          service: 'Service Fee',
          date: 'Dec 26, 2025',
          amount: '-\$5.00',
          isCredit: false,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            // TODO: Implement View All Transactions
          },
          child: const Text('View All Transactions'),
        ),
      ],
    );
  }

  Widget _buildDetailRow({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String service,
    required String date,
    required String amount,
    required bool isCredit,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isCredit ? Colors.green : Colors.red,
        ),
        title: Text(service),
        subtitle: Text(date),
        trailing: Text(
          amount,
          style: TextStyle(
            color: isCredit ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
