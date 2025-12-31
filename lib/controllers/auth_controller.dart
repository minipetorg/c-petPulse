import '../models/user.dart';
import '../models/petOwner.dart';
import '../models/veterinarian.dart';
import '../models/clinic.dart'; // Import the Clinic model
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;

  User _mapFirebaseUser(firebase_auth.User firebaseUser, {required String userType}) {
    return User(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      fullName: firebaseUser.displayName ?? '',
      userType: userType,
      phone: firebaseUser.phoneNumber ?? '',
      address: '',
    );
  }

  Future<bool> login(String email, String password, String userType) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final collectionName = userType == 'Veterinarian' ? 'veterinarians' : 'petOwners';
        final userDoc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(credential.user!.uid)
            .get();
        
        if (userDoc.exists) {
          final fetchedUserType = userDoc.data()?['userType'] ?? 'user';
          if (fetchedUserType != userType) {
            print('User type mismatch: expected $userType, found $fetchedUserType');
            return false;
          }
          _currentUser = _mapFirebaseUser(credential.user!, userType: fetchedUserType);
          print('Mapped to custom user: ${_currentUser?.fullName}');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> registerPetOwner(String email, String password, String fullName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final user = PetOwner(
          uid: credential.user!.uid,
          email: email,
          fullName: fullName,
          phone: '',
          address: '',
          createdAt: DateTime.now(),
        );
        
        await FirebaseFirestore.instance
          .collection('petOwners')
          .doc(user.uid)
          .set(user.toMap());
          
        _currentUser =  _mapFirebaseUser(credential.user!, userType: 'Pet Owner');
        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<bool> registerVets(String email, String password, String fullName, String clinicID) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final user = Veterinarian(
          uid: credential.user!.uid,
          email: email,
          fullName: fullName,
          clinicID: clinicID,
          phone: '',
          address: '',
          createdAt: DateTime.now(),
          licenseNumber: '',
          specialization: '',
          additionalInfo: '',
          certifications: [],
          patients: [],
        );
        
        await FirebaseFirestore.instance
          .collection('veterinarians')
          .doc(user.uid)
          .set(user.toMap());
          
        _currentUser =  _mapFirebaseUser(credential.user!, userType: 'Veterinarian');

        Clinic.addDoctorToClinic(clinicID, user.uid);

        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }

  Future<void> initializeUser() async {
    final currentFirebaseUser = _auth.currentUser;
    if (currentFirebaseUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentFirebaseUser.uid)
          .get();
      if (userDoc.exists) {
        final userType = userDoc.data()?['userType'] ?? 'user';
        _currentUser = _mapFirebaseUser(currentFirebaseUser, userType: userType);
      }
    }
  }

  Stream<User?> get userStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
      if (userDoc.exists) {
      final userType = userDoc.data()?['userType'] ?? 'user';
      return _mapFirebaseUser(firebaseUser, userType: userType);
      }
      return null;
    }).asBroadcastStream();
  }
}
