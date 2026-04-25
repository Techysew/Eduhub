import 'package:flutter/material.dart';
import 'services/auth_service.dart';
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

  Future<void> register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage("❌ Fill all fields");
      return;
    }

    if (!(hasMinLength && hasUppercase && hasLowercase && hasNumber && hasSpecialChar)) {
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
      );
      return;
    }

    showMessage("❌ $result");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Register as ${widget.role}", style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _Blob(color: const Color(0xFF009639))),
          Positioned(bottom: -50, left: -50, child: _Blob(color: const Color(0xFF3B82F6))),
          
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildField(usernameController, "Username", Icons.person_outline),
                const SizedBox(height: 15),
                _buildField(emailController, "Email", Icons.email_outlined),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  onChanged: checkPasswordRules,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: const Color(0xFF131929),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white24),
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                      onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Rule List
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: const Color(0xFF131929), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _rule(hasMinLength, "8+ characters"),
                      _rule(hasUppercase, "Contains uppercase"),
                      _rule(hasLowercase, "Contains lowercase"),
                      _rule(hasNumber, "Contains a number"),
                      _rule(hasSpecialChar, "Contains special character"),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009639),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Register", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) => TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          filled: true,
          fillColor: const Color(0xFF131929),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          prefixIcon: Icon(icon, color: Colors.white24),
        ),
      );

  Widget _rule(bool ok, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.circle_outlined, 
             color: ok ? const Color(0xFF009639) : Colors.white24, size: 18),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: ok ? Colors.white : Colors.white54, fontSize: 14)),
      ],
    ),
  );
}

// Background Blob Helper
class _Blob extends StatelessWidget {
  final Color color;
  const _Blob({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 200, height: 200,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withOpacity(0.15), Colors.transparent])),
  );
}