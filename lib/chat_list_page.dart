import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChatPage.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser!;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // Background Blobs
          Positioned(top: -80, right: -60, child: _Blob(color: const Color(0xFF009639))),
          Positioned(bottom: -100, left: -70, child: _Blob(color: const Color(0xFF3B82F6))),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text(
                        "Messages",
                        style: TextStyle(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("conversations")
                          .where("participants", arrayContains: currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF009639)));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text("No conversations yet",
                                style: TextStyle(color: Colors.white.withOpacity(0.3))),
                          );
                        }

                        var conversations = snapshot.data!.docs;
                        // Sort by timestamp
                        conversations.sort((a, b) {
                          final aTime = (a.data() as Map<String, dynamic>)["lastTimestamp"];
                          final bTime = (b.data() as Map<String, dynamic>)["lastTimestamp"];
                          if (aTime == null || bTime == null) return 0;
                          return (bTime as Timestamp).compareTo(aTime as Timestamp);
                        });

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final data = conversations[index].data() as Map<String, dynamic>;
                            final participants = List<String>.from(data["participants"]);
                            String otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => "");

                            if (otherUserId.isEmpty) return const SizedBox();

                            return _ChatTile(
                              conversationId: conversations[index].id,
                              otherUserId: otherUserId,
                              lastMessage: data["lastMessage"] ?? "",
                              unreadCount: data["unread_${currentUser.uid}"] ?? 0,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Tile Widget ──────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final String conversationId;
  final String otherUserId;
  final String lastMessage;
  final int unreadCount;

  const _ChatTile({
    required this.conversationId,
    required this.otherUserId,
    required this.lastMessage,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox(height: 80);

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final otherUserName = userData?["username"] ?? "User";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF009639).withOpacity(0.2),
              child: Text(otherUserName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
            ),
            title: Text(otherUserName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
            trailing: unreadCount > 0
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFF009639), shape: BoxShape.circle),
                    child: Text("$unreadCount", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                : null,
            onTap: () async {
              await FirebaseFirestore.instance.collection("conversations").doc(conversationId).update({
                "unread_${FirebaseAuth.instance.currentUser!.uid}": 0,
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(otherUserId: otherUserId, otherUserName: otherUserName),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Background Blob Helper ────────────────────────────────────────
class _Blob extends StatelessWidget {
  final Color color;
  const _Blob({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withOpacity(0.1), Colors.transparent])),
      );
}