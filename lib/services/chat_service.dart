// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch messages between two users
  Stream<List<Message>> getMessages(String userId, String otherUserId) {
    return _firestore
        .collection('messages')
        .where('participants', arrayContains: [userId, otherUserId])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Message.fromMap(doc.id, doc.data()))
        .toList());
  }

  // Send a new message
  Future<void> sendMessage({
    required String senderId,
    required String recipientId,
    required String content,
  }) async {
    final message = Message(
      id: '',
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('messages').add(message.toMap());
  }

  // Edit a message
  Future<void> editMessage(String messageId, String newContent) async {
    await _firestore.collection('messages').doc(messageId).update({
      'content': newContent,
    });
  }
}
