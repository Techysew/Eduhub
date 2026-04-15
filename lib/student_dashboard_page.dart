import 'package:eduhub/add_achievement_page.dart';
import 'package:eduhub/chat_list_page.dart';
import 'package:eduhub/edit_profile_page.dart';
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

  @override
  void initState() {
    super.initState();
    loadProfileImage();
  }

  Future<void> loadProfileImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (doc.exists && doc.data()!.containsKey("profile_image")) {
        final base64String = doc.data()!["profile_image"];
        setState(() => _profileImageBytes = base64Decode(base64String));
      }
    } catch (_) {}
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _profileImageBytes = bytes);
    await uploadImageToFirestore(bytes);
  }

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
    } catch (e) {
      setState(() => uploading = false);
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    // Using pushAndRemoveUntil to clear navigation stack on logout
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  // Navigation Helpers
  void openMyCourses() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const MyCoursesPage()));
  void openRecommended() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const CoursesPage()));
  void openProgramsByClubs() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const ProgramsByClubsPage()));
  void openAchievements() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const AddAchievementPage()));
  void openKuppiSessions() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const KuppiSessionsPage()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF009639), Color(0xFF00C853)]),
          ),
        ),
        title: const Text("Student Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatListPage())),
          ),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),

          /// SETTINGS POPUP MENU (Role Switch & Logout moved here)
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              EditProfilePage(username: widget.username)));
                  break;
                case 'switch':
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChooseRolePage(
                              username: widget.username, roles: widget.roles)));
                  break;
                case 'logout':
                  logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Edit Profile'))),
              const PopupMenuItem(
                  value: 'switch',
                  child: ListTile(
                      leading: Icon(Icons.swap_horiz),
                      title: Text('Switch Role'))),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title:
                          Text('Logout', style: TextStyle(color: Colors.red)))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// PROFILE SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profileImageBytes != null
                              ? MemoryImage(_profileImageBytes!)
                              : null,
                          child: _profileImageBytes == null
                              ? const Icon(Icons.person,
                                  size: 50, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text("Welcome, ${widget.username}",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            /// NAVIGATION MENU
            buildModernMenuTile(Icons.book, "My Courses", openMyCourses),
            buildModernMenuTile(
                Icons.video_call, "Kuppi Sessions", openKuppiSessions),
            buildModernMenuTile(
                Icons.auto_awesome, "Recommended Courses", openRecommended),
            buildModernMenuTile(
                Icons.live_tv, "Club Programs", openProgramsByClubs),
            buildModernMenuTile(
                Icons.emoji_events, "Achievements", openAchievements),
          ],
        ),
      ),
      // REMOVED bottomNavigationBar to clean up the UI
    );
  }

  Widget buildModernMenuTile(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 12,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF009639).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: const Color(0xFF009639), size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600))),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
