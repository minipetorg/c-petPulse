import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Pet {
  final String? id;  // Make nullable for new pets
  final String name;
  final String type;
  final String breed;
  final String age;
  final String gender;
  final String imagePath;
  final String userId;
  final DateTime? BD;

  Pet({
    this.id,  // Optional for new pets
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.gender,
    required this.imagePath,
    required this.userId,
    this.BD,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'breed': breed,
      'age': age,
      'gender': gender,
      'image': imagePath,
      'userId': userId,
      'birthday': BD?.toIso8601String(), // Ensure DateTime is converted to String
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Pet(
      id: docId ?? map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? 'Dog',
      breed: map['breed']?.toString() ?? '',
      age: map['age']?.toString() ?? '',
      gender: map['gender']?.toString() ?? 'Male',
      imagePath: map['image']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      BD: map['birthday'] is Timestamp 
          ? (map['birthday'] as Timestamp).toDate()
          : map['birthday'] != null 
              ? DateTime.parse(map['birthday'])
              : DateTime.now(),
    );
  }

  static Future<String?> createPet(Pet pet) async {
    try {
      final petsCollection = FirebaseFirestore.instance.collection('pets');
      final docRef = await petsCollection.add(pet.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating pet: $e');
      return null;
    }
  }

  static Stream<List<Pet>> getPetsByUser(String userId) {
    try {
      return FirebaseFirestore.instance
          .collection('pets')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Pet.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error getting pets: $e');
      return Stream.value([]);
    }
  }

  static Future<bool> updatePet(String petId, Map<String, dynamic> updates, String userId) async {
    try {
      final petDoc = await FirebaseFirestore.instance
          .collection('pets')
          .doc(petId)
          .get();

      if (!petDoc.exists || petDoc.data()?['userId'] != userId) {
        return false;
      }

      await FirebaseFirestore.instance
          .collection('pets')
          .doc(petId)
          .update(updates);

      return true;
    } catch (e) {
      print('Error updating pet: $e');
      return false;
    }
  }

  static Future<List<Pet>> getPetsByType({required String type, required String currentPetGender, required String breed}) async {
    try {
      String targetGender = currentPetGender == 'Male' ? 'Female' : 'Male';
      
      // Start building the query
      Query query = FirebaseFirestore.instance
          .collection('pets')
          .where('type', isEqualTo: type)
          .where('gender', isEqualTo: targetGender);
      
      // Add breed filter if breed is provided
      if (breed.isNotEmpty) {
        query = query.where('breed', isEqualTo: breed);
      }
      
      final QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching pets by type and gender: $e');
      return [];
    }
  }

  static AssetImage getPetIcon(String? type) {
    if (type == null) return AssetImage('assets/Blacky.jpg');
    
    switch (type.toLowerCase()) {
      case 'dog':
        return AssetImage('assets/icons/Picture2.png');
      case 'cat':
        return AssetImage('assets/icons/Picture4.png');
      case 'rabbit':
        return AssetImage('assets/icons/Picture3.png');
      case 'bird':
        return AssetImage('assets/pet4.jpg');
      default:
        return AssetImage('assets/icons/Picture2.png');
    }
  }

  static String calculateAge(String birthdayStr) {
    final birthday = DateTime.parse(birthdayStr);
    final now = DateTime.now();
    
    int years = now.year - birthday.year;
    int months = now.month - birthday.month;
    
    // Adjust years if needed
    if (now.month < birthday.month || 
        (now.month == birthday.month && now.day < birthday.day)) {
      years--;
      months = 12 - (birthday.month - now.month);
    }
    
    // Adjust months if day of month affects it
    if (now.day < birthday.day) {
      months--;
      if (months < 0) {
        months = 11;
        years--;
      }
    }
  
    final yearStr = years > 0 ? '$years year${years != 1 ? 's' : ''}' : '';
    final monthStr = months > 0 ? '$months month${months != 1 ? 's' : ''}' : '';
    
    if (yearStr.isNotEmpty && monthStr.isNotEmpty) {
      return '$yearStr, $monthStr';
    } else {
      return yearStr.isNotEmpty ? yearStr : monthStr;
    }
  }

  static Future<bool> deletePet(String petId, String userId) async {
    try {
      // Get pet document
      final petDoc = await FirebaseFirestore.instance
          .collection('pets')
          .doc(petId)
          .get();

      // Verify pet exists and belongs to user
      if (!petDoc.exists) {
        print('Pet not found');
        return false;
      }

      final petData = petDoc.data();
      if (petData?['userId'] != userId) {
        print('Unauthorized deletion attempt');
        return false;
      }

      // Delete pet document
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(petId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting pet: $e');
      return false;
    }
  }

  static Future<List<String>> getPetNamesByIds(List<String> petIds) async {
    try {
      if (petIds.isEmpty) return [];

      final querySnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where(FieldPath.documentId, whereIn: petIds)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['name'] as String? ?? 'Unknown Pet')
          .toList();
    } catch (e) {
      print('Error fetching pet names: $e');
      return List.filled(petIds.length, 'Unknown Pet');
    }
  }

  static Future<String?> getPetNameById(String petId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('pets').doc(petId).get();
      if (doc.exists) {
        return doc.data()?['name'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching pet name: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getMedicalRecords(String petId) async {
    try {
      final records = await FirebaseFirestore.instance
        .collection('medical_records') // Note the collection name
        .where('petId', isEqualTo: petId)
        .orderBy('dateTime', descending: true)
        .get();
        
      return records.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error fetching medical records: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getVaccinations(String petId) async {
    try {
      final vaccinations = await FirebaseFirestore.instance
        .collection('medical_records')  // We'll use the same collection, but filter vaccinated records
        .where('petId', isEqualTo: petId)
        .where('isVaccined', isEqualTo: true)
        .orderBy('dateTime', descending: true)
        .get();
        
      return vaccinations.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error fetching vaccinations: $e');
      return [];
    }
  }
}
