import 'package:flutter/material.dart';

class CompanionPage extends StatelessWidget {
  const CompanionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Veterinary Services',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildServiceCard(
            'Regular Checkup',
            'Schedule a routine checkup for your pet',
            Icons.medical_services,
          ),
          _buildServiceCard(
            'Vaccination',
            'Keep your pet protected with timely vaccinations',
            Icons.vaccines,
          ),
          _buildServiceCard(
            'Emergency Care',
            '24/7 emergency veterinary services',
            Icons.emergency,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Colors.purple),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(description),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Book service functionality
              },
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }
}