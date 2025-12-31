import 'package:flutter/material.dart';
import '../../../models/pet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../models/user.dart' as petpulse_user;
import '../../../models/medical_record.dart'; // Add this import

class CompanionTab extends StatelessWidget {
  final Map<String, String> currentPet;

  const CompanionTab({
    Key? key, 
    required this.currentPet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String petType = currentPet['type'] ?? '';
    String petGender = currentPet['gender'] ?? '';
    String petBreed = currentPet['breed'] ?? ''; // Get the breed
    final authService = AuthService();

    return StreamBuilder<List<Pet>>(
      stream: Stream.fromFuture(Pet.getPetsByType(
        type: petType, 
        currentPetGender: petGender,
        breed: petBreed // Pass the breed parameter
      )),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final companions = snapshot.data?.map((pet) => {
          'id': pet.id ?? '',
          'name': pet.name,
          'breed': pet.breed,
          'age': pet.age,
          'image': pet.imagePath,
          'type': pet.type,
          'gender': pet.gender,
          'userId': pet.userId,
          'birthday': pet.BD?.toIso8601String() ?? '',
        }).toList() ?? [];

        return ListView.builder(
          itemCount: companions.length,
          itemBuilder: (context, index) {
            final companion = companions[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder<String>(
                future: authService.getUserType().then((userType) {
                  return petpulse_user.User.getUserFullName(companion['userId'] ?? '', userType ?? 'user');
                }),
                builder: (context, snapshot) {
                  return CompanionCard(
                    id: companion['id'] ?? '', // Add this
                    owner: snapshot.data ?? 'Loading...', 
                    name: companion['name'] ?? '', 
                    breed: companion['breed'] ?? '',
                    age: companion['age'] ?? '',
                    distance: '10 km',
                    image: companion['image'] ?? '',
                    type: companion['type'] ?? '',
                    gender: companion['gender'] ?? '',
                    BD: DateTime.parse(companion['birthday'] ?? DateTime.now().toIso8601String()),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class CompanionCard extends StatelessWidget {
  final String id; // Add this field
  final String name;
  final String breed;
  final String age;
  final String distance;
  final String image;
  final String type;
  final String gender;
  final String owner;
  final DateTime BD;

  const CompanionCard({
    super.key,
    required this.id, // Add this
    required this.name,
    required this.breed,
    required this.age,
    required this.distance,
    required this.image,
    required this.type,
    required this.gender,
    required this.owner,
    required this.BD,
  });
  
  @override
  Widget build(BuildContext context) {
    final birthday = Pet.calculateAge(BD.toString());
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: () => _showPetDetails(context),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: image.isNotEmpty
                ? NetworkImage(image)
                : Pet.getPetIcon(type),
            backgroundColor: Colors.purple[100],
          ),
          title: Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                gender.toLowerCase() == 'male' ? Icons.male : Icons.female,
                size: 16,
                color: gender.toLowerCase() == 'male' ? Colors.blue : Colors.pink,
              ),
            ],
          ),
          subtitle: Text('$breed\n$birthday\n$distance\nOwner: $owner'),
          isThreeLine: true,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  void _showPetDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pet header with image and basic info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple[50]!,
                      Colors.purple[100]!,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: image.isNotEmpty == true 
                          ? NetworkImage(image)
                          : Pet.getPetIcon(type),
                      backgroundColor: Colors.purple[100],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                gender.toLowerCase() == 'male' ? Icons.male : Icons.female,
                                size: 18,
                                color: gender.toLowerCase() == 'male' ? Colors.blue : Colors.pink,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            breed,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.purple[700],
                            ),
                          ),
                          Text(
                            Pet.calculateAge(BD.toString()),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.purple[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: $owner',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.purple[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Pet details - health records, vaccination details, etc.
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Health Summary'),
                      _buildPetHealthSummary(),
                      
                      const SizedBox(height: 16),
                      _buildSectionHeader('Vaccination Status'),
                      _buildVaccinationList(),
                      
                      const SizedBox(height: 16),
                      _buildSectionHeader('Medical History'),
                      _buildMedicalHistory(),
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Implement message functionality
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildPetHealthSummary() {
    return FutureBuilder<MedicalRecord?>(
      future: MedicalRecord.getLatestMedicalRecordByPetId(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildInfoCard(
            icon: Icons.warning_amber,
            title: 'Health Status',
            description: 'No health data available',
            color: Colors.grey,
          );
        }
        
        final medicalRecord = snapshot.data!;
        return Column(
          children: [
            _buildInfoCard(
              icon: Icons.favorite,
              title: 'Health Status',
              description: medicalRecord.medicalNotes.isNotEmpty 
                  ? 'Recent checkup: ${medicalRecord.dateTime.toLocal().toString().split(' ')[0]}' 
                  : 'No details available',
              color: Colors.green,
            ),
            _buildInfoCard(
              icon: Icons.monitor_weight,
              title: 'Weight',
              description: '${medicalRecord.petWeight} kg',
              color: Colors.orange,
            ),
            if (medicalRecord.treatments.isNotEmpty)
              _buildInfoCard(
                icon: Icons.medical_services,
                title: 'Recent Treatments',
                description: medicalRecord.treatments.join(', '),
                color: Colors.blue,
              ),
          ],
        );
      },
    );
  }

  Widget _buildVaccinationList() {
    return FutureBuilder<MedicalRecord?>(
      future: MedicalRecord.getLatestMedicalRecordByPetId(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No vaccination records found'),
            ),
          );
        }
        
        final medicalRecord = snapshot.data!;
        
        if (!medicalRecord.isVaccined) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No vaccination records found'),
            ),
          );
        }
        
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.check, color: Colors.white),
            ),
            title: Text(medicalRecord.vaccineType),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Administered: ${medicalRecord.dateTime.toLocal().toString().split(' ')[0]}'),
                if (medicalRecord.nextDoseDate != null)
                  Text(
                    'Next dose: ${medicalRecord.nextDoseDate!.toLocal().toString().split(' ')[0]}',
                    style: TextStyle(
                      color: medicalRecord.nextDoseDate!.isAfter(DateTime.now()) 
                          ? Colors.green[700] 
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedicalHistory() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllMedicalRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        
        final records = snapshot.data ?? [];
        
        if (records.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No medical records found'),
            ),
          );
        }
        
        return Column(
          children: records.map((record) {
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.healing, color: Colors.white),
                ),
                title: Text('Checkup on: ${record['date']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weight: ${record['weight']} kg'),
                    Text('Notes: ${record['notes']}'),
                    if (record['treatments'] != null && (record['treatments'] as List).isNotEmpty)
                      Text('Treatments: ${(record['treatments'] as List).join(", ")}'),
                    if (record['isVaccined'] == true)
                      Text(
                        'Vaccinated: ${record['vaccineType']}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  _showMedicalRecordDetails(context, record['id']);
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllMedicalRecords() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('medical_records')
          .where('petId', isEqualTo: id)
          .orderBy('dateTime', descending: true)
          .get();
          
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        DateTime dateTime;
        
        if (data['dateTime'] is Timestamp) {
          dateTime = (data['dateTime'] as Timestamp).toDate();
        } else {
          dateTime = DateTime.parse(data['dateTime'].toString());
        }
        
        return {
          'id': doc.id,
          'date': dateTime.toLocal().toString().split(' ')[0],
          'weight': data['petWeight']?.toDouble() ?? 0.0,
          'notes': data['medicalNotes'] ?? 'No notes',
          'treatments': data['treatments'] ?? [],
          'isVaccined': data['isVaccined'] ?? false,
          'vaccineType': data['vaccineType'] ?? '',
          'vetId': data['vetId'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching medical records: $e');
      return [];
    }
  }

  void _showMedicalRecordDetails(BuildContext context, String recordId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final record = await MedicalRecord.getMedicalRecordById(recordId);
      
      // Pop loading dialog
      Navigator.pop(context);
      
      if (record == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record not found')),
        );
        return;
      }
      
      // Show detailed record
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Medical Record Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Date: ${record.dateTime.toLocal().toString().split(' ')[0]}'),
                const SizedBox(height: 8),
                Text('Weight: ${record.petWeight} kg'),
                const SizedBox(height: 8),
                Text('Notes: ${record.medicalNotes}'),
                const SizedBox(height: 8),
                if (record.treatments.isNotEmpty) ...[
                  const Text('Treatments:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...record.treatments.map((t) => Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text('• $t'),
                  )).toList(),
                  const SizedBox(height: 8),
                ],
                if (record.isVaccined) ...[
                  const Text('Vaccination:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${record.vaccineType}'),
                        if (record.nextDoseDate != null)
                          Text('Next dose: ${record.nextDoseDate!.toLocal().toString().split(' ')[0]}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Pop loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
