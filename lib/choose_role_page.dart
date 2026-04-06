import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_dashboard_page.dart';
import 'tutor_dashboard_page.dart';
import 'club_dashboard_page.dart';
import 'recruiter_dashboard_page.dart';

class ChooseRolePage extends StatefulWidget {
  final String username;

  const ChooseRolePage({
    super.key,
    required this.username,
    required List<String> roles,
  });

  @override
  State<ChooseRolePage> createState() => _ChooseRolePageState();
}

class _ChooseRolePageState extends State<ChooseRolePage> {
  List<String> roles = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRoles();
  }

  Future<void> loadRoles() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (doc.exists) {
      roles = List<String>.from(doc["roles"] ?? []);
    }

    if (!mounted) return;

    setState(() => loading = false);

    if (roles.length == 1) {
      goToDashboard(roles.first);
    }
  }

  void goToDashboard(String role) {
    Widget page;

    switch (role) {
      case "student":
        page = StudentDashboardPage(username: widget.username, roles: roles);
        break;
      case "tutor":
        page = TutorDashboardPage(username: widget.username, roles: roles);
        break;
      case "club":
        page = ClubDashboardPage(username: widget.username, roles: roles);
        break;
      case "recruiter":
        page = RecruiterDashboardPage(username: widget.username, roles: roles);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Your Role"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: roles.map((role) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009639),
                  ),
                  onPressed: () => goToDashboard(role),
                  child: Text(
                    "Continue as ${role.toUpperCase()}",
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
