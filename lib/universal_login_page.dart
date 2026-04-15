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

  // ✅ NEW: Forgot password dialog
  Future<void> showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: emailController.text.trim(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter your email address and we'll send you a link to reset your password.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009639),
            ),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                showMessage("Please enter your email");
                return;
              }
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                if (!mounted) return;
                Navigator.pop(context);
                showMessage("✅ Password reset email sent. Check your inbox.");
              } on FirebaseAuthException catch (e) {
                Navigator.pop(context);
                if (e.code == 'user-not-found') {
                  showMessage("❌ No account found with this email.");
                } else if (e.code == 'invalid-email') {
                  showMessage("❌ Invalid email address.");
                } else {
                  showMessage("❌ Failed to send reset email. Try again.");
                }
              }
            },
            child: const Text("Send Reset Link"),
          ),
        ],
      ),
    );
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty && password.isEmpty) {
      showMessage("Please enter your email and password");
      return;
    }
    if (email.isEmpty) {
      showMessage("Please enter your email");
      return;
    }
    if (password.isEmpty) {
      showMessage("Please enter your password");
      return;
    }

    // Basic email format check before hitting Firebase
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      showMessage("Please enter a valid email address");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User user = cred.user!;
      await user.reload();
      user = FirebaseAuth.instance.currentUser!;

      if (!user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() => isLoading = false);
        showMessage("❌ Your email is not verified. Please check your inbox.");
        return;
      }

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

      // ✅ FIXED: Covers both old and new Firebase SDK error codes
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential': // newer Firebase SDK merges these
          showMessage(
              "❌ No account found with this email, or password is incorrect.");
          break;
        case 'wrong-password':
          showMessage("❌ Incorrect password. Try again or reset it below.");
          break;
        case 'invalid-email':
          showMessage("❌ That doesn't look like a valid email address.");
          break;
        case 'user-disabled':
          showMessage("❌ This account has been disabled. Contact support.");
          break;
        case 'too-many-requests':
          showMessage(
              "⚠️ Too many failed attempts. Please wait a moment and try again.");
          break;
        case 'network-request-failed':
          showMessage(
              "⚠️ No internet connection. Check your network and try again.");
          break;
        default:
          showMessage("❌ Login failed (${e.code}). Please try again.");
          debugPrint(
              "🔥 Unhandled FirebaseAuthException: ${e.code} — ${e.message}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      showMessage("An unexpected error occurred. Try again.");
      debugPrint("🔥 Login error: $e");
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
              keyboardType: TextInputType.emailAddress,
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
            const SizedBox(height: 8),

            // ✅ NEW: Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: showForgotPasswordDialog,
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(color: Color(0xFF009639)),
                ),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009639),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Login",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
