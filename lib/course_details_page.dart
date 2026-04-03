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

  @override
  void initState() {
    super.initState();
    _loadCompletedLessons();
  }

  /// ✅ LOAD COMPLETED LESSONS
  void _loadCompletedLessons() {
    final rawCompleted = widget.course["completedLessons"];

    if (rawCompleted is List) {
      completedLessons = rawCompleted.map((e) => e.toString()).toSet().toList();
    }
  }

  /// ✅ TOGGLE LESSON + FIX PROGRESS
  Future<void> toggleLesson(String lessonId, String courseId) async {
    setState(() {
      if (completedLessons.contains(lessonId)) {
        completedLessons.remove(lessonId);
      } else {
        completedLessons.add(lessonId);
      }

      completedLessons = completedLessons.toSet().toList();
    });

    /// 🔥 GET LESSONS FROM FIRESTORE
    final lessonSnapshot = await FirebaseFirestore.instance
        .collection("courses")
        .doc(courseId)
        .collection("lessons")
        .get();

    final lessonIds = lessonSnapshot.docs.map((doc) => doc.id).toSet();

    /// 🔥 FILTER VALID LESSONS ONLY
    final validCompleted =
        completedLessons.where((id) => lessonIds.contains(id)).toList();

    /// 🔥 CALCULATE PROGRESS
    double progress =
        lessonIds.isEmpty ? 0 : validCompleted.length / lessonIds.length;

    /// 🔥 UPDATE FIRESTORE
    await FirebaseFirestore.instance
        .collection("enrollments")
        .doc(widget.enrollmentId)
        .update({
      "completedLessons": validCompleted,
      "progress": progress,
    });
  }

  /// ✅ OPEN FILE
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

    if (courseId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Invalid course")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Details"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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

            /// ✅ FILTER VALID COMPLETED
            final validCompleted = completedLessons
                .where((id) => lessonDocs.any((doc) => doc.id == id))
                .toList();

            double progress = lessonDocs.isEmpty
                ? 0
                : validCompleted.length / lessonDocs.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),
                Text("Tutor: $tutor"),

                const SizedBox(height: 20),

                /// PROGRESS
                const Text(
                  "Your Progress",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 10,
                ),

                const SizedBox(height: 5),

                Text("${(progress * 100).toInt()}% completed"),

                const SizedBox(height: 15),

                /// 🎓 CERTIFICATE BUTTON
                if (progress == 1.0)
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.workspace_premium),
                      label: const Text("Download Certificate"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CertificatePage(
                              courseName: widget.course["title"] ?? "Course",
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                /// LESSON LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: lessonDocs.length,
                    itemBuilder: (_, i) {
                      final lessonId = lessonDocs[i].id;
                      final data = lessonDocs[i].data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          title: Text(data["name"] ?? "Lesson"),
                          leading: Checkbox(
                            value: validCompleted.contains(lessonId),
                            onChanged: (_) => toggleLesson(lessonId, courseId),
                          ),
                          children: [
                            /// 📂 MATERIALS
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("courses")
                                  .doc(courseId)
                                  .collection("lessons")
                                  .doc(lessonId)
                                  .collection("materials")
                                  .snapshots(),
                              builder: (_, materialSnap) {
                                if (!materialSnap.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }

                                final materials = materialSnap.data!.docs;

                                if (materials.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text("No materials uploaded"),
                                  );
                                }

                                return Column(
                                  children: materials.map((mat) {
                                    final data =
                                        mat.data() as Map<String, dynamic>;

                                    final fileUrl = data["fileUrl"];

                                    return ListTile(
                                      leading:
                                          const Icon(Icons.insert_drive_file),
                                      title: Text(data["fileName"] ?? "File"),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () => openFile(fileUrl),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            /// 🧠 QUIZ
                            ElevatedButton(
                              child: const Text("Take Quiz"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FirestoreQuizPage(
                                      courseId: courseId,
                                      lessonName: data["name"] ?? "",
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 10),
                          ],
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
    );
  }
}
