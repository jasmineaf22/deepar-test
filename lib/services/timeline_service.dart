import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TimelineService {
  final CollectionReference postsCollection =
  FirebaseFirestore.instance.collection('posts');
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  /// Fetch all posts, ordered by timestamp (descending)
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

  Stream<List<Post>> streamPosts() {
    return postsCollection.orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs
              .map((doc) =>
              Post.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
    );
  }


  /// Create a new post in Firestore
  Future<void> createPost(Post post) async {
    try {
      await postsCollection.add(post.toFirestore());
    } catch (e) {
      print('Error creating post: $e');
    }
  }

  /// Like or Unlike a post
  Future<void> likePost(String postId) async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) return; // Ensure user is authenticated

      final doc = postsCollection.doc(postId);
      final snapshot = await doc.get();

      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final List<dynamic> likedBy = data['likedBy'] ?? [];

      if (likedBy.contains(userId)) {
        // Unlike the post
        await doc.update({
          'likedBy': FieldValue.arrayRemove([userId]),
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // Like the post
        await doc.update({
          'likedBy': FieldValue.arrayUnion([userId]),
          'likeCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error liking/unliking post: $e');
    }
  }

  /// Update an existing post
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


  /// Delete a post and its associated image from Firestore
// Updated deletePost method in TimelineService
  Future<void> deletePost(String postId, String imageUrl) async {
    try {
      // First, delete all comments related to the post
      await _deleteComments(postId);

      // If there's an associated image, delete it from Firebase Storage
      if (imageUrl.isNotEmpty) {
        try {
          await storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print("Error deleting image from Firebase Storage: $e");
        }
      }

      // Delete the post from Firestore
      await postsCollection.doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

// Helper method to delete all comments for a specific post
  Future<void> _deleteComments(String postId) async {
    try {
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();

      for (var commentDoc in commentsSnapshot.docs) {
        await commentDoc.reference.delete(); // Delete each comment
      }
    } catch (e) {
      print('Error deleting comments: $e');
    }
  }
}
