import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch comments for a specific post
  Future<List<Comment>> fetchComments(String postId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('timestamp')
          .get();

      return snapshot.docs.map((doc) {
        return Comment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);  // Corrected this line
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  // Add a new comment
  Future<void> addComment({required String postId, required String content}) async {
    try {
      await _db.collection('comments').add({
        'postId': postId,
        'content': content,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
        'profileImageUrl': FirebaseAuth.instance.currentUser?.photoURL ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Update an existing comment
  Future<void> updateComment(String commentId, String newContent) async {
    try {
      await _db.collection('comments').doc(commentId).update({
        'content': newContent,
        'timestamp': FieldValue.serverTimestamp(), // Optionally update the timestamp
      });
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  // Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _db.collection('comments').doc(commentId).delete();
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }
}
