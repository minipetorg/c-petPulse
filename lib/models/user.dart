import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class User {
  final String uid;
  final String email;
  final String fullName;
  final String userType;
  final String phone;
  final String address;
  final String? photoUrl;
  final DateTime? createdAt;

  User({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.userType,
    required this.phone,
    required this.address,
    this.photoUrl,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'userType': userType,
      'phone': phone,
      'address': address,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      userType: map['userType'] ?? 'user',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'])
          : null,
    );
  }

  User copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? userType,
    String? phone,
    String? address,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      userType: userType ?? this.userType,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Future<String> getUserFullName(String userId, String userType) async {
    final collectionName = userType == 'Veterinarian' ? 'veterinarians' : 'petOwners';

    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(userId)
          .get();

      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        return userData['fullName'] ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      print('Error fetching user fullname: $e');
      return 'Unknown User';
    }
  }

  static Future<User?> getCurrentUserInfo(String userType) async {
    final collectionName = userType == 'Veterinarian' ? 'veterinarians' : 'petOwners';

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching current user info: $e');
      return null;
    }
  }

  static Future<bool> updateUserProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String address,
    required String userType,
  }) async {
    final collectionName = userType == 'Veterinarian' ? 'veterinarians' : 'petOwners';
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .update({
            'fullName': fullName,
            'phone': phone,
            'address': address,
            'updatedAt': DateTime.now().toIso8601String(),
          });
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
}