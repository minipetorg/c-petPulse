import 'package:cloud_firestore/cloud_firestore.dart';

class Vaccination {
  final String vetId;
  final String petId;
  final String medicalRecordId;
  final String vaccineType;
  final DateTime nextDoseDate;

  Vaccination({
    required this.vetId,
    required this.petId,
    required this.medicalRecordId,
    required this.vaccineType,
    required this.nextDoseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'vetId': vetId,
      'petId': petId,
      'medicalRecordId': medicalRecordId,
      'vaccineType': vaccineType,
      'nextDoseDate': nextDoseDate.toIso8601String(),
    };
  }

  factory Vaccination.fromMap(Map<String, dynamic> map) {
    return Vaccination(
      vetId: map['vetId'] ?? '',
      petId: map['petId'] ?? '',
      medicalRecordId: map['medicalRecordId'] ?? '',
      vaccineType: map['vaccineType'] ?? '',
      nextDoseDate: DateTime.parse(map['nextDoseDate']),
    );
  }

  static Future<void> createVaccination(Vaccination vaccination) async {
    final docRef = FirebaseFirestore.instance.collection('vaccinations').doc();
    await docRef.set(vaccination.toMap());
  }

  static Future<void> updateVaccination(String id, Vaccination vaccination) async {
    final docRef = FirebaseFirestore.instance.collection('vaccinations').doc(id);
    await docRef.update(vaccination.toMap());
  }

  static Future<void> deleteVaccination(String id) async {
    final docRef = FirebaseFirestore.instance.collection('vaccinations').doc(id);
    await docRef.delete();
  }

  static Future<Vaccination?> getVaccinationById(String id) async {
    final docRef = FirebaseFirestore.instance.collection('vaccinations').doc(id);
    final doc = await docRef.get();
    if (doc.exists) {
      return Vaccination.fromMap(doc.data()!);
    }
    return null;
  }

  static Future<Vaccination?> getLatestVaccinationByPetId(String petId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('vaccinations')
        .where('petId', isEqualTo: petId)
        .orderBy('nextDoseDate', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return Vaccination.fromMap(querySnapshot.docs.first.data());
    }
    return null;
  }

  static Future<List<Vaccination>> getAllVaccinationsByPetId(String petId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('vaccinations')
        .where('petId', isEqualTo: petId)
        .orderBy('nextDoseDate', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => Vaccination.fromMap(doc.data())).toList();
  }
}


