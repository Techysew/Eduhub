import 'package:eduhub/ChatPage.dart';
import 'package:eduhub/StudentProfilePage.dart';
import 'package:eduhub/edit_profile_page.dart'; // Ensure this is imported
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String searchText = "";
  String? positionFilter;

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Recruiter Dashboard"),
        backgroundColor: const Color(0xFF009639),
        automaticallyImplyLeading: false, // <--- THIS REMOVES THE BACK ARROW
        elevation: 0,
        actions: [
          // THE NEW SETTINGS POPUP
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(username: widget.username),
                  ),
                );
              } else if (value == 'switch') {
                // Use pushReplacement here so the ChooseRolePage doesn't have a back arrow either
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChooseRolePage(
                      username: widget.username,
                      roles: widget.roles,
                    ),
                  ),
                );
              } else if (value == 'logout') {
                logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Edit Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'switch',
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Switch Role'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: TextField(
                onChanged: (val) =>
                    setState(() => searchText = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search students...",
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF009639)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // --- FILTERS ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip("All", null),
                const SizedBox(width: 8),
                _buildFilterChip("1st Place", "1st"),
                const SizedBox(width: 8),
                _buildFilterChip("2nd Place", "2nd"),
                const SizedBox(width: 8),
                _buildFilterChip("3rd Place", "3rd"),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),

          // --- RANKED STUDENT LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("achievements")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                Map<String, Map<String, dynamic>> studentMap = {};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = data["studentId"] ?? "";
                  final pos = data["position"] ?? "";

                  if (positionFilter != null && pos != positionFilter) continue;

                  if (!studentMap.containsKey(id)) {
                    studentMap[id] = {
                      "name": data["studentName"] ?? "Unknown",
                      "email": data["studentEmail"] ?? "",
                      "count": 0,
                    };
                  }
                  studentMap[id]!["count"]++;
                }

                var sortedList = studentMap.entries.toList()
                  ..sort((a, b) => (b.value["count"] as int)
                      .compareTo(a.value["count"] as int));

                if (searchText.isNotEmpty) {
                  sortedList = sortedList
                      .where((e) => e.value["name"]
                          .toString()
                          .toLowerCase()
                          .contains(searchText))
                      .toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: sortedList.length,
                  itemBuilder: (context, index) {
                    final student = sortedList[index].value;
                    return _buildStudentCard(
                        student, index, sortedList[index].key);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build stylized filter chips
  Widget _buildFilterChip(String label, String? value) {
    bool isSelected = positionFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => positionFilter = value),
      selectedColor: const Color(0xFF009639).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF009639) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // Helper to build the Student Card
  Widget _buildStudentCard(
      Map<String, dynamic> student, int index, String studentId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF009639).withOpacity(0.1),
          child: Text("${index + 1}",
              style: const TextStyle(
                  color: Color(0xFF009639), fontWeight: FontWeight.bold)),
        ),
        title: Text(student["name"],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text("Certificates: ${student["count"]}\n${student["email"]}"),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentProfilePage(
                studentId: studentId,
                studentName: student["name"],
                studentEmail: student["email"],
              ),
            ),
          );
        },
      ),
    );
  }
}
