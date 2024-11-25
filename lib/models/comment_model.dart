import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String profileImageUrl;
  final String content;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.profileImageUrl,
    required this.content,
    required this.timestamp,
  });

  factory Comment.fromFirestore(Map<String, dynamic> data, String id) {
    return Comment(
      id: id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      profileImageUrl: data['profileImageUrl'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'profileImageUrl': profileImageUrl,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
