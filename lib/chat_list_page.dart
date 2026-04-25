import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChatPage.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("conversations")
            .where("participants", arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var conversations = snapshot.data!.docs.toList();
          conversations.sort((a, b) {
            final aTime = a["lastTimestamp"];
            final bTime = b["lastTimestamp"];

            if (aTime == null || bTime == null) return 0;

            return (bTime as Timestamp).compareTo(aTime as Timestamp);
          });
          if (conversations.isEmpty) {
            return const Center(
              child: Text("No conversations yet"),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final data = conversations[index].data() as Map<String, dynamic>;

              final participants = List<String>.from(data["participants"]);

              // Get the OTHER user
              String otherUserId = "";

              for (String id in participants) {
                if (id != currentUser.uid) {
                  otherUserId = id;
                  break;
                }
              }

              if (otherUserId.isEmpty) {
                return const Text("No chat user found");
              }

              final lastMessage = data["lastMessage"] ?? "";
              final unreadCount = data["unread_${currentUser.uid}"] ?? 0;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;

                  final otherUserName = userData?["username"] ?? "User";

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade200,
                      child: Text(
                        otherUserName[0].toUpperCase(),
                      ),
                    ),
                    title: Text(
                      otherUserName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : null,
                    onTap: () async {
                      // Reset unread count
                      await FirebaseFirestore.instance
                          .collection("conversations")
                          .doc(conversations[index].id)
                          .update({
                        "unread_${currentUser.uid}": 0,
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            otherUserId: otherUserId,
                            otherUserName: otherUserName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
