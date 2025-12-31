import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart'; // Add this import
import '../../models/pet.dart';

bool _isLoading = false;

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _yearsController = TextEditingController();
  final _monthsController = TextEditingController();
  DateTime? _selectedBirthday;
  String _selectedType = 'Dog';
  String _selectedGender = 'Male';
  File? _imageFile;
  bool _isLoading = false;
  bool _useAgeInput = true; // Toggle between age input and birthday picker

  final List<String> _petTypes = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];
  final List<String> _genderOptions = ['Male', 'Female'];

  // Add breed lists
  static const Map<String, List<String>> _breedSuggestions = {
    'Dog': [
      'Other',
      'Labrador Retriever',
      'German Shepherd',
      'Golden Retriever',
      'French Bulldog',
      'Bulldog',
      'Poodle',
      'Beagle',
      'Rottweiler',
      'Husky',
    ],
    'Cat': [
      'Other',
      'Persian',
      'Maine Coon',
      'Siamese',
      'British Shorthair',
      'Ragdoll',
      'Bengal',
      'Sphynx',
      'Russian Blue',
      'American Shorthair',
    ],
    'Bird': [
      'Other',
      'Budgerigar',
      'Cockatiel',
      'Lovebird',
      'Canary',
      'African Grey Parrot',
      'Cockatoo',
      'Finch',
      'Macaw',
      'Conure',
    ],
    'Rabbit': [
      'Other',
      'Holland Lop',
      'Mini Rex',
      'Dutch',
      'Netherland Dwarf',
      'Lionhead',
      'French Lop',
      'English Angora',
      'Mini Lop',
      'Flemish Giant',
    ],
  };

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('pet_images')
          .child('${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}');

      if (kIsWeb) {
        // Web platform upload
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'picked-file-path': _imageFile!.path},
        );
        
        final bytes = await _imageFile!.readAsBytes();
        await storageRef.putData(bytes, metadata);
      } else {
        // Mobile platform upload
        await storageRef.putFile(_imageFile!);
      }
      
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        DateTime birthday;
        if (_useAgeInput) {
          final years = int.tryParse(_yearsController.text) ?? 0;
          final months = int.tryParse(_monthsController.text) ?? 0;
          birthday = DateTime.now().subtract(
            Duration(days: (years * 365) + (months * 30)),
          );
        } else {
          birthday = _selectedBirthday ?? DateTime.now();
        }

        final imageUrl = await _uploadImage() ?? '';

        final pet = Pet(
          name: _nameController.text,
          type: _selectedType,
          breed: _breedController.text,
          age: '${_yearsController.text} years ${_monthsController.text} months',
          gender: _selectedGender,
          imagePath: imageUrl,
          userId: FirebaseAuth.instance.currentUser!.uid,
          BD: birthday,
        );

        final petId = await Pet.createPet(pet);
        if (petId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pet added successfully!')),
          );
          Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Pet', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple[400],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple[400]!,
              Colors.deepPurple[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Picker with Beautiful Design
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.deepPurple[200]!, width: 2),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imageFile == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt, 
                                      size: 50, 
                                      color: Colors.deepPurple[300],
                                    ),
                                    Text(
                                      'Tap to add pet photo',
                                      style: TextStyle(
                                        color: Colors.deepPurple[300],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pet Details Inputs with Enhanced Styling
                      _buildDropdown(
                        label: 'Pet Type',
                        value: _selectedType,
                        items: _petTypes,
                        onChanged: (value) => setState(() => _selectedType = value!),
                      ),

                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Pet Name',
                        validator: (value) => value == null || value.isEmpty 
                          ? 'Please enter a pet name' 
                          : null,
                      ),

                      const SizedBox(height: 16),
                      _buildBreedField(),

                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Gender',
                        value: _selectedGender,
                        items: _genderOptions,
                        onChanged: (value) => setState(() => _selectedGender = value!),
                      ),

                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Age Input Method'),
                        trailing: Switch(
                          value: _useAgeInput,
                          onChanged: (value) => setState(() => _useAgeInput = value),
                        ),
                      ),

                      _buildAgeInput(),

                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Add Pet', 
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.deepPurple[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.deepPurple[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.deepPurple[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.deepPurple[400]!, width: 2),
        ),
      ),
      items: items.map((type) => 
        DropdownMenuItem(value: type, child: Text(type))
      ).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.deepPurple[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.deepPurple[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.deepPurple[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.deepPurple[400]!, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  // Add breed field
  Widget _buildBreedField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _breedSuggestions[_selectedType]?.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        }) ?? const Iterable<String>.empty();
      },
      onSelected: (String selection) {
        setState(() {
          _breedController.text = selection;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Breed',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter breed';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildAgeInput() {
    return _useAgeInput 
      ? Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _yearsController,
                decoration: const InputDecoration(
                  labelText: 'Years',
                  icon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_useAgeInput && value!.isEmpty) {
                    return 'Please enter years';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _monthsController,
                decoration: const InputDecoration(
                  labelText: 'Months',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final months = int.tryParse(value);
                    if (months! > 11) {
                      return 'Max 11 months';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        )
      : InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedBirthday ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _selectedBirthday = picked);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Birthday',
              icon: Icon(Icons.cake),
            ),
            child: Text(
              _selectedBirthday != null 
                ? DateFormat('MMM d, y').format(_selectedBirthday!)
                : 'Select birthday',
            ),
          ),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearsController.dispose();
    _monthsController.dispose();
    _breedController.dispose();
    super.dispose();
  }
}
