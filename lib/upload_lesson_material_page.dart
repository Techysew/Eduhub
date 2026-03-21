import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
  Uint8List? fileBytes;
  String? fileName;
  bool loading = false;

  /// PICK FILE
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result == null) return;

    setState(() {
      fileBytes = result.files.first.bytes;
      fileName = result.files.first.name;
    });
  }

  /// UPLOAD FILE TO CLOUDINARY
  Future<void> uploadFile() async {
    if (fileBytes == null) return;

    if (!mounted) return;
    setState(() => loading = true);

    try {
      var uri =
          Uri.parse("https://api.cloudinary.com/v1_1/dv5kttcfh/raw/upload");

      var request = http.MultipartRequest("POST", uri);

      request.fields['upload_preset'] = "eduhub_upload";
      request.fields['resource_type'] = "raw";

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes!,
          filename: fileName,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String fileUrl = data["secure_url"];

        await FirebaseFirestore.instance
            .collection("courses")
            .doc(widget.courseId)
            .collection("lessons")
            .doc(widget.lessonId)
            .collection("materials")
            .add({
          "fileName": fileName,
          "fileUrl": fileUrl,
          "uploadedAt": Timestamp.now(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload successful")),
        );

        setState(() {
          fileBytes = null;
          fileName = null;
        });
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  /// DELETE MATERIAL
  Future<void> deleteMaterial(String docId) async {
    await FirebaseFirestore.instance
        .collection("courses")
        .doc(widget.courseId)
        .collection("lessons")
        .doc(widget.lessonId)
        .collection("materials")
        .doc(docId)
        .delete();
  }

  /// OPEN FILE
  Future<void> openFile(String fileUrl, String fileName) async {
    if (!mounted) return;

    if (fileName.toLowerCase().endsWith(".pdf")) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(fileName)),
            body: FutureBuilder<http.Response>(
              future: http.get(Uri.parse(fileUrl)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text("Failed to load PDF"));
                }

                final bytes = snapshot.data!.bodyBytes;
                return SfPdfViewer.memory(bytes);
              },
            ),
          ),
        ),
      );
    } else {
      final uri = Uri.parse(fileUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Cannot open file")));
      }
    }
  }

  /// DOWNLOAD FILE
  Future<void> downloadFile(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// FILE ICON
  Icon getFileIcon(String name) {
    if (name.toLowerCase().endsWith(".pdf")) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    }
    if (name.toLowerCase().endsWith(".doc") ||
        name.toLowerCase().endsWith(".docx")) {
      return const Icon(Icons.description, color: Colors.blue);
    }
    return const Icon(Icons.insert_drive_file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Material")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (fileName != null) Text("Selected: $fileName"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickFile,
              child: const Text("Select File"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : uploadFile,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Upload File"),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              "Uploaded Materials",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("courses")
                    .doc(widget.courseId)
                    .collection("lessons")
                    .doc(widget.lessonId)
                    .collection("materials")
                    .orderBy("uploadedAt", descending: true)
                    .snapshots(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                        child: Text("No materials uploaded yet."));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final fileUrl = data["fileUrl"];
                      final fileName = data["fileName"];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: getFileIcon(fileName),
                          title: Text(fileName),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => openFile(fileUrl, fileName),
                              ),
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () => downloadFile(fileUrl),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteMaterial(doc.id),
                              ),
                            ],
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
