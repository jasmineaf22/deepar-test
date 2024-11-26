import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final String currentUserId;

  ChatListScreen({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("An error occurred. Please try again."),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No users found."),
            );
          }

          final users = snapshot.data!.docs.where((doc) => doc.id != currentUserId);

          if (users.isEmpty) {
            return const Center(
              child: Text("No chats available."),
            );
          }

          return ListView(
            children: users.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              // Safely retrieve data with fallback defaults
              final profilePicture = data['profilePictureUrl'] ??
                  'https://via.placeholder.com/150'; // Default image
              final name = data['name'] ?? 'Unknown User';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(profilePicture),
                ),
                title: Text(name),
                subtitle: const Text("Start a conversation"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        currentUserId: currentUserId,
                        otherUserId: doc.id,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}