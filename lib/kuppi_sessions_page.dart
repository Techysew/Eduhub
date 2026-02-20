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
      launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kuppi Sessions")),
      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search by subject / topic / tutor",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchText = value.toLowerCase());
              },
            ),
          ),

          /// SESSION LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("kuppi_sessions")
                  .where("isDeleted", isEqualTo: false) // ✅ hide deleted
                  .orderBy("dateTime")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                /// SAFE SEARCH FILTER
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final title = (data["title"] ?? "").toString().toLowerCase();
                  final subject =
                      (data["subject"] ?? "").toString().toLowerCase();
                  final topic = (data["topic"] ?? "").toString().toLowerCase();
                  final tutor =
                      (data["tutorName"] ?? "").toString().toLowerCase();

                  return title.contains(searchText) ||
                      subject.contains(searchText) ||
                      topic.contains(searchText) ||
                      tutor.contains(searchText);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No sessions found"));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;

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
                                "Date: ${DateFormat.yMMMd().format((data["dateTime"] as Timestamp).toDate())}"),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      openLink(data["zoomLink"] ?? ""),
                                  child: const Text("Join Session"),
                                ),
                                const SizedBox(width: 10),
                                if ((data["materials"] ?? "").isNotEmpty)
                                  ElevatedButton(
                                    onPressed: () =>
                                        openLink(data["materials"]),
                                    child: const Text("Materials"),
                                  )
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
