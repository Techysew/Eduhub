import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class UploadLessonMaterialPage extends StatefulWidget {
  final String courseId;
  final String lessonId;

  const UploadLessonMaterialPage({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  @override
  State<UploadLessonMaterialPage> createState() =>
      _UploadLessonMaterialPageState();
}

class _UploadLessonMaterialPageState extends State<UploadLessonMaterialPage> {
  bool loading = false;

  Future<void> uploadFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) return;

    setState(() => loading = true);

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;

    final ref = FirebaseStorage.instance
        .ref("courses/${widget.courseId}/${widget.lessonId}/$fileName");

    await ref.putFile(file);

    final url = await ref.getDownloadURL();

    /// SAVE FILE URL TO LESSON
    await FirebaseFirestore.instance
        .collection("courses")
        .doc(widget.courseId)
        .collection("lessons")
        .doc(widget.lessonId)
        .update({
      "fileUrl": url,
    });

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("File uploaded successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Material")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: uploadFile,
                child: const Text("Upload PDF / Word File"),
              ),
      ),
    );
  }
}
