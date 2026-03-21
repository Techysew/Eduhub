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

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  List<String> completedLessons = [];
  bool certificateShown = false;

  @override
  void initState() {
    super.initState();
    _loadCompletedLessons();
  }

  void _loadCompletedLessons() {
    final rawCompleted = widget.course["completedLessons"];

    if (rawCompleted is List) {
      completedLessons = rawCompleted.map((e) => e.toString()).toList();
    }
  }

  Future<void> toggleLesson(String lessonId, int totalLessons) async {
    setState(() {
      if (completedLessons.contains(lessonId)) {
        completedLessons.remove(lessonId);
      } else {
        completedLessons.add(lessonId);
      }
    });

    double progress =
        totalLessons == 0 ? 0 : completedLessons.length / totalLessons;

    await FirebaseFirestore.instance
        .collection("enrollments")
        .doc(widget.enrollmentId)
        .update({
      "completedLessons": completedLessons,
      "progress": progress,
    });

    if (progress >= 1.0 &&
        completedLessons.length == totalLessons &&
        !certificateShown) {
      certificateShown = true;
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text("🎉 Course Completed!"),
        content: const Text("Download your certificate."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CertificatePage(
                    courseName: widget.course["title"]?.toString() ?? "Course",
                  ),
                ),
              );
            },
            child: const Text("Get Certificate"),
          ),
        ],
      ),
    );
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
    final String title = widget.course["title"]?.toString() ?? "Course";
    final String tutor = widget.course["tutor"]?.toString() ?? "Tutor";

    /// ✅ SAFE courseId FIX
    final String courseId = widget.course["courseId"]?.toString() ??
        widget.course["id"]?.toString() ??
        "";

    /// ✅ SAFETY CHECK
    if (courseId.isEmpty) {
      debugPrint("❌ Missing courseId: ${widget.course}");
      return const Scaffold(
        body: Center(child: Text("Invalid course data")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Details"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Tutor: $tutor"),
            const SizedBox(height: 25),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("courses")
                    .doc(courseId)
                    .collection("lessons")
                    .orderBy("createdAt")
                    .snapshots(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final lessonDocs = snapshot.data!.docs;

                  if (lessonDocs.isEmpty) {
                    return const Center(child: Text("No lessons available"));
                  }

                  double progress = completedLessons.length / lessonDocs.length;

                  return Column(
                    children: [
                      const Text(
                        "Your Progress",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 10),
                      Text("${(progress * 100).toInt()}% completed"),
                      const SizedBox(height: 25),
                      Expanded(
                        child: ListView.builder(
                          itemCount: lessonDocs.length,
                          itemBuilder: (_, i) {
                            final data =
                                lessonDocs[i].data() as Map<String, dynamic>;

                            final lessonId = lessonDocs[i].id;
                            final lessonName =
                                data["name"]?.toString() ?? "Lesson";
                            final fileUrl = data["fileUrl"]?.toString();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    CheckboxListTile(
                                      title: Text(lessonName),
                                      value:
                                          completedLessons.contains(lessonId),
                                      onChanged: (_) => toggleLesson(
                                          lessonId, lessonDocs.length),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (fileUrl != null)
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.download),
                                            label: const Text("Open File"),
                                            onPressed: () => openFile(fileUrl),
                                          ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          child: const Text("Take Quiz"),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    FirestoreQuizPage(
                                                  courseId: courseId,
                                                  lessonName: lessonName,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
