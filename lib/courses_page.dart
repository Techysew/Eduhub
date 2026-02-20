import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  /// ===== CHECK IF ALREADY ENROLLED =====
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

  /// ===== GET LESSON COUNT FROM SUBCOLLECTION =====
  Future<int> getLessonCount(String courseId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("courses")
        .doc(courseId)
        .collection("lessons")
        .get();

    return snapshot.docs.length;
  }

  /// ===== ENROLL COURSE =====
  Future<void> enrollCourse(BuildContext context, String courseId,
      Map<String, dynamic> course, int lessonCount) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final exists = await alreadyEnrolled(courseId);

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already enrolled in this course")),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enrolled successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Courses"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("courses")
            .where("isDeleted", isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!.docs;

          if (courses.isEmpty) {
            return const Center(child: Text("No courses available"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (_, i) {
              final doc = courses[i];
              final data = doc.data() as Map<String, dynamic>;

              return FutureBuilder<int>(
                future: getLessonCount(doc.id),
                builder: (_, lessonSnapshot) {
                  final lessonCount = lessonSnapshot.data ?? 0;

                  return Card(
                    child: ListTile(
                      title: Text(data["title"] ?? ""),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Tutor: ${data["tutor"] ?? ""}"),
                          Text("Lessons: $lessonCount"),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () =>
                            enrollCourse(context, doc.id, data, lessonCount),
                        child: const Text("Enroll"),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
