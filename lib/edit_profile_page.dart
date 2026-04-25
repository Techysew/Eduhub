import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  final String username;
  const EditProfilePage({super.key, required this.username});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.username;
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? "";
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      // 1. Update Firestore Username
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "username": _nameController.text.trim(),
      });

      // 2. Update Email (Auth)
      if (_emailController.text.trim() != user?.email) {
        await user?.updateEmail(_emailController.text.trim());
      }

      // 3. Update Password (Auth) - Only if field is not empty
      if (_passwordController.text.isNotEmpty) {
        await user?.updatePassword(_passwordController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Profile Updated! Please log in again if email changed.")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Edit Profile"),
          backgroundColor: const Color(0xFF009639)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: "Username", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 15),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: "Email", prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "New Password (Leave blank to keep same)",
                  prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009639),
                        minimumSize: const Size(double.infinity, 50)),
                    child: const Text("Save Changes"),
                  ),
          ],
        ),
      ),
    );
  }
}
