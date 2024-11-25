import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/comment_service.dart';
import '../services/timeline_service.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final CommentService commentService = CommentService();
  final TimelineService timelineService = TimelineService();
  final TextEditingController commentController = TextEditingController();
  late Future<List<Comment>> commentsFuture;
  late bool isLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _checkIfLiked();
  }

  // Check if the current user has liked the post
  void _checkIfLiked() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    isLiked = widget.post.likedBy.contains(currentUserId);
    likeCount = widget.post.likeCount;
  }

  // Toggle like/unlike for the post using the existing likePost method
  Future<void> _toggleLike() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    // Call the likePost method to toggle like/unlike
    await timelineService.likePost(widget.post.id);
    setState(() {
      isLiked = !isLiked;
      likeCount = isLiked ? likeCount + 1 : likeCount - 1;
    });
  }

  Future<void> _fetchComments() async {
    commentsFuture = commentService.fetchComments(widget.post.id);
    setState(() {}); // Refresh UI after loading comments
  }

  Future<void> _addComment() async {
    if (commentController.text.isNotEmpty) {
      await commentService.addComment(
        postId: widget.post.id,
        content: commentController.text,
      );
      commentController.clear();
      await _fetchComments(); // Refresh the comments after adding
    }
  }

  Future<void> _editComment(String commentId, String newContent) async {
    await commentService.updateComment(commentId, newContent);
    await _fetchComments(); // Refresh the comments after editing
  }

  Future<void> _deleteComment(String commentId) async {
    // Show confirmation dialog before deleting comment
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
                await _fetchComments(); // Refresh the comments after deleting
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    return timeago.format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(widget.post.userName)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: widget.post.profileImageUrl.isNotEmpty
                              ? NetworkImage(widget.post.profileImageUrl)
                              : null,
                          child: widget.post.profileImageUrl.isEmpty
                              ? const Icon(Icons.person, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          widget.post.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _formatTimeAgo(widget.post.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8.0),
                    if (widget.post.imageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.network(widget.post.imageUrl),
                      ),
                    Text(widget.post.content),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.thumb_up),
                          onPressed: _toggleLike,
                        ),
                        Text('$likeCount likes'),
                        const SizedBox(width: 16.0),
                        // Comment logo and count
                        Icon(Icons.comment),
                        const SizedBox(width: 8.0),
                        FutureBuilder<List<Comment>>(
                          future: commentsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            final commentCount = snapshot.hasData ? snapshot.data!.length : 0;
                            return Text('$commentCount comments');
                          },
                        ),
                      ],
                    ),
                    FutureBuilder<List<Comment>>(
                      future: commentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No comments yet.'));
                        }
                        return ListView(
                          shrinkWrap: true,
                          children: snapshot.data!.map((comment) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(comment.profileImageUrl),
                              ),
                              title: Text(comment.userName),
                              subtitle: Text(comment.content),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (comment.userId == currentUserId)
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        await _showEditCommentDialog(comment);
                                      },
                                    ),
                                  if (comment.userId == currentUserId)
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        await _deleteComment(comment.id);  // Comment deletion
                                      },
                                    ),
                                ],
                              ),
                              onTap: null, // Optional, if you want no action when tapped
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
      ),
    );
  }

  Future<void> _showEditCommentDialog(Comment comment) async {
    final newContentController = TextEditingController(text: comment.content);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: newContentController,
            decoration: const InputDecoration(hintText: 'Edit your comment'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _editComment(comment.id, newContentController.text); // Edit comment
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
