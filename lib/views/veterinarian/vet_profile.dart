import 'package:flutter/material.dart';
import 'package:petpulse/models/veterinarian.dart';
import 'package:petpulse/models/clinic.dart';

class VetProfilePage extends StatelessWidget {
  final Veterinarian currentUser;
  final VoidCallback onProfileUpdated;

  const VetProfilePage({
    Key? key,
    required this.currentUser,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.purple,
            child: Icon(
              Icons.person,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currentUser.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Veterinarian',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          // Stats cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(context, '124', 'Patients'),
              _buildStatCard(context, '8', 'Years Exp.'),
              _buildStatCard(context, '18', 'This Week'),
            ],
          ),
          const SizedBox(height: 30),
          // Profile sections
          _buildProfileSection(
            context,
            'Personal Information',
            Icons.info_outline,
            [
              _buildProfileItem('Email', currentUser.email),
              _buildProfileItem('Phone', currentUser.phone),
              _buildProfileItem('License', currentUser.licenseNumber),
            ],
            () {
              _showEditDialog(context, 'Edit Personal Information', currentUser, ['fullName', 'phone', 'licenseNumber']);
            },
          ),
          const SizedBox(height: 16),
          _buildProfileSection(
            context,
            'Expertise',
            Icons.star_outline,
            [
              _buildProfileItem('Specialization', currentUser.specialization),
              _buildProfileItem('Additional', currentUser.additionalInfo),
              _buildProfileItem('Certifications', currentUser.certifications.join(', ')),
            ],
            () {
              _showEditDialog(context, 'Edit Expertise', currentUser, ['specialization', 'additionalInfo', 'certifications']);
            },
          ),
          const SizedBox(height: 16),
          _buildProfileSection(
            context,
            'Clinic Information',
            Icons.business_outlined,
            [
              _buildClinicProfileItem('Clinic', currentUser.clinicID),
              _buildProfileItem('Address', currentUser.address),
              _buildProfileItem('Hours', 'Mon-Fri: 9AM - 5PM'),
            ],
            () {
              _showEditDialog(context, 'Edit Clinic Information', currentUser, ['clinicName', 'address']);
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Implement edit profile functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, String title, IconData icon, List<Widget> items, VoidCallback onEdit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.purple),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicProfileItem(String label, String clinicId) {
    return FutureBuilder<Clinic?>(
      future: Clinic.getClinicById(clinicId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildProfileItem(label, 'Loading...');
        } else if (snapshot.hasError) {
          return _buildProfileItem(label, 'Error loading clinic: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data == null) {
          return _buildProfileItem(label, 'Clinic not found ${clinicId}');
        } else {
          return _buildProfileItem(label, snapshot.data!.name);
        }
      },
    );
  }

  void _showEditDialog(BuildContext context, String title, Veterinarian currentUser, List<String> fields) {
    final fullNameController = TextEditingController(text: currentUser.fullName);
    final phoneController = TextEditingController(text: currentUser.phone);
    final addressController = TextEditingController(text: currentUser.address);
    final clinicNameController = TextEditingController(text: currentUser.clinicID);
    final licenseNumberController = TextEditingController(text: currentUser.licenseNumber);
    final specializationController = TextEditingController(text: currentUser.specialization);
    final additionalInfoController = TextEditingController(text: currentUser.additionalInfo);
    final certificationsController = TextEditingController(text: currentUser.certifications.join(', '));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              children: [
                if (fields.contains('fullName'))
                  TextField(
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    controller: fullNameController,
                  ),
                if (fields.contains('phone'))
                  TextField(
                    decoration: const InputDecoration(labelText: 'Phone'),
                    controller: phoneController,
                  ),
                if (fields.contains('address'))
                  TextField(
                    decoration: const InputDecoration(labelText: 'Address'),
                    controller: addressController,
                  ),
                if (fields.contains('clinicName'))
                  TextField(
                    decoration: const InputDecoration(labelText: 'Clinic Name'),
                    controller: clinicNameController,
                  ),
                if (fields.contains('licenseNumber'))
                  TextField(
                    decoration: const InputDecoration(labelText: 'License Number'),
                    controller: licenseNumberController,
                  ),
                if (fields.contains('specialization'))
                  TextField(
                    decoration: const InputDecoration(labelText: 'Specialization'),
                    controller: specializationController,
                  ),
                if (fields.contains('additionalInfo'))
                  TextField(
                    decoration: const InputDecoration(labelText: 'Additional Info'),
                    controller: additionalInfoController,
                  ),
                if (fields.contains('certifications'))
                  TextField(
                    decoration: const InputDecoration(labelText: 'Certifications (comma separated)'),
                    controller: certificationsController,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = await currentUser.updateProfile(
                  fullName: fullNameController.text,
                  phone: phoneController.text,
                  address: addressController.text,
                  clinicID: clinicNameController.text,
                  licenseNumber: licenseNumberController.text,
                  specialization: specializationController.text,
                  additionalInfo: additionalInfoController.text,
                  certifications: certificationsController.text.split(',').map((e) => e.trim()).toList(),
                );

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(updated ? 'Profile updated successfully' : 'Failed to update profile'),
                    backgroundColor: updated ? Colors.green : Colors.red,
                  ),
                );

                if (updated) {
                  onProfileUpdated();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}