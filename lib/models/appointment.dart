import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Appointment {
  final String id;
  final String petId;
  final String vetId;
  final DateTime dateTime;
  final String purpose;
  final String status;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.petId,
    required this.vetId,
    required this.dateTime,
    required this.purpose,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'vetId': vetId,
      'dateTime': dateTime.toIso8601String(),
      'purpose': purpose,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      petId: map['petId'] ?? '',
      vetId: map['vetId'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      purpose: map['purpose'] ?? '',
      status: map['status'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  static Future<void> createAppointment(Appointment appointment) async {
    final docRef = FirebaseFirestore.instance.collection('appointments').doc(appointment.id);
    await docRef.set(appointment.toMap());
  }

  static Future<void> updateAppointment(Appointment appointment) async {
    final docRef = FirebaseFirestore.instance.collection('appointments').doc(appointment.id);
    await docRef.update(appointment.toMap());
  }

  static Future<void> deleteAppointment(String appointmentId) async {
    final docRef = FirebaseFirestore.instance.collection('appointments').doc(appointmentId);
    await docRef.delete();
  }

  static Future<void> acceptAppointment(String appointmentId) async {
    final docRef = FirebaseFirestore.instance.collection('appointments').doc(appointmentId);
    await docRef.update({'status': 'accepted'});
  }

  static Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    final docRef = FirebaseFirestore.instance.collection('appointments').doc(appointmentId);
    await docRef.update({'status': status});
  }

  static Future<List<Appointment>> getAppointmentsByPetId(String petId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('petId', isEqualTo: petId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    return querySnapshot.docs.map((doc) {
      return Appointment.fromMap(doc.data());
    }).toList();
  }

  static Future<List<Appointment>> getAppointmentsByVetId(String vetId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('vetId', isEqualTo: vetId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    return querySnapshot.docs.map((doc) {
      return Appointment.fromMap(doc.data());
    }).toList();
  }

  static Future<Appointment?> getLastCompletedAppointment(String petId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('petId', isEqualTo: petId)
        .where('status', isEqualTo: 'completed')
        .orderBy('dateTime', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return Appointment.fromMap(querySnapshot.docs.first.data());
    }
    return null;
  }

  static String timeAgoSinceDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 8) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }
}