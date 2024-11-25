import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final String imageUrl;
  final String profileImageUrl;
  final int likeCount;
  final int commentCount;
  final DateTime timestamp;
  final List<String> likedBy;

  // Constructor
  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.imageUrl,
    required this.profileImageUrl,
    required this.likeCount,
    required this.commentCount,
    required this.timestamp,
    this.likedBy = const [], // Initialize likedBy as an empty list by default
  });

  // Factory constructor to create Post from Firestore data
  factory Post.fromFirestore(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likedBy: List<String>.from(data['likedBy'] ?? []), // Map likedBy field to List<String>
    );
  }

  // Method to convert Post object to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'content': content,
      'imageUrl': imageUrl,
      'profileImageUrl': profileImageUrl,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'timestamp': timestamp,
      'likedBy': likedBy, // Save likedBy as a list
    };
  }

  // Method for immutability and creating updated Post objects (for example, with new likes or comments)
  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? content,
    String? imageUrl,
    String? profileImageUrl,
    int? likeCount,
    int? commentCount,
    DateTime? timestamp,
    List<String>? likedBy,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      timestamp: timestamp ?? this.timestamp,
      likedBy: likedBy ?? List.from(this.likedBy), // Create a copy of the list
    );
  }
}
