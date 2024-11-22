import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post_model.dart';

class TimelineService {
  final CollectionReference postsCollection =
  FirebaseFirestore.instance.collection('posts');
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<List<Post>> fetchPosts() async {
    try {
      final snapshot =
      await postsCollection.orderBy('timestamp', descending: true).get();
      return snapshot.docs
          .map((doc) =>
          Post.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  // Create a new post in Firestore
  Future<void> createPost(Post post) async {
    try {
      await postsCollection.add(post.toFirestore());
    } catch (e) {
      print('Error creating post: $e');
    }
  }

  Future<void> likePost(String postId) async {
    try {
      final doc = postsCollection.doc(postId);
      await doc.update({'likeCount': FieldValue.increment(1)});
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  Future<void> updatePost(String postId, String newContent) async {
    try {
      final doc = postsCollection.doc(postId);
      await doc.update({
        'content': newContent,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating post: $e');
    }
  }

  Future<void> deletePost(String postId, String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        try {
          await storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print("Error deleting image from Firebase Storage: $e");
        }
      }
      await postsCollection.doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
    }
  }
}
