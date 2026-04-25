import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_dashboard_page.dart';
import 'tutor_dashboard_page.dart';
import 'club_dashboard_page.dart';
import 'recruiter_dashboard_page.dart';

class ChooseRolePage extends StatefulWidget {
  final String username;

  const ChooseRolePage({
    super.key,
    required this.username,
    required List<String> roles,
  });

  @override
  State<ChooseRolePage> createState() => _ChooseRolePageState();
}

class _ChooseRolePageState extends State<ChooseRolePage>
    with TickerProviderStateMixin {
  List<String> roles = [];
  bool loading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Role metadata: icon, gradient colors, description
  final Map<String, Map<String, dynamic>> _roleMeta = {
    'student': {
      'icon': Icons.school_rounded,
      'label': 'Student',
      'description': 'Access courses & assignments',
      'gradient': [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    },
    'tutor': {
      'icon': Icons.auto_stories_rounded,
      'label': 'Tutor',
      'description': 'Manage sessions & students',
      'gradient': [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    },
    'club': {
      'icon': Icons.groups_rounded,
      'label': 'Club',
      'description': 'Organize events & members',
      'gradient': [Color(0xFF10B981), Color(0xFF3B82F6)],
    },
    'recruiter': {
      'icon': Icons.work_rounded,
      'label': 'Recruiter',
      'description': 'Post roles & review candidates',
      'gradient': [Color(0xFFF59E0B), Color(0xFFEF4444)],
    },
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    loadRoles();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> loadRoles() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (doc.exists) {
      roles = List<String>.from(doc["roles"] ?? []);
    }

    if (!mounted) return;

    setState(() => loading = false);

    _fadeController.forward();
    _slideController.forward();

    if (roles.length == 1) {
      goToDashboard(roles.first);
    }
  }

  void goToDashboard(String role) {
    Widget page;
    switch (role) {
      case "student":
        page = StudentDashboardPage(username: widget.username, roles: roles);
        break;
      case "tutor":
        page = TutorDashboardPage(username: widget.username, roles: roles);
        break;
      case "club":
        page = ClubDashboardPage(username: widget.username, roles: roles);
        break;
      case "recruiter":
        page = RecruiterDashboardPage(username: widget.username, roles: roles);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F1E),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3B82F6),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // Subtle background blobs
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),

                    // Header
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Accent divider
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Choose how you\'d like to continue.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.45),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 44),

                    // Role cards
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: roles.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final role = roles[index];
                          final meta = _roleMeta[role] ??
                              {
                                'icon': Icons.person_rounded,
                                'label': role,
                                'description': 'Continue as $role',
                                'gradient': [
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF06B6D4)
                                ],
                              };

                          final gradientColors =
                              meta['gradient'] as List<Color>;

                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(0, 0.3 + index * 0.1),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _slideController,
                              curve: Interval(
                                index * 0.1,
                                0.6 + index * 0.1,
                                curve: Curves.easeOutCubic,
                              ),
                            )),
                            child: _RoleCard(
                              icon: meta['icon'] as IconData,
                              label: meta['label'] as String,
                              description: meta['description'] as String,
                              gradientColors: gradientColors,
                              onTap: () => goToDashboard(role),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Footer hint
                    Center(
                      child: Text(
                        'You can switch roles anytime from settings',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.25),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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

// ── Role Card Widget ──────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors[0].withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),

              // Gradient icon container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                margin: const EdgeInsets.only(right: 18),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}