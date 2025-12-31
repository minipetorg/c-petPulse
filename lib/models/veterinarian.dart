import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as UserModel;

class Veterinarian extends UserModel.User {
  final String clinicID;
  final String licenseNumber;
  final String specialization;
  final String additionalInfo;
  final List<String> certifications;
  final List<String> patients;

  Veterinarian({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required String address,
    required this.clinicID,
    required this.licenseNumber,
    required this.specialization,
    required this.additionalInfo,
    required this.certifications,
    required this.patients,
    String? photoUrl,
    DateTime? createdAt,
  }) : super(
          uid: uid,
          email: email,
          fullName: fullName,
          userType: "Veterinarian",
          phone: phone,
          address: address,
          photoUrl: photoUrl,
          createdAt: createdAt,
        );

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['clinicID'] = clinicID;
    map['licenseNumber'] = licenseNumber;
    map['specialization'] = specialization;
    map['additionalInfo'] = additionalInfo;
    map['certifications'] = certifications;
    map['patients'] = patients;
    return map;
  }

  factory Veterinarian.fromMap(Map<String, dynamic> map) {
    return Veterinarian(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      clinicID: map['clinicID'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      specialization: map['specialization'] ?? '',
      additionalInfo: map['additionalInfo'] ?? '',
      certifications: List<String>.from(map['certifications'] ?? []),
      patients: List<String>.from(map['patients'] ?? []),
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }

  static Future<Veterinarian?> getCurrentUserInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('veterinarians')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        return Veterinarian.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching current user info: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String address,
    required String clinicID,
    required String licenseNumber,
    required String specialization,
    required String additionalInfo,
    required List<String> certifications,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('veterinarians')
          .doc(uid)
          .update({
            'fullName': fullName,
            'phone': phone,
            'address': address,
            'clinicID': clinicID,
            'licenseNumber': licenseNumber,
            'specialization': specialization,
            'additionalInfo': additionalInfo,
            'certifications': certifications,
            'updatedAt': DateTime.now().toIso8601String(),
          });
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  static Future<String?> getFullNameById(String id) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('veterinarians').doc(id).get();
      if (doc.exists) {
        return doc['fullName'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching full name: $e');
      return null;
    }
  }

  static Future<List<Map<String, String>>> getAllVeterinarians() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('veterinarians').get();
      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'fullName': doc['fullName'] as String,
        };
      }).toList();
    } catch (e) {
      print('Error fetching veterinarians: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllVeterinariansDetailed() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('veterinarians').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'fullName': data['fullName'] as String? ?? '',
          'specialization': data['specialization'] as String? ?? '',
          'photoUrl': data['photoUrl'] as String? ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching veterinarians: $e');
      return [];
    }
  }
}