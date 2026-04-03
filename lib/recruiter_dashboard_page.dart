import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'choose_role_page.dart';

class RecruiterDashboardPage extends StatefulWidget {
  final String username;
  final List<String> roles;

  const RecruiterDashboardPage({
    super.key,
    required this.username,
    required this.roles,
  });

  @override
  State<RecruiterDashboardPage> createState() => _RecruiterDashboardPageState();
}

class _RecruiterDashboardPageState extends State<RecruiterDashboardPage> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ❌ removes back arrow
        title: const Text("Recruiter Dashboard"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: Column(
        children: [
          /// ===== SEARCH BAR =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search students by name or skill",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => search = val.toLowerCase()),
            ),
          ),

          /// ===== ANALYTICS CARD =====
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snapshot) {
              int totalStudents = snapshot.data?.docs.length ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      statItem("Students", totalStudents.toString()),
                      statItem("Top Performers", "—"),
                      statItem("Avg Grade", "—"),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          /// ===== STUDENT LIST =====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where("role", isEqualTo: "Student")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data["username"] ?? "").toLowerCase();
                  return name.contains(search);
                }).toList();

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final data = students[i].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(data["username"] ?? "Student"),
                        subtitle: Text(
                            "Performance: ${((data["performance"] ?? 0.7) * 100).toInt()}%"),
                        trailing: ElevatedButton(
                          child: const Text("View"),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(data["username"]),
                                content:
                                    Text("Skills: ${data["skills"] ?? "N/A"}"),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ===== LOGOUT =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: const Color(0xFF009639),
                  ),
                  child: const Text("Logout"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChooseRolePage(
                          username: widget.username,
                          roles: widget.roles,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text("Switch Role"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget statItem(String title, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title),
      ],
    );
  }
}
