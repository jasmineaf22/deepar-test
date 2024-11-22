import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/timeline_service.dart';
import '../models/post_model.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TimelineService timelineService = TimelineService();
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: contentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Post Content'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: submitPost,
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> submitPost() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create a post')),
      );
      return;
    }

    final newPost = Post(
      id: '', // Firestore will generate this automatically
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'Anonymous',
      content: contentController.text,
      imageUrl: '', // Add photo URL if implemented
      profileImageUrl: currentUser.photoURL ?? '',
      likeCount: 0,
      commentCount: 0,
      timestamp: DateTime.now(),
    );

    await timelineService.createPost(newPost);
    Navigator.pop(context);
  }
}
