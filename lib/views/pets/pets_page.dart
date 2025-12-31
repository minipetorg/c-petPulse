import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_pet_page.dart';
import 'edit_pet_page.dart';
import 'pet_details_page.dart';
import '../../models/pet.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/location.dart';
import 'package:permission_handler/permission_handler.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  Map<String, bool> _trackedPets = {};
  Map<String, bool> _loadingPets = {};  // Add loading state map

  Future<void> _startTracking(Map<String, String> pet) async {
    final petId = pet['id'] ?? '';
    setState(() => _loadingPets[petId] = true);
    
    try {
      final hasPermission = await Permission.location.request();
      if(hasPermission.isGranted){
        final position = await Geolocator.getCurrentPosition();
        
        final location = Location(
          id: '',
          petId: pet['id'] ?? '',
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
        );

        final success = await Location.updateLocation(location);

        if (success && mounted) {
          setState(() {
            _trackedPets[pet['id'] ?? ''] = true;
            _loadingPets[petId] = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location updated for ${pet['name']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('Failed to update location');
        }
      }
    } catch (e) {
      print('Error tracking location: $e');
      if (mounted) {
        setState(() => _loadingPets[petId] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update location'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _editPet(BuildContext context, Map<String, String> pet) async {
    print('Editing pet with ID: ${pet['id']}'); // Debug print
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPetPage(
          pet: pet,
        ),
      ),
    );
  }

  void _showPetDetails(BuildContext context, Map<String, String> pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailsPage(pet: pet),
      ),
    );
  }
  void _addNewPet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPetPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: userId == null 
        ? const Center(child: Text('Please login to view pets'))
        : StreamBuilder<List<Pet>>(
            stream: Pet.getPetsByUser(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final pets = snapshot.data?.map((pet) {
                return {
                  'id': pet.id ?? '',
                  'name': pet.name,
                  'breed': pet.breed,
                  'age': pet.age,
                  'image': pet.imagePath,
                  'type': pet.type,
                  'gender': pet.gender,
                  'userId': pet.userId,
                  'birthday': pet.BD?.toIso8601String() ?? '', // Convert DateTime to String
                };
              }).toList() ?? [];

              return ListView.builder(
                itemCount: pets.length,
                itemBuilder: (context, listIndex) {
                  final pet = Map<String, String>.from(pets[listIndex]);
                  return GestureDetector(
                    onTap: () => _showPetDetails(context, pet),
                    child: Card(
                      margin: const EdgeInsets.all(10.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: pet['image']?.isNotEmpty == true 
                              ? NetworkImage(pet['image']!)
                              : Pet.getPetIcon(pet['type']),
                          backgroundColor: const Color.fromARGB(139, 0, 12, 30),
                        ),
                        title: Row(
                          children: [
                            Text(
                              pet['name'] ?? 'No Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold
                              ),
                              ),
                            const SizedBox(width: 8),
                                Icon(
                                  pet['gender']?.toLowerCase() == 'male' ? Icons.male : Icons.female,
                                  size: 16,
                                  color: pet['gender']?.toLowerCase() == 'male' ? Colors.blue : Colors.pink,
                                ),
                          ],
                        ),
                        subtitle: Text(
                          '${pet['breed'] ?? 'Unknown'}\n${pet['age']?.isEmpty ?? true ? 'Unknown' : '${Pet.calculateAge(pet['birthday'] ?? '')}'}',
                          style: TextStyle(
                            fontSize: 12
                          ),
                          ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                            children: [
                            IconButton(
                              icon: const Icon(
                              Icons.public_sharp,
                              color: Color.fromARGB(255, 123, 123, 123),
                              size: 20,
                              ),
                              onPressed: () {
                              // Add handler for new icon
                              },
                            ),
                            const SizedBox(width: 0), // Add horizontal spacing
                            IconButton(
                              icon: _loadingPets[pet['id']] == true
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                                      ),
                                    )
                                  : Icon(
                                      Icons.location_searching,
                                      color: _trackedPets[pet['id']] == true 
                                          ? Colors.purple 
                                          : const Color.fromARGB(255, 144, 145, 145),
                                      size: 20,
                                    ),
                              onPressed: _loadingPets[pet['id']] == true
                                  ? null
                                  : () => _startTracking(pet),
                            ),
                            const SizedBox(width: 0), // Add horizontal spacing
                            IconButton(
                              icon: const Icon(
                              Icons.edit,
                              color: Colors.purple,
                              size: 20,
                              ),
                              onPressed: () => _editPet(context, pet),
                            ),
                            ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPet,
        backgroundColor: Colors.purple,
        heroTag: 'addPet',
        child: const Icon(Icons.add),
      ),
    );
  }
}