
import 'package:flutter/material.dart';

class JobDetailsScreen extends StatelessWidget {
  const JobDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerInfoCard(),
            const SizedBox(height: 20),
            _buildJobDetailsCard(),
            const SizedBox(height: 20),
            _buildLocationCard(),
            const SizedBox(height: 20),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Placeholder
            ),
            SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Name',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Text('5.0'),
                  ],
                ),
              ],
            ),
            Spacer(),
            Icon(Icons.message, color: Colors.deepPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildDetailRow(icon: Icons.category, title: 'Service', subtitle: 'House Cleaning'),
            _buildDetailRow(icon: Icons.calendar_today, title: 'Date', subtitle: 'Dec 30, 2025'),
            _buildDetailRow(icon: Icons.access_time, title: 'Time', subtitle: '10:00 AM'),
            _buildDetailRow(icon: Icons.hourglass_bottom, title: 'Duration', subtitle: '2 hours'),
            const Divider(height: 20),
            const Text(
              'Special Instructions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Please bring your own cleaning supplies. The dog is friendly.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('123 Main Street, Anytown, USA'),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                    image: NetworkImage('https://via.placeholder.com/400x225.png?text=Map+View'), // Placeholder for map
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () {
            // TODO: Implement Start Job
          },
          child: const Text('Start Job'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () {
            // TODO: Implement Cancel Job
          },
          child: const Text('Cancel Job'),
        ),
      ],
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
