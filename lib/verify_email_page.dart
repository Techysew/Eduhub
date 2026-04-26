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
      body: Stack(
        children: [
          // Background Blobs
          Positioned(top: -80, right: -60, child: _Blob(color: const Color(0xFF009639))),
          Positioned(bottom: -100, left: -70, child: _Blob(color: const Color(0xFF3B82F6))),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text('Verify Email',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Spacer(),
                  
                  // Verification Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131929),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isEmailVerified ? Icons.check_circle : Icons.email_rounded,
                          size: 64,
                          color: isEmailVerified ? const Color(0xFF009639) : Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isEmailVerified ? "Verified!" : "Check Your Email",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isEmailVerified
                              ? "Redirecting to login..."
                              : "We've sent a link to:\n$email",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14),
                        ),
                        if (!isEmailVerified) ...[
                          const SizedBox(height: 30),
                          // Resend Button
                          GestureDetector(
                            onTap: canResendEmail ? () async {
                              await sendVerificationEmail();
                              startResendCooldown();
                            } : null,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: canResendEmail 
                                    ? [const Color(0xFF009639), const Color(0xFF10B981)]
                                    : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.1)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  canResendEmail ? "Resend Verification" : "Resend in ${resendSeconds}s",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: cancelRegistration,
                            child: Text("Cancel", style: TextStyle(color: Colors.white.withOpacity(0.4))),
                          ),
                        ] else 
                          const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: CircularProgressIndicator(color: Color(0xFF009639)),
                          )
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  const _Blob({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.12), Colors.transparent],
          ),
        ),
      );
}