import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/comment_service.dart';
import '../models/comment_model.dart';
import '../services/timeline_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final CommentService commentService = CommentService();
  final TextEditingController commentController = TextEditingController();
  final TextEditingController postEditController = TextEditingController();
  late Future<List<Comment>> commentsFuture;
  late bool isLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  // Fetch comments for the post
  Future<void> _fetchComments() async {
    commentsFuture = commentService.fetchComments(widget.postId);
    setState(() {}); // Update the UI after fetching comments
  }

  // Add a new comment
  Future<void> _addComment() async {
    if (commentController.text.isNotEmpty) {
      await commentService.addComment(
        postId: widget.postId,
        content: commentController.text,
      );
      commentController.clear();
      await _fetchComments(); // Refresh comments after adding
    }
  }

  // Edit an existing comment
// Edit an existing comment
  Future<void> _editComment(String commentId, String currentContent) async {
    // Create a new controller and prefill it with the current content of the comment
    final TextEditingController editController = TextEditingController(text: currentContent);

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: 'Edit your comment'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String newContent = editController.text.trim();
                if (newContent.isNotEmpty && newContent != currentContent) {
                  await commentService.updateComment(commentId, newContent);
                  Navigator.of(context).pop(); // Close the dialog
                  await _fetchComments(); // Refresh the comments after editing
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog without saving
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }


  // Delete a comment
  Future<void> _deleteComment(String commentId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await commentService.deleteComment(commentId);
                await _fetchComments(); // Refresh comments after deleting
                _decrementCommentCount(); // Decrease comment count in the post
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Update comment count when a comment is deleted
  Future<void> _decrementCommentCount() async {
    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
      final postSnapshot = await postRef.get();
      if (postSnapshot.exists) {
        final postData = postSnapshot.data() as Map<String, dynamic>;
        final currentCount = postData['commentCount'] ?? 0;
        await postRef.update({
          'commentCount': FieldValue.increment(-1), // Decrement the comment count
        });
      }
    } catch (e) {
      print('Error decrementing comment count: $e');
    }
  }

  // Format timestamp for comments
  String _formatTimeAgo(DateTime timestamp) {
    return timeago.format(timestamp);
  }

  // Delete the entire post and its comments
  Future<void> _deletePost() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  // Delete all comments associated with the post
                  await _deleteComments(widget.postId);

                  // Check and delete the image if it exists
                  final imageUrl = await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .get()
                      .then((doc) => doc.data()?['imageUrl'] ?? '');

                  if (imageUrl.isNotEmpty) {
                    final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
                    await storageRef.delete();
                  }

                  // Delete the post document
                  await FirebaseFirestore.instance.collection('posts').doc(widget.postId).delete();
                  await TimelineService().deletePost(widget.postId, imageUrl);

                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Navigate back
                  Navigator.pushReplacementNamed(context, '/home');
                } catch (e) {
                  print('Error deleting post and comments: $e');
                  Navigator.of(context).pop(); // Close dialog on error
                }
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to delete all comments for a post
  Future<void> _deleteComments(String postId) async {
    final commentsSnapshot = await FirebaseFirestore.instance
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();

    for (var commentDoc in commentsSnapshot.docs) {
      await commentDoc.reference.delete();
    }
  }

  // Edit the post content
  Future<void> _editPost(String currentContent) async {
    postEditController.text = currentContent; // Pre-fill the current content
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Post'),
          content: TextField(
            controller: postEditController,
            decoration: const InputDecoration(hintText: 'Enter new content'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String newContent = postEditController.text.trim();
                if (newContent.isNotEmpty && newContent != currentContent) {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .update({'content': newContent});
                  Navigator.of(context).pop();
                  setState(() {}); // Refresh the UI
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('This post has been deleted.'));
          }

          final userId = data['userId'];
          final userName = data['userName'] ?? 'Anonymous';
          final profileImageUrl = data['profileImageUrl'] ?? '';
          final content = data['content'] ?? '';
          final imageUrl = data['imageUrl'] ?? '';
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          likeCount = data['likeCount'] ?? 0;
          isLiked = (data['likedBy'] as List<dynamic>?)?.contains(currentUserId) ?? false;

          return SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : null,
                            child: profileImageUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(_formatTimeAgo(timestamp)),
                        ),
                        if (imageUrl.isNotEmpty) Image.network(imageUrl),
                        Text(content),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
                                  'likedBy': isLiked
                                      ? FieldValue.arrayRemove([currentUserId])
                                      : FieldValue.arrayUnion([currentUserId]),
                                  'likeCount': isLiked ? FieldValue.increment(-1) : FieldValue.increment(1),
                                });
                                setState(() {
                                  isLiked = !isLiked;
                                  likeCount += isLiked ? 1 : -1;
                                });
                              },
                            ),
                            Text('$likeCount likes'),
                            const SizedBox(width: 16.0),
                            IconButton(
                              icon: const Icon(Icons.comment),
                              onPressed: () {},
                            ),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('comments')
                                  .where('postId', isEqualTo: widget.postId)
                                  .orderBy('timestamp')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }

                                final commentCount = snapshot.data?.docs.length ?? 0;
                                return Text('$commentCount comments');
                              },
                            ),
                          ],
                        ),
                        if (userId == currentUserId)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editPost(content),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: _deletePost,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                FutureBuilder<List<Comment>>(
                  future: commentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No comments yet.');
                    }
                    return ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: snapshot.data!.map((comment) {
                        return ListTile(
                          leading: CircleAvatar(
                            // Use the profile image URL if it exists
                            backgroundImage: comment.profileImageUrl.isNotEmpty
                                ? NetworkImage(comment.profileImageUrl)
                                : null,
                            // Show an icon if the profile image URL is empty
                            child: comment.profileImageUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(comment.userName),
                          subtitle: Text(comment.content),
                          trailing: comment.userId == currentUserId
                              ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editComment(comment.id, comment.content);
                              } else if (value == 'delete') {
                                _deleteComment(comment.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          )
                              : null,
                        );

                      }).toList(),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
