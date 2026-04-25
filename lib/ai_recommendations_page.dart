import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIRecommendationsPage extends StatelessWidget {
  const AIRecommendationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Recommendations"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userSnap.data!.data() as Map<String, dynamic>? ?? {};
          final performance = user["performance"] ?? 0.7;

          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection("courses").snapshots(),
            builder: (context, courseSnap) {
              if (!courseSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final courses = courseSnap.data!.docs;

              final recommended = courses.where((c) {
                final data = c.data() as Map<String, dynamic>;
                return (data["difficulty"] ?? 0.5) >= performance;
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recommended.length,
                itemBuilder: (_, i) {
                  final data = recommended[i].data() as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      title: Text(data["title"]),
                      subtitle: Text(data["description"] ?? ""),
                      trailing: const Icon(Icons.auto_awesome),
                    ),
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
