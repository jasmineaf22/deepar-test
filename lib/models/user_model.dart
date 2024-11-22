class UserModel {
  final String uid;
  final String name;
  final String email;
  final String profilePictureUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.profilePictureUrl,
  });

  // Converts a Firestore document to a UserModel
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profilePictureUrl: data['profilePictureUrl'] ?? '',
    );
  }

  // Converts a UserModel to a Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': DateTime.now(),
    };
  }
}
