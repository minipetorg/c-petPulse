import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/pet.dart';
import '../../services/drive_service.dart';

class EditPetPage extends StatefulWidget {
  final Map<String, String> pet;
  
  const EditPetPage({super.key, required this.pet});

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, String> _editedPet;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _editedPet = Map<String, String>.from(widget.pet);
    print('Received pet data: ${widget.pet}'); // Debug print
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.pet['name']}'),
        backgroundColor: Colors.purple,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : widget.pet['image'] != null
                          ? DecorationImage(
                              image: NetworkImage(widget.pet['image']!),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: _imageFile == null && widget.pet['image'] == null
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.pet['name'],
              decoration: const InputDecoration(
                labelText: 'Pet Name',
                icon: Icon(Icons.pets),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pet name';
                }
                return null;
              },
              onSaved: (value) {
                _editedPet['name'] = value ?? '';
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.pet['breed'],
              decoration: const InputDecoration(
                labelText: 'Breed',
                icon: Icon(Icons.category),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter breed';
                }
                return null;
              },
              onSaved: (value) {
                _editedPet['breed'] = value ?? '';
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.pet['age'],
              decoration: const InputDecoration(
                labelText: 'Age',
                icon: Icon(Icons.calendar_today),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter age';
                }
                return null;
              },
              onSaved: (value) {
                _editedPet['age'] = value ?? '';
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Change Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        final petId = widget.pet['id'];

        // Calculate birthday from age
        final age = int.tryParse(_editedPet['age'] ?? '0') ?? 0;
        final birthday = DateTime.now().subtract(Duration(days: age * 365));

        String? imageUrl = widget.pet['image'];
        if (_imageFile != null) {
          imageUrl = await DriveService.uploadImage(_imageFile!);
          if (imageUrl == null) throw Exception('Failed to upload image');
        }

        final success = await Pet.updatePet(
          petId ?? '',
          {
            'name': _editedPet['name'],
            'breed': _editedPet['breed'],
            'age': _editedPet['age'],
            'type': _editedPet['type'] ?? 'Dog',
            'gender': _editedPet['gender'] ?? 'Male',
            'image': imageUrl,
            'userId': userId,
            'birthday': birthday, // Add calculated birthday
          },
          userId!,
        );

        if (success) {
          Navigator.pop(context, _editedPet);
        } else {
          throw Exception('Failed to update pet');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}