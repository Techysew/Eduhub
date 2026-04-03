import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class KuppiSessionsPage extends StatefulWidget {
  const KuppiSessionsPage({super.key});

  @override
  State<KuppiSessionsPage> createState() => _KuppiSessionsPageState();
}

class _KuppiSessionsPageState extends State<KuppiSessionsPage> {
  String searchText = "";

  Future openLink(String link) async {
    if (link.isEmpty) return;

    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication); // ✅ FIXED
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kuppi Sessions")),
      body: Column(
        children: [
          /// SEARCH
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search sessions...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => searchText = value.toLowerCase()),
            ),
          ),

          /// LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("kuppi_sessions")
                  .where("isDeleted", isEqualTo: false)
                  .snapshots(), // ✅ removed orderBy

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No Kuppi sessions available"));
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return (data["title"] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains(searchText) ||
                      (data["subject"] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains(searchText) ||
                      (data["topic"] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains(searchText) ||
                      (data["tutorName"] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains(searchText);
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final data = filtered[i].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data["title"] ?? "",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("Subject: ${data["subject"] ?? ""}"),
                            Text("Topic: ${data["topic"] ?? ""}"),
                            Text("Tutor: ${data["tutorName"] ?? ""}"),
                            Text(
                              "Date: ${DateFormat.yMMMd().format(
                                (data["dateTime"] as Timestamp).toDate(),
                              )}",
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      openLink(data["zoomLink"] ?? ""),
                                  child: const Text("Join"),
                                ),
                                const SizedBox(width: 10),
                                if ((data["materials"] ?? "").isNotEmpty)
                                  ElevatedButton(
                                    onPressed: () =>
                                        openLink(data["materials"]),
                                    child: const Text("Materials"),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
