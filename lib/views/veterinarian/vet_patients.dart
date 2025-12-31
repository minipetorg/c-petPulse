import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/pet.dart';
import '../../../models/veterinarian.dart';
import '../../../models/petOwner.dart';
import '../../../models/appointment.dart';
import 'package:uuid/uuid.dart';

class VetPatientsPage extends StatefulWidget {
  @override
  _VetPatientsPageState createState() => _VetPatientsPageState();
}

class _VetPatientsPageState extends State<VetPatientsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Pet> _pets = [];
  List<Pet> _patients = [];
  bool _isLoading = false;
  String? _error;
  String _selectedPurpose = 'Regular Checkup';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final vet = await Veterinarian.getCurrentUserInfo();
      if (vet == null) {
        setState(() {
          _error = 'Error fetching veterinarian info';
        });
        return;
      }

      if (vet.patients.isEmpty) {
        setState(() {
          _patients = [];
        });
        return;
      }

      final patientsSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where(FieldPath.documentId, whereIn: vet.patients)
          .get();

      setState(() {
        _patients = patientsSnapshot.docs.map((doc) => Pet.fromMap(doc.data(), doc.id)).toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading patients: $e';
      });
    }
  }

  Future<void> _searchPetsByOwnerEmail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _searchController.text.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _error = 'No pet owner found with this email';
          _isLoading = false;
        });
        return;
      }

      final ownerId = querySnapshot.docs.first.id;
      final petsSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('userId', isEqualTo: ownerId)
          .get();

      setState(() {
        _pets = petsSnapshot.docs.map((doc) => Pet.fromMap(doc.data(), doc.id)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error searching pets: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addPetToPatients(Pet pet) async {
    try {
      final vet = await Veterinarian.getCurrentUserInfo();
      if (vet == null) {
        setState(() {
          _error = 'Error fetching veterinarian info';
        });
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('veterinarians').doc(vet.uid);
      await docRef.update({
        'patients': FieldValue.arrayUnion([pet.id])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet added to patients list')),
      );

      _loadPatients();
    } catch (e) {
      setState(() {
        _error = 'Error adding pet to patients: $e';
      });
    }
  }

  Future<void> _createAppointment(Pet pet) async {
    try {
      final vet = await Veterinarian.getCurrentUserInfo();
      if (vet == null) {
        setState(() {
          _error = 'Error fetching veterinarian info';
        });
        return;
      }

      final appointment = Appointment(
        id: Uuid().v4(),
        petId: pet.id!,
        vetId: vet.uid,
        dateTime: DateTime.now(),
        purpose: _selectedPurpose,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      await Appointment.createAppointment(appointment);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment created successfully')),
      );
    } catch (e) {
      setState(() {
        _error = 'Error creating appointment: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet Patients'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Pet Owner Email',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchPetsByOwnerEmail,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            const Text(
              'Patients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _patients.length,
                itemBuilder: (context, index) {
                  final pet = _patients[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(pet.imagePath),
                      ),
                      title: Text(pet.name),
                      subtitle: Text('${pet.type} - ${pet.breed}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showPurposeDialog(pet),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Search Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _pets.length,
                itemBuilder: (context, index) {
                  final pet = _pets[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(pet.imagePath),
                      ),
                      title: Text(pet.name),
                      subtitle: Text('${pet.type} - ${pet.breed}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'add') {
                            _addPetToPatients(pet);
                          } else if (value == 'create') {
                            _showPurposeDialog(pet);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'add',
                            child: Text('Add to Patients'),
                          ),
                          const PopupMenuItem(
                            value: 'create',
                            child: Text('Create Appointment'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurposeDialog(Pet pet) {
    String selectedPurpose = _selectedPurpose;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Purpose'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<String>(
                value: selectedPurpose,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPurpose = newValue!;
                  });
                },
                items: <String>['Regular Checkup', 'Vaccination', 'Medical Issue', 'Grooming', 'Dental Care', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedPurpose = selectedPurpose;
                });
                Navigator.pop(context);
                _createAppointment(pet);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}