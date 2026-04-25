import 'package:eduhub/upload_lesson_material_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ManageLessonsPage extends StatefulWidget {
  final String courseId;

  const ManageLessonsPage({
    super.key,
    required this.courseId,
  });

  @override
  State<ManageLessonsPage> createState() => _ManageLessonsPageState();
}

class _ManageLessonsPageState extends State<ManageLessonsPage> {
  final lessonController = TextEditingController();
  bool loading = false;

  /// ================= ADD LESSON =================
  Future<void> addLesson() async {
    final lessonName = lessonController.text.trim();
    if (lessonName.isEmpty) return;

    setState(() => loading = true);

    try {
      String? fileUrl;

      /// Ask user if they want to upload file
      if (await _confirmUpload()) {
        fileUrl = await uploadFile();
      }

      /// ✅ CREATE LESSON (NO fileUrl here)
      final lessonRef = await FirebaseFirestore.instance
          .collection("courses")
          .doc(widget.courseId)
          .collection("lessons")
          .add({
        "name": lessonName,
        "createdAt": Timestamp.now(),
      });

      /// ✅ ADD FILE TO MATERIALS SUBCOLLECTION
      if (fileUrl != null) {
        await lessonRef.collection("materials").add({
          "fileUrl": fileUrl,
          "fileName": lessonName,
          "createdAt": Timestamp.now(),
        });
      }

      lessonController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lesson added successfully")),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding lesson: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  /// ================= DELETE LESSON =================
  Future<void> deleteLesson(String id) async {
    await FirebaseFirestore.instance
        .collection("courses")
        .doc(widget.courseId)
        .collection("lessons")
        .doc(id)
        .delete();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Lesson deleted")));
  }

  /// ================= RENAME LESSON =================
  Future<void> renameLesson(String id, String currentName) async {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename Lesson"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection("courses")
                  .doc(widget.courseId)
                  .collection("lessons")
                  .doc(id)
                  .update({"name": newName});

              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  /// ================= UPLOAD FILE =================
  Future<String?> uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null) return null;

      final filePath = result.files.single.path;
      if (filePath == null) return null;

      final file = File(filePath);
      final fileName = result.files.single.name;

      final ref =
          FirebaseStorage.instance.ref("courses/${widget.courseId}/$fileName");

      await ref.putFile(file);

      return await ref.getDownloadURL();
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  /// ================= CONFIRM FILE UPLOAD =================
  Future<bool> _confirmUpload() async {
    bool upload = false;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Upload File?"),
        content: const Text(
            "Do you want to upload a PDF/Word file with this lesson?"),
        actions: [
          TextButton(
              onPressed: () {
                upload = false;
                Navigator.pop(context);
              },
              child: const Text("No")),
          ElevatedButton(
              onPressed: () {
                upload = true;
                Navigator.pop(context);
              },
              child: const Text("Yes")),
        ],
      ),
    );

    return upload;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Lessons")),
      body: Column(
        children: [
          /// ================= ADD LESSON UI =================
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: lessonController,
                    decoration:
                        const InputDecoration(hintText: "Enter lesson name..."),
                  ),
                ),
                loading
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: addLesson,
                      ),
              ],
            ),
          ),

          /// ================= LESSON LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("courses")
                  .doc(widget.courseId)
                  .collection("lessons")
                  .orderBy("createdAt")
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No lessons yet"));
                }

                return ListView(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(data["name"] ?? ""),

                      /// ✅ UPDATED TEXT (no fileUrl anymore)
                      subtitle: const Text("Tap to manage lesson materials"),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => renameLesson(doc.id, data["name"]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => deleteLesson(doc.id),
                          ),
                        ],
                      ),

                      /// 👉 OPEN MATERIAL PAGE
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UploadLessonMaterialPage(
                              courseId: widget.courseId,
                              lessonId: doc.id,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
