import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage>
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

  Future<bool> alreadyEnrolled(String courseId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final result = await FirebaseFirestore.instance
        .collection("enrollments")
        .where("studentId", isEqualTo: uid)
        .where("courseId", isEqualTo: courseId)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<int> getLessonCount(String courseId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("courses")
        .doc(courseId)
        .collection("lessons")
        .get();
    return snapshot.docs.length;
  }

  Future<void> enrollCourse(BuildContext context, String courseId,
      Map<String, dynamic> course, int lessonCount) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final exists = await alreadyEnrolled(courseId);
    if (!context.mounted) return;

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Already enrolled in this course',
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF1E2A45),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("enrollments").add({
      "studentId": uid,
      "courseId": courseId,
      "title": course["title"],
      "tutor": course["tutor"],
      "lessonCount": lessonCount,
      "completedLessons": [],
      "progress": 0.0,
      "enrolledAt": Timestamp.now(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Enrolled successfully',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E2A45),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
                              'Courses',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Browse & enroll in courses',
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

                  const SizedBox(height: 20),

                  // ── Course list ──────────────────────
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("courses")
                          .where("isDeleted", isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3B82F6),
                              strokeWidth: 2.5,
                            ),
                          );
                        }

                        final courses = snapshot.data!.docs;

                        if (courses.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.book_outlined,
                                    size: 52,
                                    color: Colors.white.withOpacity(0.15)),
                                const SizedBox(height: 14),
                                Text(
                                  'No courses available',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: courses.length,
                          itemBuilder: (_, i) {
                            final doc = courses[i];
                            final data =
                                doc.data() as Map<String, dynamic>;
                            return FutureBuilder<int>(
                              future: getLessonCount(doc.id),
                              builder: (_, lessonSnapshot) {
                                final lessonCount =
                                    lessonSnapshot.data ?? 0;
                                return _CourseCard(
                                  data: data,
                                  index: i,
                                  lessonCount: lessonCount,
                                  slideController: _fadeController,
                                  onEnroll: () => enrollCourse(
                                      context, doc.id, data, lessonCount),
                                );
                              },
                            );
                          },
                        );
                      },
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

// ── Course Card ───────────────────────────────────────────────────────────────

class _CourseCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;
  final int lessonCount;
  final AnimationController slideController;
  final VoidCallback onEnroll;

  const _CourseCard({
    required this.data,
    required this.index,
    required this.lessonCount,
    required this.slideController,
    required this.onEnroll,
  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  static const List<List<Color>> _gradients = [
    [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    [Color(0xFF10B981), Color(0xFF3B82F6)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  ];

  @override
  Widget build(BuildContext context) {
    final title = widget.data["title"] ?? "Course";
    final tutor = widget.data["tutor"] ?? "Tutor";
    final gradient = _gradients[widget.index % _gradients.length];

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2 + widget.index * 0.05),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: widget.slideController,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon badge ───────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.book_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),

              // ── Info ─────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tutor,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Lessons chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: gradient[0].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.lessonCount} lessons',
                        style: TextStyle(
                          color: gradient[0],
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Enroll button ────────────────────
                    GestureDetector(
                      onTap: widget.onEnroll,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: gradient[0].withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Enroll',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }
}