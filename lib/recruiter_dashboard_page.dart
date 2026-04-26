import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_page.dart';
import 'choose_role_page.dart';
import 'StudentProfilePage.dart';

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

class _RecruiterDashboardPageState extends State<RecruiterDashboardPage>
    with SingleTickerProviderStateMixin {
  String searchText = "";
  String? positionFilter;
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

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // Background decorations
          Positioned(top: -80, right: -60, child: _Blob(color: const Color(0xFF009639))),
          Positioned(bottom: -100, left: -70, child: _Blob(color: const Color(0xFF3B82F6))),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recruiter Dashboard',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Manage top performing students',
                                style: TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                      _buildSettingsMenu(),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() => searchText = val.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Search students...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(15),
                      ),
                    ),
                  ),
                ),

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildFilterChip("All", null),
                      _buildFilterChip("1st Place", "1st"),
                      _buildFilterChip("2nd Place", "2nd"),
                      _buildFilterChip("3rd Place", "3rd"),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // List
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection("achievements").snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF009639)));
                        }

                        final docs = snapshot.data!.docs;
                        Map<String, Map<String, dynamic>> studentMap = {};

                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final id = data["studentId"] ?? "";
                          final pos = data["position"] ?? "";
                          if (positionFilter != null && pos != positionFilter) continue;
                          if (!studentMap.containsKey(id)) {
                            studentMap[id] = {"name": data["studentName"] ?? "Unknown", "email": data["studentEmail"] ?? "", "count": 0};
                          }
                          studentMap[id]!["count"]++;
                        }

                        var sortedList = studentMap.entries.toList()
                          ..sort((a, b) => (b.value["count"] as int).compareTo(a.value["count"] as int));

                        if (searchText.isNotEmpty) {
                          sortedList = sortedList.where((e) => e.value["name"].toString().toLowerCase().contains(searchText)).toList();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          itemCount: sortedList.length,
                          itemBuilder: (context, index) {
                            return _StudentCard(
                              student: sortedList[index].value,
                              index: index,
                              studentId: sortedList[index].key,
                              slideController: _fadeController,
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

  Widget _buildFilterChip(String label, String? value) {
    bool isSelected = positionFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => positionFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF009639) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1)),
          ),
          child: Text(label, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings, color: Colors.white54),
      color: const Color(0xFF131929),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(username: widget.username)));
        } else if (value == 'switch') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChooseRolePage(username: widget.username, roles: widget.roles)));
        } else if (value == 'logout') {
          logout();
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem('edit', 'Edit Profile', Icons.person_outline),
        _buildPopupItem('switch', 'Switch Role', Icons.swap_horiz),
        const PopupMenuDivider(),
        _buildPopupItem('logout', 'Logout', Icons.logout, isRed: true),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String val, String text, IconData icon, {bool isRed = false}) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isRed ? Colors.red : Colors.white70),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: isRed ? Colors.red : Colors.white70)),
        ],
      ),
    );
  }
}

// ── Student Card Widget ───────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final int index;
  final String studentId;
  final AnimationController slideController;

  const _StudentCard({
    required this.student,
    required this.index,
    required this.studentId,
    required this.slideController,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(parent: slideController, curve: Interval(index * 0.05, 1.0, curve: Curves.easeOutCubic)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF009639).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text("${index + 1}", style: const TextStyle(color: Color(0xFF009639), fontWeight: FontWeight.bold)),
            ),
          ),
          title: Text(student["name"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text("Certificates: ${student["count"]}\n${student["email"]}", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withOpacity(0.3)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProfilePage(studentId: studentId, studentName: student["name"], studentEmail: student["email"]))),
        ),
      ),
    );
  }
}

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