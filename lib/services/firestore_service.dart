import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add or update user profile data
  Future<void> createUserProfile(String userId, String displayName, String email) async {
  await FirebaseFirestore.instance.collection('users').doc(userId).set({
    'displayName': displayName,
    'email': email,
    'createdAt': Timestamp.now(),
  });
}

  // Fetch user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }

  // Create a new message board
  Future<void> createMessageBoard(String boardName, String imageUrl) async {
    try {
      await _firestore.collection('messageBoards').add({
        'boardName': boardName,
        'imageUrl': imageUrl,
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      print("Error creating message board: $e");
    }
  }

  // Get list of all message boards
  Stream<QuerySnapshot> getMessageBoards() {
    return _firestore.collection('messageBoards').orderBy('createdAt').snapshots();
  }

  // Add a new message to a message board
  Future<void> addMessage(String boardId, String userId, String username, String message) async {
    try {
      await _firestore.collection('messageBoards').doc(boardId).collection('messages').add({
        'userId': userId,
        'username': username,
        'message': message,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print("Error adding message: $e");
    }
  }

  // Fetch all messages from a specific message board (real-time updates)
  Stream<QuerySnapshot> getMessages(String boardId) {
    return _firestore.collection('messageBoards').doc(boardId).collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Update user profile information
  Future<void> updateUserProfile(String userId, String displayName, String dob) async {
  await FirebaseFirestore.instance.collection('users').doc(userId).update({
    'displayName': displayName,
    if (dob.isNotEmpty) 'dob': dob,
  });
}



  // Delete a message (optional feature)
  Future<void> deleteMessage(String boardId, String messageId) async {
    try {
      await _firestore.collection('messageBoards').doc(boardId).collection('messages').doc(messageId).delete();
    } catch (e) {
      print("Error deleting message: $e");
    }
  }
  Future<Map<String, dynamic>> getUserData(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data() ?? {};
  }
}
