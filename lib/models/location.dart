import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';


class Location {
  final String id;
  final String petId;
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isActive;

  Location({
    required this.id,
    required this.petId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map, String docId) {
    return Location(
      id: docId,
      petId: map['petId'] ?? '',
      userId: map['userId'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] is Timestamp 
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp']),
      isActive: map['isActive'] ?? true,
    );
  }

  static Future<bool> updateLocation(Location location) async {
    try {

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != location.userId) {
        throw Exception('Unauthorized');
      }

      final locationsRef = FirebaseFirestore.instance
          .collection('locations')
          .doc(location.petId);

      // First update main document with server timestamp
      await locationsRef.set({
        'userId': location.userId,
        'petId': location.petId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));

      print('Location updated for pet: ${location.petId}');
      return true;
    } catch (e) {
      print('Error updating location: $e');
      return false;
    }
  }

  static Stream<List<Location>> getPetLocations(String petId) {
    return FirebaseFirestore.instance
        .collection('locations')
        .where('petId', isEqualTo: petId)
        .where('isActive', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Location.fromMap(doc.data(), doc.id))
            .toList());
  }

  static Future<List<Location>> getNearbyPets({
    required double latitude,
    required double longitude,
    double radiusInKm = 5.0,
  }) async {
    try {
      // Calculate bounding box for rough filtering
      final lat = 0.0144927536231884; // approx. 1 degree = 111km
      final lon = 0.0181818181818182;
      
      final lowerLat = latitude - (lat * radiusInKm);
      final upperLat = latitude + (lat * radiusInKm);
      final lowerLon = longitude - (lon * radiusInKm);
      final upperLon = longitude + (lon * radiusInKm);

      final snapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where('latitude', isGreaterThanOrEqualTo: lowerLat)
          .where('latitude', isLessThanOrEqualTo: upperLat)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Location.fromMap(doc.data(), doc.id))
          .where((loc) {
            final inLongitudeRange = loc.longitude >= lowerLon && 
                                   loc.longitude <= upperLon;
            return inLongitudeRange;
          })
          .toList();
    } catch (e) {
      print('Error getting nearby pets: $e');
      return [];
    }
  }
}