import 'package:eduhub/choose_role_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_dashboard_page.dart';
import 'tutor_dashboard_page.dart';
import 'club_dashboard_page.dart';
import 'recruiter_dashboard_page.dart';

class UniversalLoginPage extends StatefulWidget {
  const UniversalLoginPage({super.key});

  @override
  State<UniversalLoginPage> createState() => _UniversalLoginPageState();
}

class _UniversalLoginPageState extends State<UniversalLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1️⃣ Sign in
      UserCredential cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User user = cred.user!;
      await user.reload(); // refresh to get latest email verification status
      user = FirebaseAuth.instance.currentUser!;

      // 2️⃣ Check email verification
      if (!user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() => isLoading = false);
        showMessage("❌ Your email is not verified. Please check your inbox.");
        return;
      }

      // 3️⃣ Get user data from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      List<String> roles = ["student"];
      String username = "User";

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        roles = List<String>.from(data["roles"] ?? ["student"]);
        username = data["username"] ?? "User";
      }

      setState(() => isLoading = false);

      if (!mounted) return;

      // 4️⃣ Navigate based on roles
      if (roles.length > 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChooseRolePage(username: username, roles: roles),
          ),
        );
        return;
      }

      Widget dashboard;
      switch (roles.first) {
        case "tutor":
          dashboard = TutorDashboardPage(username: username, roles: roles);
          break;
        case "club":
          dashboard = ClubDashboardPage(username: username, roles: roles);
          break;
        case "recruiter":
          dashboard = RecruiterDashboardPage(username: username, roles: roles);
          break;
        default:
          dashboard = StudentDashboardPage(username: username, roles: roles);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => dashboard),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);

      String msg = "Login failed";
      if (e.code == 'user-not-found') msg = "User not found";
      if (e.code == 'wrong-password') msg = "Incorrect password";
      if (e.code == 'invalid-email') msg = "Invalid email";

      showMessage(msg);
    } catch (e) {
      setState(() => isLoading = false);
      showMessage("An unexpected error occurred. Try again.");
      print("🔥 Login error: $e"); // for debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : loginUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009639),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
