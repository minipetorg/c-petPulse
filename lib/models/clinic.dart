import 'package:cloud_firestore/cloud_firestore.dart';

class Clinic {
  final String id;
  final String name;
  final String licenseNumber;
  final List<String> availableDoctors;
  final double latitude;
  final double longitude;
  final String address;
  final String openingHours;
  final double rating;
  final String image;

  Clinic({
    required this.id,
    required this.name,
    required this.licenseNumber,
    required this.availableDoctors,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.openingHours,
    required this.rating,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'licenseNumber': licenseNumber,
      'availableDoctors': availableDoctors,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'openingHours': openingHours,
      'rating': rating,
      'image': image,
    };
  }

  factory Clinic.fromMap(Map<String, dynamic> map) {
    return Clinic(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      availableDoctors: List<String>.from(map['availableDoctors'] ?? []),
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      address: map['address'] ?? '',
      openingHours: map['openingHours'] ?? '',
      rating: map['rating'] ?? 0.0,
      image: map['image'] ?? '',
    );
  }

  static Future<void> createClinic(Clinic clinic) async {
    final docRef = FirebaseFirestore.instance.collection('clinics').doc(clinic.licenseNumber);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set(clinic.toMap());
    } else {
      throw Exception('A clinic with this license number already exists');
    }
  }

  static Future<void> updateClinic(Clinic clinic) async {
    final docRef = FirebaseFirestore.instance.collection('clinics').doc(clinic.licenseNumber);
    await docRef.update(clinic.toMap());
  }

  static Future<void> deleteClinic(String licenseNumber) async {
    final docRef = FirebaseFirestore.instance.collection('clinics').doc(licenseNumber);
    await docRef.delete();
  }

  static Future<List<Map<String, String>>> getAllClinicNamesAndLicenseNumbers() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('clinics').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] as String? ?? 'Unknown Clinic',
        'licenseNumber': data['licenseNumber'] as String? ?? 'No License',
      };
    }).toList();
  }

  static Future<Clinic?> getClinicById(String licenseNumber) async {
    final docRef = FirebaseFirestore.instance.collection('clinics').doc(licenseNumber);
    final doc = await docRef.get();
    if (doc.exists) {
      return Clinic.fromMap(doc.data()!);
    } else {
      return null;
    }
  }

  static Future<void> addDoctorToClinic(String clinicId, String vetId) async {
    final docRef = FirebaseFirestore.instance.collection('clinics').doc(clinicId);
    final doc = await docRef.get();

    if (doc.exists) {
      final clinic = Clinic.fromMap(doc.data()!);
      if (!clinic.availableDoctors.contains(vetId)) {
        clinic.availableDoctors.add(vetId);
        await docRef.update({'availableDoctors': clinic.availableDoctors});
      } else {
        throw Exception('Doctor is already in the clinic');
      }
    } else {
      throw Exception('Clinic not found');
    }
  }

  static Future<List<Clinic>> getAllClinics() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('clinics').get();
    return querySnapshot.docs.map((doc) {
      return Clinic.fromMap(doc.data());
    }).toList();
  }

  static Future<Clinic?> getClinicByVetId(String vetId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('clinics')
        .where('availableDoctors', arrayContains: vetId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return Clinic.fromMap(querySnapshot.docs.first.data());
    }
    return null;
  }
}