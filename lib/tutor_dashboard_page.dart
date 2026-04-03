import 'package:flutter/material.dart';
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

class _TutorDashboardPageState extends State<TutorDashboardPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final contentController = TextEditingController();
  final sessionLinkController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool loading = false;

  /// ================= GET TUTOR COURSES =================
  Stream<QuerySnapshot> getTutorCourses() {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection("courses")
        .where("tutorId", isEqualTo: user?.uid)
        .where("isDeleted", isEqualTo: false)
        .snapshots();
  }

  /// ================= GET TUTOR SESSIONS =================
  Stream<QuerySnapshot> getTutorSessions() {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection("kuppi_sessions")
        .where("tutorId", isEqualTo: user?.uid)
        .where("isDeleted", isEqualTo: false)
        .orderBy("dateTime")
        .snapshots();
  }

  /// ================= DELETE COURSE =================
  Future<void> deleteCourse(String id) async {
    await FirebaseFirestore.instance
        .collection("courses")
        .doc(id)
        .update({"isDeleted": true});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Course deleted")),
    );
  }

  /// ================= DELETE SESSION =================
  Future<void> deleteSession(String id) async {
    await FirebaseFirestore.instance
        .collection("kuppi_sessions")
        .doc(id)
        .update({"isDeleted": true});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session deleted")),
    );
  }

  /// ================= LOGOUT =================
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pop(context);
  }

  /// ================= ADD COURSE =================
  Future<void> addCourse() async {
    if (titleController.text.isEmpty) return;

    try {
      setState(() => loading = true);

      final user = FirebaseAuth.instance.currentUser;

      DateTime? sessionDateTime;
      if (selectedDate != null && selectedTime != null) {
        sessionDateTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        );
      }

      await FirebaseFirestore.instance.collection("courses").add({
        "title": titleController.text.trim(),
        "description": descriptionController.text.trim(),
        "price": double.tryParse(priceController.text) ?? 0,
        "content": contentController.text.trim(),
        "tutor": widget.username,
        "tutorId": user?.uid,
        "sessionDate": sessionDateTime,
        "sessionLink": sessionLinkController.text.trim(),
        "createdAt": Timestamp.now(),
        "isDeleted": false,
      });

      clearFields();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Course created successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => loading = false);
  }

  void clearFields() {
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    contentController.clear();
    sessionLinkController.clear();
    selectedDate = null;
    selectedTime = null;
  }

  /// ================= ADD COURSE DIALOG =================
  void showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create New Course"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Course Title"),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: "Course Content"),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: loading ? null : addCourse,
            child: loading
                ? const CircularProgressIndicator()
                : const Text("Create"),
          ),
        ],
      ),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutor Dashboard"),
        backgroundColor: const Color(0xFF009639),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddCourseDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Welcome, ${widget.username}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            /// 🔥 MAIN CONTENT
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ================= COURSES =================
                    const Text(
                      "My Courses",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: getTutorCourses(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final courses = snapshot.data!.docs;

                        if (courses.isEmpty) {
                          return const Text("No courses yet");
                        }

                        return Column(
                          children: courses.map((course) {
                            final data = course.data() as Map<String, dynamic>;

                            return Card(
                              child: ListTile(
                                title: Text(data["title"] ?? ""),
                                subtitle: Text(data["description"] ?? ""),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ManageLessonsPage(
                                          courseId: course.id),
                                    ),
                                  );
                                },
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => deleteCourse(course.id),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    /// ================= KUPPI SESSIONS =================
                    const Text(
                      "My Kuppi Sessions",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: getTutorSessions(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final sessions = snapshot.data!.docs;

                        if (sessions.isEmpty) {
                          return const Text("No sessions yet");
                        }

                        return Column(
                          children: sessions.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            return Card(
                              child: ListTile(
                                title: Text(data["title"] ?? ""),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Subject: ${data["subject"] ?? ""}"),
                                    Text("Topic: ${data["topic"] ?? ""}"),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => deleteSession(doc.id),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            /// CREATE SESSION BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.video_call),
                label: const Text("Create Kuppi Session"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CreateKuppiSessionPage(tutorName: widget.username),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            /// LOGOUT
            ElevatedButton(
              onPressed: logout,
              child: const Text("Logout"),
            ),

            /// SWITCH ROLE
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChooseRolePage(
                      username: widget.username,
                      roles: widget.roles,
                    ),
                  ),
                );
              },
              child: const Text("Switch Role"),
            ),
          ],
        ),
      ),
    );
  }
}
