import 'package:eduhub/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecruiterRegistrationPage extends StatefulWidget {
  const RecruiterRegistrationPage({super.key});

  @override
  State<RecruiterRegistrationPage> createState() =>
      _RecruiterRegistrationPageState();
}

class _RecruiterRegistrationPageState extends State<RecruiterRegistrationPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;
  bool isPasswordVisible = false;

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void checkPasswordRules(String password) {
    setState(() {
      hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      hasNumber = RegExp(r'[0-9]').hasMatch(password);
      hasSpecialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
      hasMinLength = password.length >= 8;
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    final query = await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .get();
    if (!mounted) return false;
    return query.docs.isEmpty;
  }

  Future<void> registerUser() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    if (!(hasMinLength &&
        hasUppercase &&
        hasLowercase &&
        hasNumber &&
        hasSpecialChar)) {
      showMessage("Password does not meet all requirements");
      return;
    }

    setState(() => isLoading = true);

    final available = await isUsernameAvailable(username);
    if (!mounted) return;
    if (!available) {
      setState(() => isLoading = false);
      showMessage("Username already taken, choose another");
      return;
    }

    try {
      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;

      final user = cred.user;
      if (user == null) throw Exception("User creation failed");

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "username": username,
        "email": email,
        "roles": ["recruiter"]
      });
      if (!mounted) return;

      await user.sendEmailVerification();
      if (!mounted) return;

      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Verify Your Email"),
          content: const Text(
              "A verification email has been sent.\n\nPlease verify your email to login."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => isLoading = false);
    } on FirebaseAuthException catch (e) {
      // Handle email-already-in-use with role check
      if (e.code == "email-already-in-use") {
        try {
          UserCredential cred =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          if (!mounted) return;

          final uid = cred.user!.uid;
          final doc = await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .get();
          if (!mounted) return;

          List roles = [];
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            roles = data["roles"] ?? [];

            if (roles.contains("recruiter")) {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  title: const Text("Role Exists"),
                  content:
                      const Text("You are already registered as recruiter."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const SplashScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
              if (!mounted) return;
            } else {
              roles.add("recruiter");
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .update({"roles": roles});
              if (!mounted) return;

              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  title: const Text("Role Added"),
                  content: const Text(
                      "Recruiter role added successfully.\n\nYou can now login."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const SplashScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
              if (!mounted) return;
            }
          }

          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          setState(() => isLoading = false);
          return;
        } catch (_) {
          if (!mounted) return;
          setState(() => isLoading = false);
          showMessage(
              "Email already exists. Use correct password to add role.");
          return;
        }
      }
      setState(() => isLoading = false);
      showMessage("Registration failed");
    } catch (e) {
      setState(() => isLoading = false);
      showMessage("Error: $e");
    }
  }

  Widget passwordRuleRow(bool ruleMet, String text) {
    return Row(
      children: [
        Icon(ruleMet ? Icons.check_circle : Icons.cancel,
            color: ruleMet ? Colors.green : Colors.red, size: 18),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recruiter Registration"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              onChanged: checkPasswordRules,
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
            const SizedBox(height: 10),
            passwordRuleRow(hasMinLength, "Minimum 8 characters"),
            passwordRuleRow(hasUppercase, "At least 1 uppercase letter"),
            passwordRuleRow(hasLowercase, "At least 1 lowercase letter"),
            passwordRuleRow(hasNumber, "At least 1 number"),
            passwordRuleRow(hasSpecialChar, "At least 1 special character"),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009639),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
