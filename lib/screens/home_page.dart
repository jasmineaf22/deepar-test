import 'package:flutter/material.dart';
import '../services/timeline_service.dart';
import '../models/post_model.dart';
import '../widgets/post_item.dart';
import 'camera_page.dart';
import 'create_post_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(initialPage: 1);
  final TimelineService timelineService = TimelineService();
  late Future<List<Post>> postsFuture;
  bool isTimelinePage = true; // Track whether we're on the timeline page

  @override
  void initState() {
    super.initState();
    postsFuture = timelineService.fetchPosts();

    // Add a listener to the page controller to detect page changes
    _pageController.addListener(() {
      // Check if the current page is the timeline page (index 1)
      if (_pageController.page == 1) {
        setState(() {
          isTimelinePage = true;
        });
      } else {
        setState(() {
          isTimelinePage = false;
        });
      }
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
        reverse: false,  // Set reverse to false to swipe right to go to the camera
        children: [
          const CameraPage(),
          FutureBuilder<List<Post>>(
            future: postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No posts yet.'));
              }

              return ListView(
                children: snapshot.data!
                    .map(
                      (post) => PostItem(
                    post: post,
                    onLike: () => likePost(post.id),
                    onEdit: () => _editPost(post),
                    onDelete: () => _confirmDelete(context, post),
                  ),
                )
                    .toList(),
              );
            },
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
          setState(() {
            postsFuture = timelineService.fetchPosts(); // Refresh posts after returning
          });
        },
        child: const Icon(Icons.add),
      )
          : null,  // Hide FAB on the Camera page
    );
  }

  void likePost(String postId) {
    timelineService.likePost(postId);
    setState(() {
      postsFuture = timelineService.fetchPosts();
    });
  }

  void _editPost(Post post) async {
    String updatedContent = await _showEditDialog(context, post.content);
    if (updatedContent.isNotEmpty) {
      timelineService.updatePost(post.id, updatedContent);
      setState(() {
        postsFuture = timelineService.fetchPosts();
      });
    }
  }

  void _confirmDelete(BuildContext context, Post post) async {
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
      _deletePost(post.id, post.imageUrl);
    }
  }

  void _deletePost(String postId, String imageUrl) async {
    await timelineService.deletePost(postId, imageUrl);
    setState(() {
      postsFuture = timelineService.fetchPosts();
    });
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    return result;
  }
}
