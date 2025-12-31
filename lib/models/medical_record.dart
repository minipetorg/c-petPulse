import 'package:cloud_firestore/cloud_firestore.dart';
import 'vaccination.dart';

class MedicalRecord {
  final String vetId;
  final String petId;
  final String appointmentId;
  final DateTime dateTime;
  final double petWeight;
  final String medicalNotes;
  final List<String> treatments;
  final bool isVaccined;
  final String vaccineType;
  final DateTime? nextDoseDate;

  MedicalRecord({
    required this.vetId,
    required this.petId,
    required this.appointmentId,
    required this.dateTime,
    required this.petWeight,
    required this.medicalNotes,
    required this.treatments,
    required this.isVaccined,
    required this.vaccineType,
    this.nextDoseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'vetId': vetId,
      'petId': petId,
      'appointmentId': appointmentId,
      'dateTime': dateTime.toIso8601String(),
      'petWeight': petWeight,
      'medicalNotes': medicalNotes,
      'treatments': treatments,
      'isVaccined': isVaccined,
      'vaccineType': vaccineType,
      'nextDoseDate': nextDoseDate?.toIso8601String(),
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      vetId: map['vetId'] ?? '',
      petId: map['petId'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      petWeight: map['petWeight']?.toDouble() ?? 0.0,
      medicalNotes: map['medicalNotes'] ?? '',
      treatments: List<String>.from(map['treatments'] ?? []),
      isVaccined: map['isVaccined'] ?? false,
      vaccineType: map['vaccineType'] ?? '',
      nextDoseDate: map['nextDoseDate'] != null ? DateTime.parse(map['nextDoseDate']) : null,
    );
  }

  static Future<bool> createMedicalRecord(MedicalRecord record) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('medical_records').doc();
      await docRef.set(record.toMap());

      if (record.isVaccined) {
        final vaccination = Vaccination(
          vetId: record.vetId,
          petId: record.petId,
          medicalRecordId: docRef.id,
          vaccineType: record.vaccineType,
          nextDoseDate: record.nextDoseDate ?? DateTime.now(),
        );
        await Vaccination.createVaccination(vaccination);
      }

      print('Medical record created successfully');
      return true;
    } catch (e) {
      print('Error creating medical record: $e');
      return false;
    }
  }

  static Future<void> updateMedicalRecord(String id, MedicalRecord record) async {
    final docRef = FirebaseFirestore.instance.collection('medical_records').doc(id);
    await docRef.update(record.toMap());
  }

  static Future<void> deleteMedicalRecord(String id) async {
    final docRef = FirebaseFirestore.instance.collection('medical_records').doc(id);
    await docRef.delete();
  }

  static Future<MedicalRecord?> getMedicalRecordById(String id) async {
    final docRef = FirebaseFirestore.instance.collection('medical_records').doc(id);
    final doc = await docRef.get();
    if (doc.exists) {
      return MedicalRecord.fromMap(doc.data()!);
    }
    return null;
  }

  static Future<MedicalRecord?> getLatestMedicalRecordByPetId(String petId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('medical_records')
        .where('petId', isEqualTo: petId)
        .orderBy('dateTime', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return MedicalRecord.fromMap(querySnapshot.docs.first.data());
    }
    return null;
  }

  static Future<List<MedicalRecord>> getAllMedicalRecordsByPetId(String petId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('medical_records')
        .where('petId', isEqualTo: petId)
        .orderBy('dateTime', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => MedicalRecord.fromMap(doc.data())).toList();
  }
}