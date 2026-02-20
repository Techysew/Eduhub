import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../choose_role_page.dart';

class RoleSwitchButton extends StatelessWidget {
  const RoleSwitchButton({super.key});

  Future<bool> hasMultipleRoles() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    final data = doc.data();
    if (data == null) return false;

    if (data["roles"] != null) {
      return (data["roles"] as List).length > 1;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: hasMultipleRoles(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == false) {
          return const SizedBox();
        }

        return IconButton(
          icon: const Icon(Icons.switch_account),
          tooltip: "Switch Role",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChooseRolePage(
                  username: '',
                  roles: [],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
