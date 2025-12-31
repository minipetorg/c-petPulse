import '../models/user.dart';

class PetOwner extends User {
  PetOwner({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required String address,
    String? photoUrl,
    DateTime? createdAt,
  }) : super(
          uid: uid,
          email: email,
          fullName: fullName,
          userType: "Pet Owner",
          phone: phone,
          address: address,
          photoUrl: photoUrl,
          createdAt: createdAt,
        );
}