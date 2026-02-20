import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectsPerformancePage extends StatefulWidget {
  const ProjectsPerformancePage({super.key});

  @override
  State<ProjectsPerformancePage> createState() =>
      _ProjectsPerformancePageState();
}

class _ProjectsPerformancePageState extends State<ProjectsPerformancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Projects & Performance"),
        backgroundColor: const Color(0xFF009639),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Courses"),
            Tab(text: "Clubs / Programs"),
          ],
        ),
      ),
      body: Column(
        children: [
          /// ===== PERFORMANCE SUMMARY =====
          FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance.collection("users").doc(uid).get(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox();

              final data = snap.data!.data() as Map<String, dynamic>? ?? {};
              final performance = data["performance"] ?? 0.8;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("Overall Performance",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: performance,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 5),
                    Text("${(performance * 100).toInt()}%"),
                  ],
                ),
              );
            },
          ),

          /// ===== PROJECT LIST =====
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildProjectList("course"),
                buildProjectList("club"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProjectList(String type) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("projects")
          .where("studentId", isEqualTo: uid)
          .where("type", isEqualTo: type)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final projects = snapshot.data!.docs;

        if (projects.isEmpty) {
          return const Center(child: Text("No records found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (_, i) {
            final data = projects[i].data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                leading: Icon(type == "course" ? Icons.school : Icons.groups),
                title: Text(data["title"]),
                subtitle: Text("Grade: ${data["grade"]} • ${data["date"]}"),
                onTap: () => showDetails(data),
              ),
            );
          },
        );
      },
    );
  }

  void showDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data["title"]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Organized by: ${data["organizer"]}"),
            const SizedBox(height: 10),
            Text("Grade: ${data["grade"]}"),
            const SizedBox(height: 10),
            Text("Role: ${data["role"] ?? "N/A"}"),
            const SizedBox(height: 10),
            Text("Feedback: ${data["feedback"] ?? "None"}"),
            const SizedBox(height: 10),
            Text("Awards: ${data["awards"] ?? "None"}"),
          ],
        ),
      ),
    );
  }
}
