import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final String imageUrl;
  final String profileImageUrl; // New field for profile picture
  final int likeCount;
  final int commentCount;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.imageUrl,
    required this.profileImageUrl, // Initialize new field
    required this.likeCount,
    required this.commentCount,
    required this.timestamp,
  });

  factory Post.fromFirestore(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '', // Map from Firestore
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'content': content,
      'imageUrl': imageUrl,
      'profileImageUrl': profileImageUrl, // Save profile picture URL
      'likeCount': likeCount,
      'commentCount': commentCount,
      'timestamp': timestamp,
    };
  }
}
