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
    return await snapshot.ref.getDownloadURL(); // Return the photo URL
  }

  Future<void> createPost(
      String imageUrl, String userId, String userName, String caption) async {
    final postCollection = FirebaseFirestore.instance.collection('posts');
    await postCollection.add({
      'userId': userId,
      'userName': userName,
      'content': caption, // Custom caption
      'imageUrl': imageUrl,
      'likeCount': 0,
      'commentCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendToTimeline(BuildContext context) async {
    try {
      // Ensure the user is authenticated
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
        user = FirebaseAuth.instance.currentUser;
      }

      String userId = user?.uid ?? "anonymousUserId";
      String userName = user?.displayName ?? "Anonymous";

      // Upload photo to Firebase Storage
      String imageUrl = await uploadPhotoToStorage(photo);

      // Show caption input dialog
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

      // Use the entered caption or a default value
      String caption = captionController.text.isNotEmpty
          ? captionController.text
          : "Uploaded a photo!";

      // Create post in Firestore
      await createPost(imageUrl, userId, userName, caption);

      // Redirect to Timeline
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send to timeline: $e')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo saved to gallery!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save photo to gallery.')),
      );
    }
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
              ElevatedButton(
                onPressed: () async {
                  await saveToGallery(photo, context);
                  // Do not pop after saving
                },
                child: const Text('Save to Gallery'),
              ),
              ElevatedButton(
                onPressed: () => sendToTimeline(context),
                child: const Text('Send to Timeline'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
