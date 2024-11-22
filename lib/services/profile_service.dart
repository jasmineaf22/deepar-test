import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch user profile data
  Future<UserModel?> getUserProfile() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    DocumentSnapshot snapshot =
    await _firestore.collection('users').doc(currentUser.uid).get();

    if (!snapshot.exists) return null;

    return UserModel.fromFirestore(
        snapshot.data() as Map<String, dynamic>, currentUser.uid);
  }

  // Update user's name
  Future<void> updateUserName(String name) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    await _firestore.collection('users').doc(currentUser.uid).update({
      'name': name,
    });
  }

  // Upload new profile picture to Firebase Storage
  Future<String> uploadProfilePicture(File imageFile) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    String filePath = 'profile_pictures/${currentUser.uid}.jpg';
    UploadTask uploadTask = _storage.ref(filePath).putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  // Update profile picture URL in Firestore
  Future<void> updateProfilePicture(String downloadUrl) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    await _firestore.collection('users').doc(currentUser.uid).update({
      'profilePictureUrl': downloadUrl,
    });
  }

  // Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }
}
