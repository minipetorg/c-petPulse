import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  Future<QuerySnapshot> searchVets(String query) async {
    return await FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'vet')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThan: '${query}z')
        .get();
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Error information
  String? lastErrorMessage;
  DateTime? lastErrorTime;
  
  // Get current user type
  Future<String?> getCurrentUserType() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!doc.exists) {
          debugPrint('User document does not exist for ${user.uid}');
          // Create a basic user document
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'userType': 'pet_owner', // Default type
            'createdAt': FieldValue.serverTimestamp(),
          });
          return 'pet_owner';
        }
        
        final data = doc.data();
        
        // Try different possible field names
        String? userType = data?['userType'] as String?;
        if (userType == null) userType = data?['UserType'] as String?;
        if (userType == null) userType = data?['type'] as String?;
        if (userType == null) userType = data?['user_type'] as String?;
        
        if (userType == null) {
          // If still null, update with default type
          await _firestore.collection('users').doc(user.uid).update({
            'userType': 'pet_owner',
          });
          return 'pet_owner';
        }
        
        return userType;
      } catch (e) {
        _handleError('Error getting user type', e);
        return 'pet_owner'; // Default fallback
      }
    }
    return null;
  }

  // Get all vets (for pet owners)
  Stream<QuerySnapshot> getVets() {
    try {
      return _firestore
          .collection('users')
          .where('userType', whereIn: ['vet', 'Vet', 'VET', 'Veterinarian'])
          .snapshots();
    } catch (e) {
      _handleError('Error in getVets()', e);
      // Fallback to a simpler query
      return _firestore
          .collection('users')
          .limit(10)  // Limit results as a fallback
          .snapshots();
    }
  }

  // Get all pet owners who have chats with the current vet
  Stream<QuerySnapshot> getVetChats() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    try {
      return _firestore
          .collection('chats')
          .where('vetId', isEqualTo: user.uid)
          .snapshots();
    } catch (e) {
      _handleError('Error in getVetChats()', e);
      return const Stream.empty();
    }
  }

  // Get all vets who the current pet owner has chatted with
  Stream<QuerySnapshot> getPetOwnerChats() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    try {
      debugPrint('Attempting to fetch chats for pet owner: ${user.uid}');
      return _firestore
          .collection('chats')
          .where('petOwnerId', isEqualTo: user.uid)
          .snapshots();
    } catch (e) {
      _handleError('Error in getPetOwnerChats()', e);
      return const Stream.empty();
    }
  }

  // Get chat messages between users
  Stream<QuerySnapshot> getMessages(String chatId) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      _handleError('Error in getMessages()', e);
      return const Stream.empty();
    }
  }

  // Create or get existing chat between pet owner and vet
  Future<String> createOrGetChatId(String vetId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw 'Not authenticated';
    
    // Check if chat already exists
    final chatQuery = await _firestore.collection('chats')
        .where('participants.${currentUser.uid}', isEqualTo: true)
        .where('participants.$vetId', isEqualTo: true)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      return chatQuery.docs.first.id;
    }

    // Create new chat with proper permissions
    final chatDoc = await _firestore.collection('chats').add({
      'petOwnerId': currentUser.uid,
      'vetId': vetId,
      'participants': {
        currentUser.uid: true,
        vetId: true,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': null,
    });

    return chatDoc.id;
  }

  // Send message
  Future<void> sendMessage(String chatId, String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Not authenticated';

    // Verify chat participation before sending
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) throw 'Chat not found';
    
    final chatData = chatDoc.data();
    if (chatData == null || !(chatData['participants'] as Map)[user.uid]) {
      throw 'Not authorized to send messages in this chat';
    }

    final batch = _firestore.batch();
    
    // Add message
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'text': message,
      'senderId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update chat metadata
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
  
  // Handle errors
  void _handleError(String context, dynamic error) {
    lastErrorMessage = '$context: $error';
    lastErrorTime = DateTime.now();
    debugPrint('🔴 FIREBASE ERROR: $lastErrorMessage');
    notifyListeners();
  }

  // Method to help integrate Firebase security rules
  Future<void> addUserToFirestore(String uid, String email, String userType) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('User added to Firestore successfully');
    } catch (e) {
      _handleError('Error adding user to Firestore', e);
    }
  }
  
  // Manual index creation method for debugging
  Future<void> createRequiredIndexes() async {
    try {
      // This doesn't actually create the index but helps with logging
      debugPrint('Creating debug document to trigger index creation');
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Create a test document that would trigger the index requirements
      await _firestore.collection('chats').add({
        'petOwnerId': user.uid,
        'vetId': 'test_vet_id',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': 'This is a test message to trigger index creation',
        'petOwnerEmail': user.email,
        'vetEmail': 'test@vet.com',
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [user.uid, 'test_vet_id'],
      });
      
      debugPrint('Test document created. Check console for index requirements');
    } catch (e) {
      // The error will contain the index creation link
      debugPrint('Expected error (contains index URL): $e');
    }
  }
}
