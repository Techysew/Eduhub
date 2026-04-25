import 'dart:typed_data';
import 'dart:convert';

import 'package:eduhub/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'choose_role_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_kuppi_session_page.dart';
import 'manage_lessons_page.dart';

class TutorDashboardPage extends StatefulWidget {
  final String username;
  final List<String> roles;

  const TutorDashboardPage({
    super.key,
    required this.username,
    required this.roles,
  });

  @override
  State<TutorDashboardPage> createState() => _TutorDashboardPageState();
}

class _TutorDashboardPageState extends State<TutorDashboardPage>
    with SingleTickerProviderStateMixin {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final contentController = TextEditingController();

  bool loading = false;
  Uint8List? _profileImageBytes;
  late AnimationController _fadeController;

  static const List<List<Color>> _gradients = [
    [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    [Color(0xFF10B981), Color(0xFF3B82F6)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    loadProfileImage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> loadProfileImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('profile_image')) {
        setState(() {
          _profileImageBytes = base64Decode(doc.data()!['profile_image']);
        });
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E2A45),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Stream<QuerySnapshot> getTutorCourses() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('courses')
        .where('tutorId', isEqualTo: uid)
        .where('isDeleted', isEqualTo: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getTutorSessions() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('kuppi_sessions')
        .where('tutorId', isEqualTo: uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('dateTime')
        .snapshots();
  }

  Future<void> deleteCourse(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _DarkConfirmDialog(
        icon: Icons.delete_outline_rounded,
        iconColor: const Color(0xFFEF4444),
        title: 'Delete Course?',
        message: 'This will permanently remove this course.',
        confirmLabel: 'Delete',
        confirmColor: const Color(0xFFEF4444),
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(id)
        .update({'isDeleted': true});
    if (!mounted) return;
    _showSnackBar('Course deleted');
  }

  Future<void> deleteSession(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _DarkConfirmDialog(
        icon: Icons.delete_outline_rounded,
        iconColor: const Color(0xFFEF4444),
        title: 'Delete Session?',
        message: 'This will permanently remove this session.',
        confirmLabel: 'Delete',
        confirmColor: const Color(0xFFEF4444),
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('kuppi_sessions')
        .doc(id)
        .update({'isDeleted': true});
    if (!mounted) return;
    _showSnackBar('Session deleted');
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> addCourse() async {
    if (titleController.text.isEmpty) return;
    try {
      setState(() => loading = true);
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('courses').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': double.tryParse(priceController.text) ?? 0,
        'content': contentController.text.trim(),
        'tutor': widget.username,
        'tutorId': user?.uid,
        'createdAt': Timestamp.now(),
        'isDeleted': false,
      });
      _clearCourseFields();
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Course created successfully');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
    setState(() => loading = false);
  }

  void _clearCourseFields() {
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    contentController.clear();
  }

  void showAddCourseDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF131929),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4, height: 18,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Create New Course',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _darkField(titleController, 'Course Title'),
                  const SizedBox(height: 12),
                  _darkField(descriptionController, 'Description'),
                  const SizedBox(height: 12),
                  _darkField(contentController, 'Course Content'),
                  const SizedBox(height: 12),
                  _darkField(priceController, 'Price',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 24),
                  Row(
                    children: [
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
                              child: Text('Cancel',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: loading ? null : addCourse,
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: loading
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text('Create',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
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
        ),
      ),
    );
  }

  Widget _darkField(TextEditingController controller, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13.5),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  String _formatDateTime(dynamic ts) {
    if (ts == null) return '—';
    final dt = (ts as Timestamp).toDate();
    return '${DateFormat('d MMM yyyy').format(dt)}  •  ${DateFormat('h:mm a').format(dt)}';
  }

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
              width: 260, height: 260,
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
            bottom: -100, left: -70,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          FadeTransition(
            opacity: _fadeController,
            child: SafeArea(
              child: Column(
                children: [
                  // ── Header ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        // Profile avatar
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: _profileImageBytes == null
                                ? const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.25),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _profileImageBytes != null
                                ? Image(
                                    image: MemoryImage(_profileImageBytes!),
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.person_rounded,
                                    color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tutor Dashboard',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                  )),
                              Text(widget.username,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12.5,
                                  )),
                            ],
                          ),
                        ),
                        // Notification
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Icon(Icons.notifications_outlined,
                                color: Colors.white.withOpacity(0.7), size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Settings
                        _SettingsMenu(
                          onEditProfile: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  EditProfilePage(username: widget.username),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 350),
                            ),
                          ).then((_) => loadProfileImage()),
                          onSwitchRole: () => Navigator.pushReplacement(
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

                  // ── Scrollable body ──────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── My Courses ─────────────────────
                          _SectionLabel(
                            label: 'My Courses',
                            gradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                          ),
                          const SizedBox(height: 14),

                          StreamBuilder<QuerySnapshot>(
                            stream: getTutorCourses(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF3B82F6), strokeWidth: 2.5),
                                );
                              }
                              final courses = snapshot.data!.docs;
                              if (courses.isEmpty) {
                                return _EmptyState(
                                    icon: Icons.book_outlined,
                                    label: 'No courses yet');
                              }
                              return Column(
                                children: courses.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final course = entry.value;
                                  final data =
                                      course.data() as Map<String, dynamic>;
                                  final gradient =
                                      _gradients[i % _gradients.length];
                                  return _CourseCard(
                                    data: data,
                                    gradient: gradient,
                                    index: i,
                                    fadeController: _fadeController,
                                    onDelete: () => deleteCourse(course.id),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ManageLessonsPage(
                                            courseId: course.id),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),

                          const SizedBox(height: 28),

                          // ── My Kuppi Sessions ──────────────
                          _SectionLabel(
                            label: 'My Kuppi Sessions',
                            gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          ),
                          const SizedBox(height: 14),

                          StreamBuilder<QuerySnapshot>(
                            stream: getTutorSessions(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF3B82F6), strokeWidth: 2.5),
                                );
                              }
                              final sessions = snapshot.data!.docs;
                              if (sessions.isEmpty) {
                                return _EmptyState(
                                    icon: Icons.video_camera_front_outlined,
                                    label: 'No sessions yet');
                              }
                              return Column(
                                children: sessions.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final doc = entry.value;
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final gradient =
                                      _gradients[i % _gradients.length];
                                  return _SessionCard(
                                    sessionId: doc.id,
                                    data: data,
                                    tutorName: widget.username,
                                    gradient: gradient,
                                    index: i,
                                    fadeController: _fadeController,
                                    formattedDateTime:
                                        _formatDateTime(data['dateTime']),
                                    onDelete: () => deleteSession(doc.id),
                                  );
                                }).toList(),
                              );
                            },
                          ),

                          const SizedBox(height: 28),

                          // ── Action buttons ─────────────────
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateKuppiSessionPage(
                                    tutorName: widget.username),
                              ),
                            ),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.video_call_rounded,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Create Kuppi Session',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          GestureDetector(
                            onTap: showAddCourseDialog,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6).withOpacity(0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded,
                                      color: const Color(0xFF3B82F6), size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Add New Course',
                                      style: TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
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
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  const _SectionLabel({required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 44, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Course card ───────────────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Color> gradient;
  final int index;
  final AnimationController fadeController;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _CourseCard({
    required this.data,
    required this.gradient,
    required this.index,
    required this.fadeController,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2 + index * 0.05),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: fadeController,
        curve: Interval(
          (index * 0.08).clamp(0.0, 0.6),
          (0.5 + index * 0.08).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      )),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.book_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2)),
                      if ((data['description'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(data['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12.5,
                                height: 1.4)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.touch_app_rounded,
                              size: 13, color: gradient[0]),
                          const SizedBox(width: 5),
                          Text('Tap to manage lessons',
                              style: TextStyle(
                                  color: gradient[0],
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.25)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444), size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Session card ──────────────────────────────────────────────────────────────
class _SessionCard extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> data;
  final String tutorName;
  final List<Color> gradient;
  final int index;
  final AnimationController fadeController;
  final String formattedDateTime;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.sessionId,
    required this.data,
    required this.tutorName,
    required this.gradient,
    required this.index,
    required this.fadeController,
    required this.formattedDateTime,
    required this.onDelete,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final hasLink = (d['zoomLink'] ?? '').isNotEmpty;
    final hasMaterials = (d['materials'] ?? '').isNotEmpty;
    final hasDesc = (d['description'] ?? '').isNotEmpty;
    final gradient = widget.gradient;

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2 + widget.index * 0.05),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: widget.fadeController,
        curve: Interval(
          (widget.index * 0.08).clamp(0.0, 0.6),
          (0.5 + widget.index * 0.08).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.video_camera_front_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['title'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2)),
                          if ((d['subject'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(d['subject'],
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 12.5)),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.event_rounded,
                                  size: 13, color: gradient[0]),
                              const SizedBox(width: 5),
                              Text(widget.formattedDateTime,
                                  style: TextStyle(
                                      color: gradient[0],
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: gradient[0].withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: gradient[0], size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded details ──────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(height: 1, color: Colors.white.withOpacity(0.06),
                      indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DarkDetailRow(
                            icon: Icons.topic_rounded,
                            label: 'Topic',
                            value: d['topic'] ?? '—',
                            color: gradient[0]),
                        _DarkDetailRow(
                            icon: Icons.event_rounded,
                            label: 'Date & Time',
                            value: widget.formattedDateTime,
                            color: gradient[0]),
                        if (hasLink)
                          _DarkDetailRow(
                              icon: Icons.link_rounded,
                              label: 'Meeting Link',
                              value: d['zoomLink'],
                              color: gradient[0]),
                        if (hasMaterials)
                          _DarkDetailRow(
                              icon: Icons.attach_file_rounded,
                              label: 'Materials',
                              value: d['materials'],
                              color: gradient[0]),
                        if (hasDesc)
                          _DarkDetailRow(
                              icon: Icons.notes_rounded,
                              label: 'Description',
                              value: d['description'],
                              color: gradient[0]),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateKuppiSessionPage(
                                      tutorName: widget.tutorName,
                                      sessionId: widget.sessionId,
                                      existingData: widget.data,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: gradient[0].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: gradient[0].withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          color: gradient[0], size: 17),
                                      const SizedBox(width: 6),
                                      Text('Edit',
                                          style: TextStyle(
                                              color: gradient[0],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: widget.onDelete,
                                child: Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFEF4444)
                                            .withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.delete_outline_rounded,
                                          color: Color(0xFFEF4444), size: 17),
                                      SizedBox(width: 6),
                                      Text('Delete',
                                          style: TextStyle(
                                              color: Color(0xFFEF4444),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dark detail row ───────────────────────────────────────────────────────────
class _DarkDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DarkDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

// ── Settings menu ─────────────────────────────────────────────────────────────
class _SettingsMenu extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onSwitchRole;
  final VoidCallback onLogout;

  const _SettingsMenu({
    required this.onEditProfile,
    required this.onSwitchRole,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF1A2235),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(Icons.settings_outlined,
            color: Colors.white.withOpacity(0.7), size: 20),
      ),
      onSelected: (value) {
        if (value == 'edit') onEditProfile();
        if (value == 'switch') onSwitchRole();
        if (value == 'logout') onLogout();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.person_outline_rounded,
                color: Colors.white.withOpacity(0.7), size: 18),
            const SizedBox(width: 10),
            Text('Edit Profile',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 14)),
          ]),
        ),
        PopupMenuItem(
          value: 'switch',
          child: Row(children: [
            Icon(Icons.swap_horiz_rounded,
                color: Colors.white.withOpacity(0.7), size: 18),
            const SizedBox(width: 10),
            Text('Switch Role',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 14)),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 10),
            Text('Logout',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
          ]),
        ),
      ],
    );
  }
}

// ── Dark confirm dialog ───────────────────────────────────────────────────────
class _DarkConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const _DarkConfirmDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131929),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13.5,
                    height: 1.4)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text('Cancel',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: confirmColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: confirmColor.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Text(confirmLabel,
                            style: TextStyle(
                                color: confirmColor,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}