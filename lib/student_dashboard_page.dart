import 'package:eduhub/add_achievement_page.dart';
import 'package:eduhub/chat_list_page.dart';
import 'package:eduhub/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

import '../services/auth_service.dart';
import '../choose_role_page.dart';
import 'kuppi_sessions_page.dart';
import 'my_courses_page.dart';
import 'courses_page.dart';
import 'programs_by_clubs_page.dart';

class StudentDashboardPage extends StatefulWidget {
  final String username;
  final List<String> roles;

  const StudentDashboardPage({
    super.key,
    required this.username,
    required this.roles,
  });

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage>
    with TickerProviderStateMixin {
  Uint8List? _profileImageBytes;
  bool uploading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Menu items: icon, label, gradient colors, callback
  late final List<Map<String, dynamic>> _menuItems;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _menuItems = [
      {
        'icon': Icons.book_rounded,
        'label': 'My Courses',
        'description': 'View enrolled courses',
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
        'onTap': openMyCourses,
      },
      {
        'icon': Icons.video_call_rounded,
        'label': 'Kuppi Sessions',
        'description': 'Join study sessions',
        'gradient': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
        'onTap': openKuppiSessions,
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'label': 'Recommended Courses',
        'description': 'Curated just for you',
        'gradient': [const Color(0xFF10B981), const Color(0xFF3B82F6)],
        'onTap': openRecommended,
      },
      {
        'icon': Icons.live_tv_rounded,
        'label': 'Club Programs',
        'description': 'Explore club activities',
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
        'onTap': openProgramsByClubs,
      },
      {
        'icon': Icons.emoji_events_rounded,
        'label': 'Achievements',
        'description': 'Track your milestones',
        'gradient': [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
        'onTap': openAchievements,
      },
    ];

    loadProfileImage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> loadProfileImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();
      if (doc.exists && doc.data()!.containsKey("profile_image")) {
        final base64String = doc.data()!["profile_image"];
        setState(() => _profileImageBytes = base64Decode(base64String));
      }
    } catch (_) {}
  }

  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _profileImageBytes = bytes);
    await uploadImageToFirestore(bytes);
  }

  Future<void> uploadImageToFirestore(Uint8List bytes) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      setState(() => uploading = true);
      final base64String = base64Encode(bytes);
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set({"profile_image": base64String}, SetOptions(merge: true));
      setState(() => uploading = false);
    } catch (e) {
      setState(() => uploading = false);
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void openMyCourses() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const MyCoursesPage()));
  void openRecommended() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const CoursesPage()));
  void openProgramsByClubs() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgramsByClubsPage()));
  void openAchievements() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAchievementPage()));
  void openKuppiSessions() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KuppiSessionsPage()));

  @override
  Widget build(BuildContext context) {
    final initials = widget.username.isNotEmpty
        ? widget.username[0].toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // ── Background blobs ────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
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

          // ── Main content ─────────────────────────────────
          FadeTransition(
            opacity: _fadeController,
            child: SafeArea(
              child: Column(
                children: [
                  // ── Top bar ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                    child: Row(
                      children: [
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${widget.username} 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Text(
                                'Student Dashboard',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Chat icon
                        _topBarIcon(
                          icon: Icons.chat_bubble_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChatListPage()),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Notifications icon
                        _topBarIcon(
                          icon: Icons.notifications_rounded,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),

                        // Settings menu
                        _SettingsMenu(
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfilePage(
                                  username: widget.username),
                            ),
                          ),
                          onSwitch: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChooseRolePage(
                                  username: widget.username,
                                  roles: widget.roles),
                            ),
                          ),
                          onLogout: logout,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // ── Profile card ──────────────
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _slideController,
                              curve: const Interval(0.0, 0.6,
                                  curve: Curves.easeOutCubic),
                            )),
                            child: _buildProfileCard(initials),
                          ),

                          const SizedBox(height: 24),

                          // ── Section label ─────────────
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _slideController,
                              curve: const Interval(0.1, 0.65,
                                  curve: Curves.easeOutCubic),
                            )),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF8B5CF6)
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Quick Access',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── Menu items ────────────────
                          ..._menuItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(0, 0.3 + index * 0.05),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _slideController,
                                curve: Interval(
                                  0.15 + index * 0.08,
                                  (0.65 + index * 0.08).clamp(0.0, 1.0),
                                  curve: Curves.easeOutCubic,
                                ),
                              )),
                              child: _buildMenuCard(item),
                            );
                          }),

                          const SizedBox(height: 20),
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

  Widget _topBarIcon(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child:
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
      ),
    );
  }

  Widget _buildProfileCard(String initials) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: pickImage,
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _profileImageBytes == null
                        ? const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _profileImageBytes != null
                      ? ClipOval(
                          child: Image(
                            image: MemoryImage(_profileImageBytes!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
                // Camera badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF131929), width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 12),
                  ),
                ),
                if (uploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Student',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap avatar to update photo',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> item) {
    final gradientColors = item['gradient'] as List<Color>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: item['onTap'] as VoidCallback,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              // Gradient icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item['icon'] as IconData,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['description'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.white.withOpacity(0.25)),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings Menu ─────────────────────────────────────────────────────────────

class _SettingsMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onSwitch;
  final VoidCallback onLogout;

  const _SettingsMenu({
    required this.onEdit,
    required this.onSwitch,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF131929),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 48),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'switch':
            onSwitch();
            break;
          case 'logout':
            onLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        _menuItem('edit', Icons.person_outline_rounded, 'Edit Profile',
            Colors.white),
        _menuItem(
            'switch', Icons.swap_horiz_rounded, 'Switch Role', Colors.white),
        const PopupMenuDivider(height: 1),
        _menuItem(
            'logout', Icons.logout_rounded, 'Logout', const Color(0xFFEF4444)),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(Icons.settings_rounded,
            color: Colors.white.withOpacity(0.8), size: 20),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}