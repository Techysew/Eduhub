import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

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

    // Start periodic verification check
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

        // Auto redirect to LoginPage after short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        });
      }
    });
  }

  void startResendCooldown() {
    canResendEmail = false;
    resendSeconds = 30;

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
      MaterialPageRoute(builder: (_) => const LoginPage()),
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
      appBar: AppBar(
        title: const Text("Verify Email"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF009639),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isEmailVerified ? Icons.check_circle : Icons.email,
                size: 90,
                color: const Color(0xFF009639),
              ),
              const SizedBox(height: 20),
              Text(
                isEmailVerified
                    ? "Email Verified Successfully!"
                    : "Verify Your Email",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                isEmailVerified
                    ? "Redirecting to login..."
                    : "We sent a verification link to:\n$email\n\n"
                        "✔ Open your email\n"
                        "✔ Click the verification link\n"
                        "✔ This page will update automatically",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (!isEmailVerified)
                ElevatedButton(
                  onPressed: canResendEmail
                      ? () async {
                          await sendVerificationEmail();
                          startResendCooldown();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009639),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 40),
                  ),
                  child: Text(
                    canResendEmail
                        ? "Resend Email"
                        : "Resend in $resendSeconds s",
                  ),
                ),
              const SizedBox(height: 15),
              if (!isEmailVerified)
                TextButton(
                  onPressed: cancelRegistration,
                  child: const Text("Cancel / Back to Login"),
                ),
              const SizedBox(height: 20),
              if (!isEmailVerified)
                const CircularProgressIndicator(
                  color: Color(0xFF009639),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
