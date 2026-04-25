import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser!;

  String get conversationId {
    List<String> ids = [currentUser.uid, widget.otherUserId];
    ids.sort(); // always sorts alphabetically
    return ids.join("_");
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    if (currentUser.uid == widget.otherUserId) return; // 🛡️ guard

    final messageText = messageController.text.trim();

    final convoRef = FirebaseFirestore.instance
        .collection("conversations")
        .doc(conversationId);

    await convoRef.set({
      "participants": FieldValue.arrayUnion(
          [currentUser.uid, widget.otherUserId]), // ✅ fixed
      "lastMessage": messageText,
      "lastTimestamp": FieldValue.serverTimestamp(),
      "unread_${widget.otherUserId}": FieldValue.increment(1),
    }, SetOptions(merge: true));

    await convoRef.collection("messages").add({
      "senderId": currentUser.uid,
      "senderName": currentUser.email,
      "text": messageText,

      // 🔥 ONLY ONE TIME FIELD (IMPORTANT)
      "timestamp": FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final convoRef = FirebaseFirestore.instance
        .collection("conversations")
        .doc(conversationId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          // -------- MESSAGE LIST --------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: convoRef
                  .collection("messages")
                  .orderBy("timestamp", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;

                    final isMe = data["senderId"] == currentUser.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.green.shade300
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(data["text"] ?? ""),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // -------- INPUT FIELD --------
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                        hintText: "Type message...",
                        border: OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
