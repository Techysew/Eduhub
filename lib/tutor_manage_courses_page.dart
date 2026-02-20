import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_lessons_page.dart';

class TutorManageCoursesPage extends StatefulWidget {
  final String tutorName;

  const TutorManageCoursesPage({super.key, required this.tutorName});

  @override
  State<TutorManageCoursesPage> createState() => _TutorManageCoursesPageState();
}

class _TutorManageCoursesPageState extends State<TutorManageCoursesPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  List<TextEditingController> lessonControllers = [];

  /// ADD LESSON FIELD
  void addLessonField() {
    setState(() => lessonControllers.add(TextEditingController()));
  }

  /// REMOVE LESSON FIELD
  void removeLessonField(int index) {
    setState(() => lessonControllers.removeAt(index));
  }

  /// ADD COURSE
  Future<void> addCourse() async {
    if (titleController.text.isEmpty) return;

    List<String> lessonList = lessonControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    await FirebaseFirestore.instance.collection("courses").add({
      "title": titleController.text.trim(),
      "description": descController.text.trim(),
      "lessons": lessonList,
      "tutor": widget.tutorName,
      "createdAt": Timestamp.now(),
      "isDeleted": false, // ✅ IMPORTANT
    });

    titleController.clear();
    descController.clear();
    lessonControllers.clear();
    setState(() {});
  }

  /// SOFT DELETE COURSE
  Future<void> deleteCourse(String id) async {
    await FirebaseFirestore.instance
        .collection("courses")
        .doc(id)
        .update({"isDeleted": true});
  }

  /// STREAM COURSES (HIDE DELETED)
  Stream<QuerySnapshot> getCourses() {
    return FirebaseFirestore.instance
        .collection("courses")
        .where("tutor", isEqualTo: widget.tutorName)
        .where("isDeleted", isEqualTo: false)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Courses"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// CREATE COURSE
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Course Title"),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Lessons",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: addLessonField,
                  child: const Text("Add Lesson"),
                ),
              ],
            ),

            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: lessonControllers.length,
                itemBuilder: (_, i) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: lessonControllers[i],
                          decoration:
                              InputDecoration(labelText: "Lesson ${i + 1}"),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => removeLessonField(i),
                      ),
                    ],
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: addCourse,
              child: const Text("Create Course"),
            ),

            const Divider(height: 30),

            /// EXISTING COURSES
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Your Courses",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getCourses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final courses = snapshot.data!.docs;

                  if (courses.isEmpty) {
                    return const Center(child: Text("No courses created yet."));
                  }

                  return ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (_, i) {
                      final doc = courses[i];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(data["title"] ?? "Untitled"),
                          subtitle: Text(data["description"] ?? ""),

                          /// OPEN LESSON MANAGER
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ManageLessonsPage(courseId: doc.id),
                              ),
                            );
                          },

                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => deleteCourse(doc.id),
                          ),
                        ),
                      );
                    },
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
