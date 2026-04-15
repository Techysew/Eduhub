import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ChatPage.dart';

class StudentProfilePage extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String studentEmail;

  const StudentProfilePage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(studentName),
        backgroundColor: const Color(0xFF009639),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    otherUserId: studentId,
                    otherUserName: studentName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // -------- STUDENT INFO HEADER --------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF009639).withOpacity(0.1),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: const Color(0xFF009639),
                  child: Text(
                    studentName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 28),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  studentName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(studentEmail, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Achievements & Certificates",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // -------- ACHIEVEMENTS LIST --------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("achievements")
                  .where("studentId", isEqualTo: studentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No achievements found"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    // ✅ decode base64 certificate — same as profile image
                    Uint8List? certBytes;
                    final base64Str = data["certificateBase64"] ?? "";
                    if (base64Str.isNotEmpty) {
                      try {
                        certBytes = base64Decode(base64Str);
                      } catch (_) {}
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF009639).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.emoji_events,
                                  color: Color(0xFF009639)),
                            ),
                            title: Text(
                              data["title"] ?? "",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${data["faculty"] ?? ""} • ${data["department"] ?? ""}\nPosition: ${data["position"] ?? ""}",
                            ),
                          ),

                          // ✅ show certificate image if exists — tap to enlarge
                          if (certBytes != null)
                            GestureDetector(
                              onTap: () {
                                // Open full screen certificate view
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppBar(
                                          title: const Text("Certificate"),
                                          automaticallyImplyLeading: false,
                                          actions: [
                                            IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            )
                                          ],
                                        ),
                                        InteractiveViewer(
                                          child: Image(
                                            image: MemoryImage(certBytes!),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image(
                                    image: MemoryImage(certBytes),
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Text(
                                "No certificate uploaded",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // -------- CHAT BUTTON --------
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: Text("Message $studentName"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009639),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    otherUserId: studentId,
                    otherUserName: studentName,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
