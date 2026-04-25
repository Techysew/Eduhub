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
    ids.sort();
    return ids.join("_");
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    if (currentUser.uid == widget.otherUserId) return;

    final messageText = messageController.text.trim();
    final convoRef = FirebaseFirestore.instance.collection("conversations").doc(conversationId);

    // Update conversation metadata
    await convoRef.set({
      "participants": FieldValue.arrayUnion([currentUser.uid, widget.otherUserId]),
      "lastMessage": messageText,
      "lastTimestamp": FieldValue.serverTimestamp(),
      "unread_${widget.otherUserId}": FieldValue.increment(1),
    }, SetOptions(merge: true));

    // Send the actual message
    await convoRef.collection("messages").add({
      "senderId": currentUser.uid,
      "senderName": currentUser.email,
      "text": messageText,
      "timestamp": FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final convoRef = FirebaseFirestore.instance.collection("conversations").doc(conversationId);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.otherUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // Background Blobs
          Positioned(top: -50, right: -50, child: _Blob(color: const Color(0xFF009639))),
          Positioned(bottom: -50, left: -50, child: _Blob(color: const Color(0xFF3B82F6))),
          
          Column(
            children: [
              // --- Message List ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: convoRef.collection("messages").orderBy("timestamp", descending: false).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF009639)));
                    }

                    final messages = snapshot.data!.docs;

                    if (messages.isEmpty) {
                      return Center(child: Text("Start the conversation", style: TextStyle(color: Colors.white.withOpacity(0.3))));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data = messages[index].data() as Map<String, dynamic>;
                        final isMe = data["senderId"] == currentUser.uid;
                        return _ChatBubble(text: data["text"] ?? "", isMe: isMe);
                      },
                    );
                  },
                ),
              ),

              // --- Input Field ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131929),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Type message...",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          filled: true,
                          fillColor: const Color(0xFF0A0F1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: const BoxDecoration(color: Color(0xFF009639), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: sendMessage,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Custom Chat Bubble Widget ─────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const _ChatBubble({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF009639) : const Color(0xFF131929),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }
}

// ── Background Blob Helper ────────────────────────────────────────
class _Blob extends StatelessWidget {
  final Color color;
  const _Blob({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withOpacity(0.15), Colors.transparent])),
      );
}