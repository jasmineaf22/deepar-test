import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String email,
    required String profilePictureUrl,
  }) async {
    final doc = usersCollection.doc(uid);

    // Check if the user exists; if not, create a new record
    if (!(await doc.get()).exists) {
      await doc.set({
        'name': name,
        'email': email,
        'profilePictureUrl': profilePictureUrl,
        'createdAt': DateTime.now(),
      });
    }
  }
}
