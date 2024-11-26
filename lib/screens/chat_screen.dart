import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;

  ChatScreen({required this.currentUserId, required this.otherUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late String chatRoomId;
  String otherUserName = '';
  String otherUserProfilePic = '';
  String currentUserProfilePic = ''; // To store current user's profile picture

  @override
  void initState() {
    super.initState();
    chatRoomId = getChatRoomId(widget.currentUserId, widget.otherUserId);
    fetchUserInfo();
  }

  // Function to get unique chat room ID based on user IDs
  String getChatRoomId(String currentUserId, String otherUserId) {
    if (currentUserId.hashCode <= otherUserId.hashCode) {
      return "$currentUserId-$otherUserId";
    } else {
      return "$otherUserId-$currentUserId";
    }
  }

  // Fetch user info (name and profile picture)
  void fetchUserInfo() async {
    // Fetch other user's info
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .get();

    setState(() {
      otherUserName = userDoc['name'] ?? 'Unknown User';  // Provide a default value if null
      otherUserProfilePic = userDoc['profilePictureUrl'] ?? 'https://via.placeholder.com/150';  // Provide a default URL if null
    });

    // Fetch current user's profile info
    DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .get();

    setState(() {
      currentUserProfilePic = currentUserDoc['profilePictureUrl'] ?? 'https://via.placeholder.com/150';  // Provide a default URL if null
    });
  }

  // Send message to Firestore
  void sendMessage(String chatRoomId, {String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    // Check if the chat room exists or not
    DocumentReference chatRoomRef = FirebaseFirestore.instance.collection('chats').doc(chatRoomId);

    // If chat room does not exist, create it with participants
    DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();
    if (!chatRoomSnapshot.exists) {
      // Assuming both users are participants
      await chatRoomRef.set({
        'participants': [widget.currentUserId, widget.otherUserId], // Add participants
        // You can add other fields like a last message, timestamp, etc.
      });
    }

    // Send message after chat room creation
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'text': text.isNotEmpty ? text : null, // Store text if provided
      'imageUrl': imageUrl, // Store imageUrl if provided
      'senderId': widget.currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'profilePictureUrl': currentUserProfilePic,  // Include the current user's profile picture
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(otherUserProfilePic),
            ),
            const SizedBox(width: 10),
            Text(otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Error loading messages."),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No messages yet."),
                  );
                }

                final messages = snapshot.data!.docs;
                List<Widget> messageWidgets = [];
                String lastTimestamp = '';

                for (var i = 0; i < messages.length; i++) {
                  final data = messages[i].data() as Map<String, dynamic>;
                  final isMe = data['senderId'] == widget.currentUserId;

                  // Time Ago
                  String messageTimeAgo = '';
                  if (data['timestamp'] != null) {
                    Timestamp timestamp = data['timestamp'];
                    DateTime messageTime = timestamp.toDate();
                    messageTimeAgo = timeago.format(messageTime);
                  }

                  // Profile Picture
                  bool showProfilePic = (i == 0 || messages[i]['timestamp'] != messages[i - 1]['timestamp']);

                  messageWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe && showProfilePic)
                            CircleAvatar(
                              backgroundImage: NetworkImage(otherUserProfilePic),
                            ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // Check if message contains an image or text
                              data['imageUrl'] != null
                                  ? Image.network(data['imageUrl'], width: 200, height: 200)
                                  : Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue[100] : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(data['text'] ?? ''),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                messageTimeAgo,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          if (isMe && showProfilePic)
                            CircleAvatar(
                              backgroundImage: NetworkImage(data['profilePictureUrl'] ?? currentUserProfilePic),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  reverse: true,
                  children: messageWidgets,
                );
              },
            ),
          ),

          // Message Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => sendMessage(chatRoomId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
