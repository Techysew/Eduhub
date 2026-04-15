import 'package:flutter/material.dart';
import 'services/auth_service.dart'; // Updated import path
import 'verify_email_page.dart';

class RegistrationPage extends StatefulWidget {
  final String role;

  const RegistrationPage({super.key, required this.role});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;

  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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

  Future<void> register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage("❌ Fill all fields");
      return;
    }

    if (!(hasMinLength &&
        hasUppercase &&
        hasLowercase &&
        hasNumber &&
        hasSpecialChar)) {
      showMessage("❌ Weak password. Follow the rules below");
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.registerUser(
      username: username,
      email: email,
      password: password,
      role: widget.role,
    );

    setState(() => isLoading = false);

    if (result == "SUCCESS") {
      showMessage(
        "✅ Registration successful! Verify your email before login.",
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
      );
      return;
    }

    // Handle errors
    switch (result) {
      case "USERNAME_TAKEN":
        showMessage("❌ Username already taken");
        break;
      case "EMAIL_EXISTS":
        showMessage("❌ Email already exists");
        break;
      case "INVALID_EMAIL":
        showMessage("❌ Invalid email");
        break;
      case "WEAK_PASSWORD":
        showMessage("❌ Weak password");
        break;
      default:
        showMessage("❌ $result");
    }
  }

  Widget rule(bool ok, String text) {
    return Row(
      children: [
        Icon(ok ? Icons.check : Icons.close,
            color: ok ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register as ${widget.role}"),
        backgroundColor: const Color(0xFF009639),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
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
            rule(hasMinLength, "8+ chars"),
            rule(hasUppercase, "Uppercase"),
            rule(hasLowercase, "Lowercase"),
            rule(hasNumber, "Number"),
            rule(hasSpecialChar, "Special char"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009639),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register",
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
