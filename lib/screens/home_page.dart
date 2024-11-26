import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final TimelineService timelineService = TimelineService();
  late Future<List<Post>> postsFuture;
  List<Post> posts = [];
  bool isTimelinePage = true;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    final user = FirebaseAuth.instance.currentUser;
    currentUserId = user?.uid ?? '';
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

  Future<void> _fetchPosts() async {
    postsFuture = timelineService.fetchPosts();
    posts = await postsFuture;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: [
          const CameraPage(),
          FutureBuilder<List<Post>>(
            future: postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (posts.isEmpty) {
                return const Center(child: Text('No posts yet.'));
              }
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return PostItem(
                    post: post,
                    onLike: () => _toggleLike(post, index),
                    onEdit: () => _editPost(post),
                    onDelete: () => _confirmDelete(context, post),
                    onTap: () => _openPostDetails(post), // Pass _openPostDetails here
                  );
                },
              );
            },
          ),
          ChatListScreen(
            currentUserId: currentUserId,
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
          _fetchPosts();
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  void _toggleLike(Post post, int index) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isLiked = post.likedBy.contains(currentUserId);
    await timelineService.likePost(post.id);
    final updatedPost = post.copyWith(
      likedBy: isLiked
          ? (post.likedBy..remove(currentUserId))
          : (post.likedBy..add(currentUserId)),
      likeCount: isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    setState(() {
      posts[index] = updatedPost;
    });
  }

  void _editPost(Post post) async {
    String updatedContent = await _showEditDialog(context, post.content);
    if (updatedContent.isNotEmpty) {
      await timelineService.updatePost(post.id, updatedContent);
      _fetchPosts();
    }
  }

  void _openPostDetails(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailPage(post: post),
      ),
    );
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
    _fetchPosts();
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
