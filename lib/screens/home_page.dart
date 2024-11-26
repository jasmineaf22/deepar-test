import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/timeline_service.dart';
import '../models/post_model.dart';
import '../widgets/post_item.dart';
import 'camera_page.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';
import 'chat_list_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(initialPage: 1);
  bool isTimelinePage = true;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        isTimelinePage = _pageController.page == 1;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: [
          const CameraPage(),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = snapshot.data!.docs;

              if (posts.isEmpty) {
                return const Center(child: Text('No posts yet.'));
              }

              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final postId = post.id;

                  return PostItem(
                    postId: postId,
                    post: Post.fromFirestore(post.data() as Map<String, dynamic>, postId),
                    onLike: () async {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                      final isLiked = (post['likedBy'] as List).contains(currentUserId);

                      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                        'likedBy': isLiked
                            ? FieldValue.arrayRemove([currentUserId])
                            : FieldValue.arrayUnion([currentUserId]),
                        'likeCount': isLiked ? FieldValue.increment(-1) : FieldValue.increment(1),
                      });
                    },
                    onEdit: () => _editPost(postId, post['content']),
                    onDelete: () => _confirmDelete(context, postId, post['imageUrl']),
                    onTap: () => _openPostDetails(postId),
                  );
                },
              );
            },
          ),
          ChatListScreen(
            currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
          ),
        ],
      ),
      floatingActionButton: isTimelinePage
          ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostPage()),
          );
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  void _editPost(String postId, String currentContent) async {
    String updatedContent = await _showEditDialog(context, currentContent);
    if (updatedContent.isNotEmpty) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'content': updatedContent,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _confirmDelete(BuildContext context, String postId, String imageUrl) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm) {
      // Call the deletePost method from TimelineService
      await TimelineService().deletePost(postId, imageUrl);
    }
  }



  void _openPostDetails(String postId) async {
    final docSnapshot = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    if (docSnapshot.exists) {
      final post = Post.fromFirestore(docSnapshot.data() as Map<String, dynamic>, postId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailPage(postId: postId),
        ),
      );
    } else {
      // Handle the case where the document does not exist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post not found')),
      );
    }
  }


  Future<String> _showEditDialog(BuildContext context, String currentContent) async {
    TextEditingController controller = TextEditingController(text: currentContent);
    String result = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Post'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new content'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                result = controller.text;
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    return result;
  }
}
