import 'package:flutter/material.dart';
import 'registration_page.dart';
import 'splash_screen.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Each role: id, label, icon, gradient
  static const List<Map<String, dynamic>> _roles = [
    {
      'role': 'student',
      'label': 'Student',
      'subtitle': 'Enroll in courses & track progress',
      'icon': Icons.school_rounded,
      'gradient': [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    },
    {
      'role': 'tutor',
      'label': 'Tutor / Mentor',
      'subtitle': 'Create courses & host Kuppi sessions',
      'icon': Icons.cast_for_education_rounded,
      'gradient': [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    },
    {
      'role': 'club',
      'label': 'Club',
      'subtitle': 'Manage programs & club activities',
      'icon': Icons.groups_rounded,
      'gradient': [Color(0xFF10B981), Color(0xFF3B82F6)],
    },
    {
      'role': 'recruiter',
      'label': 'Recruiter',
      'subtitle': 'Find & connect with top talent',
      'icon': Icons.work_rounded,
      'gradient': [Color(0xFFF59E0B), Color(0xFFEF4444)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // ── Background blobs ──────────────────────────
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 280, height: 280,
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
            bottom: -100, left: -70,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────
          FadeTransition(
            opacity: _fadeController,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // ── Title ────────────────────────────
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _fadeController,
                        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
                      )),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App logo badge
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.hub_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Select Your Role',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choose how you\'ll use EduHub',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Role cards ───────────────────────
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _roles.length,
                        itemBuilder: (context, index) {
                          final role = _roles[index];
                          final gradient =
                              role['gradient'] as List<Color>;

                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(0, 0.25 + index * 0.06),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _fadeController,
                              curve: Interval(
                                (0.1 + index * 0.1).clamp(0.0, 0.6),
                                (0.6 + index * 0.1).clamp(0.0, 1.0),
                                curve: Curves.easeOutCubic,
                              ),
                            )),
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) =>
                                      RegistrationPage(role: role['role']),
                                  transitionsBuilder: (_, anim, __, child) =>
                                      FadeTransition(
                                          opacity: anim, child: child),
                                  transitionDuration:
                                      const Duration(milliseconds: 350),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131929),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.07)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradient[0].withOpacity(0.1),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Icon badge
                                    Container(
                                      width: 52, height: 52,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: gradient,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                gradient[0].withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                          role['icon'] as IconData,
                                          color: Colors.white, size: 26),
                                    ),
                                    const SizedBox(width: 16),

                                    // Labels
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(role['label'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.3,
                                              )),
                                          const SizedBox(height: 3),
                                          Text(role['subtitle'],
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.4),
                                                fontSize: 12.5,
                                              )),
                                        ],
                                      ),
                                    ),

                                    // Arrow
                                    Container(
                                      width: 32, height: 32,
                                      decoration: BoxDecoration(
                                        color: gradient[0].withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: gradient[0], size: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Back to login ────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 4),
                      child: GestureDetector(
                        onTap: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SplashScreen()),
                          (route) => false,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back_rounded,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 18),
                              const SizedBox(width: 8),
                              Text('Back to Login',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
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