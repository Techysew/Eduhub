import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'course_details_page.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot> getMyCourses() {
    return FirebaseFirestore.instance
        .collection("enrollments")
        .where("studentId", isEqualTo: uid)
        .snapshots();
  }

  void openCourse(String id, Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailsPage(
          enrollmentId: id,
          course: course,
        ),
      ),
    );
  }

  Future<void> removeCourse(String enrollmentId) async {
    await FirebaseFirestore.instance
        .collection("enrollments")
        .doc(enrollmentId)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Course removed")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Courses"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getMyCourses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!.docs;

          if (courses.isEmpty) {
            return const Center(
              child: Text("No enrolled courses"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final doc = courses[index];
              final data = doc.data() as Map<String, dynamic>;

              return buildCourseCard(data, doc.id);
            },
          );
        },
      ),
    );
  }

  Widget buildCourseCard(Map<String, dynamic> course, String enrollmentId) {
    final title = course["title"] ?? "Course";
    final tutor = course["tutor"] ?? "Tutor";
    final lessons = course["lessons"] ?? 0;

    /// ✅ CLAMP FIX (IMPORTANT)
    final progress = (course["progress"] ?? 0.0).toDouble().clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Tutor: $tutor"),
            Text("Lessons: $lessons"),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
            ),
            Text("${(progress * 100).toInt()}% completed"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => openCourse(enrollmentId, course),
                  child: const Text("Open"),
                ),
                TextButton(
                  onPressed: () => removeCourse(enrollmentId),
                  child: const Text("Remove"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
