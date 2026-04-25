import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  final String username;
  const EditProfilePage({super.key, required this.username});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.username;
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? "";
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "username": _nameController.text.trim(),
      });

      if (_emailController.text.trim() != user?.email) {
        await user?.updateEmail(_emailController.text.trim());
      }

      if (_passwordController.text.isNotEmpty) {
        await user?.updatePassword(_passwordController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Profile updated! Please log in again if email changed.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1E2A45),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF1E2A45),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
          labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.35), fontSize: 13),
          prefixIcon:
              Icon(icon, color: Colors.white.withOpacity(0.3), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // ── Background blobs ──────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF3B82F6).withOpacity(0.13),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────
          FadeTransition(
            opacity: _fadeController,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white.withOpacity(0.8),
                                size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Update your account details',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          // ── Avatar placeholder ───────────────
                          Center(
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF3B82F6),
                                    Color(0xFF06B6D4)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6)
                                        .withOpacity(0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 40),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ── Form card ────────────────────────
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131929),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.07)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6)
                                      .withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section label
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF3B82F6),
                                            Color(0xFF06B6D4)
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Account Information',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                _darkField(
                                  controller: _nameController,
                                  label: 'Username',
                                  icon: Icons.person_outline_rounded,
                                ),
                                const SizedBox(height: 12),
                                _darkField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                ),
                                const SizedBox(height: 12),
                                _darkField(
                                  controller: _passwordController,
                                  label: 'New Password',
                                  hint: 'Leave blank to keep the same',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePassword,
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color:
                                          Colors.white.withOpacity(0.3),
                                      size: 20,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Save button
                                GestureDetector(
                                  onTap: _isLoading ? null : _updateProfile,
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: _isLoading
                                          ? null
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFF3B82F6),
                                                Color(0xFF06B6D4),
                                              ],
                                            ),
                                      color: _isLoading
                                          ? Colors.white.withOpacity(0.06)
                                          : null,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      boxShadow: _isLoading
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: const Color(
                                                        0xFF3B82F6)
                                                    .withOpacity(0.3),
                                                blurRadius: 12,
                                                offset:
                                                    const Offset(0, 4),
                                              ),
                                            ],
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              'Save Changes',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Info note ────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFF59E0B)
                                      .withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: const Color(0xFFF59E0B),
                                    size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'If you change your email, you will need to log in again.',
                                    style: TextStyle(
                                      color: const Color(0xFFF59E0B)
                                          .withOpacity(0.85),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}