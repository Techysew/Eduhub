import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'universal_login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? checkTimer;
  Timer? resendCooldownTimer;

  bool isEmailVerified = false;
  bool canResendEmail = false;
  int resendSeconds = 30;

  @override
  void initState() {
    super.initState();
    startAutoCheck();
    startResendCooldown();
  }

  Future<void> sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Verification email sent")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send email: $e")),
          );
        }
      }
    }
  }

  void startAutoCheck() {
    checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      if (user != null && user.emailVerified) {
        checkTimer?.cancel();
        if (!mounted) return;

        setState(() => isEmailVerified = true);

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UniversalLoginPage()),
          );
        });
      }
    });
  }

  void startResendCooldown() {
    setState(() {
      canResendEmail = false;
      resendSeconds = 30;
    });

    resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds == 0) {
        timer.cancel();
        if (mounted) setState(() => canResendEmail = true);
      } else {
        if (mounted) setState(() => resendSeconds--);
      }
    });
  }

  Future<void> cancelRegistration() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const UniversalLoginPage()),
    );
  }

  @override
  void dispose() {
    checkTimer?.cancel();
    resendCooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Verify Email", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _Blob(color: const Color(0xFF009639))),
          Positioned(bottom: -50, left: -50, child: _Blob(color: const Color(0xFF3B82F6))),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF131929),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEmailVerified ? Icons.check_circle_outline : Icons.email_outlined,
                      size: 80,
                      color: const Color(0xFF009639),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isEmailVerified ? "Verified!" : "Check your email",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      isEmailVerified
                          ? "Redirecting to login..."
                          : "We sent a link to:\n$email\n\nClick the link in your inbox to proceed.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 30),
                    
                    if (!isEmailVerified) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: canResendEmail
                              ? () async {
                                  await sendVerificationEmail();
                                  startResendCooldown();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009639),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(canResendEmail ? "Resend Email" : "Resend in $resendSeconds s"),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: cancelRegistration,
                        child: const Text("Cancel / Back to Login", style: TextStyle(color: Colors.white60)),
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(color: Color(0xFF009639)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background Blob Helper ────────────────────────────────────────
class _Blob extends StatelessWidget {
  final Color color;
  const _Blob({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withOpacity(0.15), Colors.transparent])),
      );
}