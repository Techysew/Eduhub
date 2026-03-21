import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_dashboard_page.dart';
import 'tutor_dashboard_page.dart';
import 'club_dashboard_page.dart';
import 'recruiter_dashboard_page.dart';

class ChooseRolePage extends StatefulWidget {
  final String username;
  final List<String>? roles;

  const ChooseRolePage({super.key, required this.username, this.roles});

  @override
  State<ChooseRolePage> createState() => _ChooseRolePageState();
}

class _ChooseRolePageState extends State<ChooseRolePage> {
  List<String> roles = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.roles != null && widget.roles!.isNotEmpty) {
      roles = widget.roles!;
      loading = false;
    } else {
      loadRoles();
    }
  }

  Future<void> loadRoles() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      final data = doc.data();
      if (data != null) {
        if (data["roles"] != null) {
          roles = List<String>.from(data["roles"]);
        } else if (data["role"] != null) {
          roles = [data["role"]];
        }
      }

      if (!mounted) return;

      setState(() => loading = false);

      if (roles.length == 1) {
        goToDashboard(roles.first);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error loading roles: $e")));
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
      appBar: AppBar(title: const Text("Choose Your Role")),
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
                  onPressed: () => goToDashboard(role),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                  ),
                  child: Text(
                    "Continue as ${role.toUpperCase()}",
                    style: const TextStyle(fontSize: 18),
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
