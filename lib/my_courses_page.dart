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

  /// ================= GET ENROLLED COURSES =================
  Stream<QuerySnapshot> getMyCourses() {
    return FirebaseFirestore.instance
        .collection("enrollments")
        .where("studentId", isEqualTo: uid)
        .snapshots();
  }

  /// ================= OPEN COURSE (LATER CONNECT) =================
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

  /// ================= UNENROLL COURSE =================
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No enrolled courses yet",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final courses = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final doc = courses[index];
              final data = doc.data() as Map<String, dynamic>;

              final courseId = data["courseId"];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("courses")
                    .doc(courseId)
                    .get(),
                builder: (context, courseSnap) {
                  if (!courseSnap.hasData) return const SizedBox();

                  // course deleted or not exists → hide
                  if (!courseSnap.data!.exists ||
                      (courseSnap.data!.data()
                              as Map<String, dynamic>)["isDeleted"] ==
                          true) {
                    return const SizedBox();
                  }

                  return buildCourseCard(data, doc.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// ================= COURSE CARD =================
  Widget buildCourseCard(Map<String, dynamic> course, String enrollmentId) {
    final title = course["title"] ?? "Course";
    final tutor = course["tutor"] ?? "Tutor";
    final lessons = course["lessons"] ?? 0;
    final progress = (course["progress"] ?? 0.0).toDouble();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// COURSE TITLE
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            /// TUTOR
            Text("Tutor: $tutor"),

            const SizedBox(height: 5),

            /// LESSON COUNT
            Text("Lessons: $lessons"),

            const SizedBox(height: 12),

            /// PROGRESS BAR
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),

            const SizedBox(height: 8),

            Text("${(progress * 100).toInt()}% completed"),

            const SizedBox(height: 12),

            /// ACTION BUTTONS
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
            ),
          ],
        ),
      ),
    );
  }
}
