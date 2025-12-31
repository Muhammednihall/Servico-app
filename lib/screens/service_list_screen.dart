import 'package:flutter/material.dart';
import 'booking_confirmed_screen.dart';

class ServiceListScreen extends StatelessWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electrician Services'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for specific services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterDropdown(
                  context: context,
                  value: 'Rating 4.0+',
                  items: ['Rating 4.0+', 'Rating 3.0+', 'Rating 2.0+'],
                ),
                _buildFilterDropdown(
                  context: context,
                  value: 'Price',
                  items: ['Price: Low to High', 'Price: High to Low'],
                ),
                _buildFilterDropdown(
                  context: context,
                  value: 'Distance',
                  items: ['Under 5 miles', 'Under 10 miles', 'Any'],
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: 4, // Replace with actual data
                itemBuilder: (context, index) {
                  return _buildServiceProviderCard(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
  }) {
    return DropdownButton<String>(
      value: value,
      onChanged: (String? newValue) {},
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildServiceProviderCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  child: Icon(Icons.person, size: 26),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'John Electric',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 16.0),
                          SizedBox(width: 4),
                          Text('4.8'),
                          SizedBox(width: 8),
                          Text('(120 reviews)', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text('\$35/hr', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('2.3 mi', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            const Text(
              'Certified electrician with 10+ years experience in residential wiring and repairs.',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12.0),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('Verified'), avatar: Icon(Icons.verified, color: Colors.blue), backgroundColor: Color(0xFFE8F0FE)),
                Chip(label: Text('Quick Response')),
                Chip(label: Text('Warranty')),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('View Profile'),
                ),
                const Spacer(),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookingConfirmedScreen(),
                        ),
                      );
                    },
                    child: const Text('Book Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
