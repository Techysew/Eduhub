import 'package:eduhub/firestore_quiz_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduhub/certificate_page.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseDetailsPage extends StatefulWidget {
  final String enrollmentId;
  final Map<String, dynamic> course;

  const CourseDetailsPage({
    super.key,
    required this.enrollmentId,
    required this.course,
  });

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage>
    with SingleTickerProviderStateMixin {
  List<String> completedLessons = [];
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _loadCompletedLessons();
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

  void _loadCompletedLessons() {
    final rawCompleted = widget.course["completedLessons"];
    if (rawCompleted is List) {
      completedLessons = rawCompleted.map((e) => e.toString()).toSet().toList();
    }
  }

  Future<void> toggleLesson(String lessonId, String courseId) async {
    setState(() {
      if (completedLessons.contains(lessonId)) {
        completedLessons.remove(lessonId);
      } else {
        completedLessons.add(lessonId);
      }
      completedLessons = completedLessons.toSet().toList();
    });

    final lessonSnapshot = await FirebaseFirestore.instance
        .collection("courses")
        .doc(courseId)
        .collection("lessons")
        .get();

    final lessonIds = lessonSnapshot.docs.map((doc) => doc.id).toSet();
    final validCompleted =
        completedLessons.where((id) => lessonIds.contains(id)).toList();

    double progress =
        lessonIds.isEmpty ? 0 : validCompleted.length / lessonIds.length;

    await FirebaseFirestore.instance
        .collection("enrollments")
        .doc(widget.enrollmentId)
        .update({
      "completedLessons": validCompleted,
      "progress": progress,
    });
  }

  Future<void> openFile(String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) return;
    final uri = Uri.tryParse(fileUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot open file")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.course["title"] ?? "Course";
    final tutor = widget.course["tutor"] ?? "Tutor";
    final courseId = widget.course["courseId"] ?? widget.course["id"] ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // Background blobs
          Positioned(top: -80, right: -60, child: _Blob(color: const Color(0xFF3B82F6).withOpacity(0.13))),
          Positioned(bottom: -100, left: -70, child: _Blob(color: const Color(0xFF8B5CF6).withOpacity(0.1))),

          FadeTransition(
            opacity: _fadeController,
            child: SafeArea(
              child: Column(
                children: [
                  // Custom Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.08))),
                            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white.withOpacity(0.8), size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text('Course Details', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection("courses").doc(courseId).collection("lessons").orderBy("createdAt").snapshots(),
                      builder: (_, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));

                        final lessonDocs = snapshot.data!.docs;
                        final validCompleted = completedLessons.where((id) => lessonDocs.any((doc) => doc.id == id)).toList();
                        double progress = lessonDocs.isEmpty ? 0 : validCompleted.length / lessonDocs.length;

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            // Info Card
                            Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text("Tutor: $tutor", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                            const SizedBox(height: 24),

                            // Progress Card
                            _SectionContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Progress", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: Colors.white.withOpacity(0.07), valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6))),
                                ],
                              ),
                            ),

                            // Certificate Button
                            if (progress >= 1.0)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CertificatePage(courseName: title))),
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]), borderRadius: BorderRadius.circular(12)),
                                    child: const Center(child: Text("Download Certificate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Lessons List
                            ...lessonDocs.map((doc) {
                              final lessonId = doc.id;
                              final data = doc.data() as Map<String, dynamic>;
                              return _LessonCard(
                                title: data["name"] ?? "Lesson",
                                isCompleted: validCompleted.contains(lessonId),
                                onToggle: () => toggleLesson(lessonId, courseId),
                                lessonId: lessonId,
                                courseId: courseId,
                                openFile: openFile,
                              );
                            }).toList(),
                            const SizedBox(height: 40),
                          ],
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

// Helper Widgets to match your design
class _Blob extends StatelessWidget {
  final Color color;
  const _Blob({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])));
}

class _SectionContainer extends StatelessWidget {
  final Widget child;
  const _SectionContainer({required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF131929), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.07))), child: child);
}

class _LessonCard extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final VoidCallback onToggle;
  final String lessonId;
  final String courseId;
  final Function(String?) openFile;

  const _LessonCard({required this.title, required this.isCompleted, required this.onToggle, required this.lessonId, required this.courseId, required this.openFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF131929), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        leading: Checkbox(value: isCompleted, onChanged: (_) => onToggle(), activeColor: const Color(0xFF3B82F6)),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("courses").doc(courseId).collection("lessons").doc(lessonId).collection("materials").snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              return Column(
                children: snap.data!.docs.map((m) {
                  final data = m.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data["fileName"] ?? "Material", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    trailing: IconButton(icon: const Icon(Icons.download, color: Colors.white54, size: 20), onPressed: () => openFile(data["fileUrl"])),
                  );
                }).toList(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), elevation: 0),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FirestoreQuizPage(courseId: courseId, lessonName: title))),
                child: const Text("Take Quiz", style: TextStyle(color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }
}