import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart'; // For handling file paths
import 'dart:io';

class PhotoPreviewPage extends StatelessWidget {
  final File photo;

  const PhotoPreviewPage({super.key, required this.photo});

  Future<String> uploadPhotoToStorage(File photo) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('timeline_photos/${DateTime.now().millisecondsSinceEpoch}.jpg');

    UploadTask uploadTask = storageRef.putFile(photo);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> createPost(
      String imageUrl, String userId, String userName, String caption) async {
    final postCollection = FirebaseFirestore.instance.collection('posts');
    await postCollection.add({
      'userId': userId,
      'userName': userName,
      'content': caption,
      'imageUrl': imageUrl,
      'likeCount': 0,
      'commentCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendToTimeline(BuildContext context) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
        user = FirebaseAuth.instance.currentUser;
      }

      String userId = user?.uid ?? "anonymousUserId";
      String userName = user?.displayName ?? "Anonymous";

      String imageUrl = await uploadPhotoToStorage(photo);

      final TextEditingController captionController = TextEditingController();
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Add Caption'),
            content: TextField(
              controller: captionController,
              decoration: const InputDecoration(hintText: 'Enter a caption...'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, captionController.text),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );

      String caption = captionController.text.isNotEmpty
          ? captionController.text
          : "";

      await createPost(imageUrl, userId, userName, caption);

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send to timeline: $e')),
        );
      }
    }
  }

  Future<void> saveToGallery(File photo, BuildContext context) async {
    try {
      final Directory downloadsDir =
      Directory('/storage/emulated/0/Download/cipherlens');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final String newFilePath =
          '${downloadsDir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      await photo.copy(newFilePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo saved to gallery!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save photo to gallery.')),
        );
      }
    }
  }

  Future<void> sendPhotoToChat(BuildContext context, String chatRoomId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
        user = FirebaseAuth.instance.currentUser;
      }

      String imageUrl = await uploadPhotoToStorage(photo);

      FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': user?.uid ?? 'anonymousUserId',
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'profilePictureUrl': user?.photoURL ?? 'defaultProfilePicURL',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo sent to chat!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send photo to chat: $e')),
        );
      }
    }
  }

  void openChatRoomSelector(BuildContext context, String currentUserId) async {
    try {
      final chatRoomsSnapshot = await FirebaseFirestore.instance.collection('chats').get();
      final chatRooms = chatRoomsSnapshot.docs;

      if (chatRooms.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No chat rooms available.')),
          );
        }
        return;
      }

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return FutureBuilder<List<Map<String, String>>>(
            future: getRecipientNamesAndPicturesForChatRooms(chatRooms, currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No recipients found.'));
              }

              final chatRoomData = snapshot.data!;

              return ListView.builder(
                shrinkWrap: true,
                itemCount: chatRoomData.length,
                itemBuilder: (context, index) {
                  final chatRoomId = chatRoomData[index]['chatRoomId'];
                  final recipientName = chatRoomData[index]['name'] ?? 'Unknown';
                  final profilePictureUrl = chatRoomData[index]['profilePictureUrl'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profilePictureUrl.isNotEmpty
                          ? NetworkImage(profilePictureUrl)
                          : const AssetImage('assets/default_profile_pic.png') as ImageProvider,
                      onBackgroundImageError: (_, __) {
                        // Handle errors while loading the profile picture
                      },
                    ),
                    title: Text('$recipientName'),
                    onTap: () {
                      sendPhotoToChat(context, chatRoomId!);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening chat rooms: $e')),
        );
      }
    }
  }

  Future<List<Map<String, String>>> getRecipientNamesAndPicturesForChatRooms(
      List<QueryDocumentSnapshot> chatRooms, String currentUserId) async {
    List<Map<String, String>> chatRoomData = [];

    for (var chatRoom in chatRooms) {
      final chatRoomId = chatRoom.id;

      final chatRoomDataMap = chatRoom.data() as Map<String, dynamic>;
      final participants = chatRoomDataMap['participants'] as List<dynamic>?;

      if (participants == null || participants.isEmpty) {
        continue;
      }

      if (participants.contains(currentUserId)) {
        final otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
          final userName = userDoc.exists ? userDoc['name'] ?? 'Unknown User' : 'Unknown User';
          final profilePictureUrl = userDoc.exists ? userDoc['profilePictureUrl'] ?? '' : '';

          chatRoomData.add({
            'name': userName,
            'chatRoomId': chatRoomId,
            'profilePictureUrl': profilePictureUrl,
          });
        }
      }
    }

    return chatRoomData;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Preview')),
      body: Column(
        children: [
          Expanded(
            child: Image.file(photo, fit: BoxFit.contain),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await saveToGallery(photo, context);
                  },
                  child: const Text('Save to Gallery'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => sendToTimeline(context),
                  child: const Text('Send to Timeline'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      String currentUserId = user.uid;
                      openChatRoomSelector(context, currentUserId); // Pass currentUserId here
                    } else {
                      // Handle case when user is not logged in (e.g., sign in anonymously)
                      FirebaseAuth.instance.signInAnonymously().then((userCredential) {
                        String currentUserId = userCredential.user?.uid ?? "anonymousUserId";
                        openChatRoomSelector(context, currentUserId);
                      });
                    }
                  },

                  child: const Text('Send to People'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
