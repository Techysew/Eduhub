import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

import '../services/auth_service.dart';
import '../choose_role_page.dart';
import 'kuppi_sessions_page.dart';
import 'my_courses_page.dart';
import 'courses_page.dart';
import 'programs_by_clubs_page.dart';

class StudentDashboardPage extends StatefulWidget {
  final String username;
  final List<String> roles;

  const StudentDashboardPage({
    super.key,
    required this.username,
    required this.roles,
  });

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  Uint8List? _profileImageBytes;
  bool uploading = false;

  int completedCourses = 5;
  int points = 120;
  double performance = 0.75;

  @override
  void initState() {
    super.initState();
    loadProfileImage();
  }

  /// ================= LOAD PROFILE IMAGE =================
  Future<void> loadProfileImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (doc.exists && doc.data()!.containsKey("profile_image")) {
        final base64String = doc.data()!["profile_image"];
        final bytes = base64Decode(base64String);

        setState(() {
          _profileImageBytes = bytes;
        });
      }
    } catch (_) {}
  }

  /// ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _profileImageBytes = bytes;
    });

    await uploadImageToFirestore(bytes);
  }

  /// ================= UPLOAD IMAGE =================
  Future<void> uploadImageToFirestore(Uint8List bytes) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      setState(() => uploading = true);

      final base64String = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set({"profile_image": base64String}, SetOptions(merge: true));

      setState(() => uploading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated")),
      );
    } catch (e) {
      setState(() => uploading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload: $e")),
      );
    }
  }

  /// ================= LOGOUT =================
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pop(context);
  }

  /// ================= NAVIGATION =================
  void openMyCourses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyCoursesPage()),
    );
  }

  void openRecommended() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoursesPage()),
    );
  }

  void openTutorials() {}

  void openProgramsByClubs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProgramsByClubsPage(),
      ),
    );
  }

  void openAssignments() {}
  void openAchievements() {}

  /// ================= ADD ROLE & REDIRECT =================
  Future<void> addRoleAndRedirect(String role) async {
    final result = await AuthService.addRole(role);

    if (result == "ROLE_ADDED_SUCCESS") {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      final data = doc.data();

      if (data != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChooseRolePage(
              username: data["username"],
              roles: List<String>.from(data["roles"] ?? []),
            ),
          ),
        );
      }
    } else if (result == "ROLE_ALREADY_EXISTS") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already have this role")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Student Dashboard"),
        backgroundColor: const Color(0xFF009639),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// PROFILE
            GestureDetector(
              onTap: pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageBytes != null
                        ? MemoryImage(_profileImageBytes!)
                        : null,
                    child: _profileImageBytes == null
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                  if (uploading)
                    const Positioned.fill(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Text(
              "Welcome, ${widget.username}!",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),

            /// PERFORMANCE CARD
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Your Performance",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: performance,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            buildMenuButton(Icons.book, "My Courses", openMyCourses),
            buildMenuButton(
                Icons.auto_awesome, "Recommended Courses", openRecommended),
            buildMenuButton(
                Icons.video_library, "Tutorials / Resources", openTutorials),
            buildMenuButton(
                Icons.live_tv, "Programs by Clubs", openProgramsByClubs),
            buildMenuButton(Icons.assignment, "Assignments", openAssignments),
            buildMenuButton(
                Icons.emoji_events, "Achievements / Badges", openAchievements),

            const SizedBox(height: 30),

            /// LOGOUT
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009639),
                ),
                child: const Text("Logout"),
              ),
            ),

            const SizedBox(height: 15),

            if (!widget.roles.contains("club"))
              buildMenuButton(
                Icons.groups,
                "Add Club Role",
                () => addRoleAndRedirect("club"),
              ),

            if (!widget.roles.contains("tutor"))
              buildMenuButton(
                Icons.menu_book,
                "Add Tutor Role",
                () => addRoleAndRedirect("tutor"),
              ),

            if (!widget.roles.contains("recruiter"))
              buildMenuButton(
                Icons.business_center,
                "Add Recruiter Role",
                () => addRoleAndRedirect("recruiter"),
              ),

            const SizedBox(height: 10),

            /// SWITCH ROLE
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
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
                  backgroundColor: Colors.orange,
                ),
                child: const Text("Switch Role"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenuButton(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 55),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 15),
            Text(title),
          ],
        ),
      ),
    );
  }
}
