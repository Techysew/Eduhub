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

class _UniversalLoginPageState extends State<UniversalLoginPage>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E2A45),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> showForgotPasswordDialog() async {
    final resetEmailController =
        TextEditingController(text: emailController.text.trim());

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF131929),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your email and we'll send a reset link.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Email field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0F1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 13),
                    prefixIcon: Icon(Icons.mail_outline_rounded,
                        color: Colors.white.withOpacity(0.3), size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
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
                          showMessage("✅ Reset link sent. Check your inbox.");
                        } on FirebaseAuthException catch (e) {
                          Navigator.pop(context);
                          if (e.code == 'user-not-found') {
                            showMessage("❌ No account found with this email.");
                          } else if (e.code == 'invalid-email') {
                            showMessage("❌ Invalid email address.");
                          } else {
                            showMessage("❌ Failed to send reset email.");
                          }
                        }
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Send Link',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        showMessage("❌ Email not verified. Please check your inbox.");
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
            builder: (_) =>
                ChooseRolePage(username: username, roles: roles),
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
          dashboard =
              RecruiterDashboardPage(username: username, roles: roles);
          break;
        default:
          dashboard = StudentDashboardPage(username: username, roles: roles);
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => dashboard,
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          showMessage("❌ No account found, or password is incorrect.");
          break;
        case 'wrong-password':
          showMessage("❌ Incorrect password. Try again or reset it.");
          break;
        case 'invalid-email':
          showMessage("❌ That doesn't look like a valid email.");
          break;
        case 'user-disabled':
          showMessage("❌ This account has been disabled.");
          break;
        case 'too-many-requests':
          showMessage("⚠️ Too many attempts. Please wait and try again.");
          break;
        case 'network-request-failed':
          showMessage("⚠️ No internet connection.");
          break;
        default:
          showMessage("❌ Login failed (${e.code}). Please try again.");
      }
    } catch (e) {
      setState(() => isLoading = false);
      showMessage("An unexpected error occurred. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // ── Background blobs ──────────────────────────────────────
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF3B82F6).withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: FadeTransition(
                opacity: _fadeController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // Logo badge
                    _slide(
                      controller: _slideController,
                      begin: const Offset(0, -0.3),
                      intervalEnd: 0.6,
                      child: Center(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF3B82F6).withOpacity(0.35),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.white, size: 32),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // App name
                    _slide(
                      controller: _slideController,
                      intervalStart: 0.05,
                      intervalEnd: 0.65,
                      child: const Center(
                        child: Text(
                          'EduHub',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Heading
                    _slide(
                      controller: _slideController,
                      intervalStart: 0.1,
                      intervalEnd: 0.7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 36,
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF3B82F6),
                                Color(0xFF8B5CF6),
                              ]),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Welcome back — we\'ve missed you.',
                            style: TextStyle(
                              fontSize: 14.5,
                              color: Colors.white.withOpacity(0.42),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Email field
                    _slide(
                      controller: _slideController,
                      intervalStart: 0.2,
                      intervalEnd: 0.78,
                      child: _buildField(
                        controller: emailController,
                        label: 'Email address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Password field
                    _slide(
                      controller: _slideController,
                      intervalStart: 0.28,
                      intervalEnd: 0.85,
                      child: _buildPasswordField(),
                    ),

                    // Forgot password
                    _slide(
                      controller: _slideController,
                      intervalStart: 0.32,
                      intervalEnd: 0.88,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 36)),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF3B82F6).withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login button
                    _slide(
                      controller: _slideController,
                      intervalStart: 0.38,
                      intervalEnd: 0.92,
                      child: _buildLoginButton(),
                    ),

                    const SizedBox(height: 32),

                    // Divider
                    _slide(
                      controller: _slideController,
                      intervalStart: 0.42,
                      intervalEnd: 0.95,
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                                color: Colors.white.withOpacity(0.08),
                                thickness: 1),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Don\'t have an account?',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                                color: Colors.white.withOpacity(0.08),
                                thickness: 1),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sign up hint
                    _slide(
                      controller: _slideController,
                      intervalStart: 0.45,
                      intervalEnd: 1.0,
                      child: Center(
                        child: Text(
                          'Sign up from the home screen',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _slide({
    required AnimationController controller,
    required Widget child,
    Offset begin = const Offset(0, 0.25),
    double intervalStart = 0.0,
    double intervalEnd = 1.0,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(intervalStart, intervalEnd,
              curve: Curves.easeOutCubic),
        ),
      ),
      child: child,
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          prefixIcon:
              Icon(icon, color: Colors.white.withOpacity(0.3), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TextField(
        controller: passwordController,
        obscureText: !isPasswordVisible,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle:
              TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline_rounded,
              color: Colors.white.withOpacity(0.3), size: 20),
          suffixIcon: GestureDetector(
            onTap: () =>
                setState(() => isPasswordVisible = !isPasswordVisible),
            child: Icon(
              isPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: isLoading ? null : loginUser,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [
                    const Color(0xFF3B82F6).withOpacity(0.5),
                    const Color(0xFF8B5CF6).withOpacity(0.5),
                  ]
                : [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.2),
                )
              : const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}