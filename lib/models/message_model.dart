import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      senderId: data['senderId'],
      recipientId: data['recipientId'],
      content: data['content'],
      imageUrl: data['imageUrl'],
      timestamp: DateTime.parse(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
