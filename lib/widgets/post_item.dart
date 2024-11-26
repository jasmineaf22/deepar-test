import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/timeline_service.dart';

class PostItem extends StatefulWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap; // Optional onTap parameter

  const PostItem({
    Key? key,
    required this.post,
    required this.onLike,
    required this.onEdit,
    required this.onDelete,
    this.onTap, // Add this parameter
  }) : super(key: key);

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.likedBy.contains(FirebaseAuth.instance.currentUser?.uid);
  }

  String _formatTimeAgo(DateTime timestamp) {
    return timeago.format(timestamp);
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });

    widget.onLike();
    TimelineService().likePost(widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return GestureDetector(
      onTap: widget.onTap, // Trigger onTap if passed
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                  Text(
                    _formatTimeAgo(widget.post.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              if (widget.post.imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.network(widget.post.imageUrl),
                ),
              Text(widget.post.content),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.post.likeCount} likes'),
                  IconButton(
                    icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
                    onPressed: _toggleLike,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('${widget.post.commentCount} comments'),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.comment),
                    onPressed: widget.onTap, // Use onTap for comments too
                  ),
                ],
              ),
              if (widget.post.userId == currentUserId)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: widget.onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
