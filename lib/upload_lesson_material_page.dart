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

class _UploadLessonMaterialPageState extends State<UploadLessonMaterialPage>
    with SingleTickerProviderStateMixin {
  Uint8List? fileBytes;
  String? fileName;
  bool loading = false;

  late AnimationController _fadeController;

  static const List<List<Color>> _gradients = [
    [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    [Color(0xFF10B981), Color(0xFF3B82F6)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E2A45),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null) return;
    setState(() {
      fileBytes = result.files.first.bytes;
      fileName = result.files.first.name;
    });
  }

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
      request.files.add(http.MultipartFile.fromBytes(
        'file', fileBytes!, filename: fileName,
      ));

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
        _showSnackBar('Upload successful');
        setState(() {
          fileBytes = null;
          fileName = null;
        });
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Upload failed: $e');
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> deleteMaterial(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF131929),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(height: 16),
              const Text('Delete Material?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('This will permanently remove this file.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 13.5,
                      height: 1.4)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.4)),
                        ),
                        child: const Center(
                          child: Text('Delete',
                              style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection("courses")
        .doc(widget.courseId)
        .collection("lessons")
        .doc(widget.lessonId)
        .collection("materials")
        .doc(docId)
        .delete();

    if (!mounted) return;
    _showSnackBar('Material deleted');
  }

  Future<void> openFile(String fileUrl, String fileName) async {
    if (!mounted) return;
    if (fileName.toLowerCase().endsWith(".pdf")) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => _DarkPdfViewer(
              fileUrl: fileUrl, fileName: fileName),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        _showSnackBar('Cannot open file');
      }
    }
  }

  Future<void> downloadFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── File type helpers ─────────────────────────────────────────────────────
  IconData _fileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.doc') || lower.endsWith('.docx'))
      return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  List<Color> _fileGradient(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return [Color(0xFFEF4444), Color(0xFFF59E0B)];
    if (lower.endsWith('.doc') || lower.endsWith('.docx'))
      return [Color(0xFF3B82F6), Color(0xFF06B6D4)];
    return [Color(0xFF8B5CF6), Color(0xFFEC4899)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // ── Background blobs ──────────────────────────
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF3B82F6).withOpacity(0.13),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -70,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────
          FadeTransition(
            opacity: _fadeController,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white.withOpacity(0.8), size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lesson Materials',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                )),
                            Text('Upload & manage files',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12.5,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Upload card ──────────────────────
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131929),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.07)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4, height: 18,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('Upload File',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // File selected preview
                                if (fileName != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFF3B82F6)
                                              .withOpacity(0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(_fileIcon(fileName!),
                                            color: const Color(0xFF3B82F6),
                                            size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(fileName!,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w500)),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            fileBytes = null;
                                            fileName = null;
                                          }),
                                          child: Icon(Icons.close_rounded,
                                              color: Colors.white.withOpacity(0.4),
                                              size: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Select file button
                                GestureDetector(
                                  onTap: pickFile,
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.folder_open_rounded,
                                            color: const Color(0xFF3B82F6),
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          fileName == null
                                              ? 'Select File'
                                              : 'Change File',
                                          style: const TextStyle(
                                              color: Color(0xFF3B82F6),
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                if (fileName != null) ...[
                                  const SizedBox(height: 12),
                                  // Upload button
                                  GestureDetector(
                                    onTap: loading ? null : uploadFile,
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: loading
                                            ? null
                                            : const LinearGradient(
                                                colors: [
                                                  Color(0xFF3B82F6),
                                                  Color(0xFF06B6D4)
                                                ],
                                              ),
                                        color: loading
                                            ? Colors.white.withOpacity(0.06)
                                            : null,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: loading
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: const Color(0xFF3B82F6)
                                                      .withOpacity(0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                      ),
                                      child: Center(
                                        child: loading
                                            ? const SizedBox(
                                                width: 22, height: 22,
                                                child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  Icon(Icons.upload_rounded,
                                                      color: Colors.white,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Upload File',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Materials section label ──────────
                          Row(
                            children: [
                              Container(
                                width: 4, height: 18,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text('Uploaded Materials',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ── Materials list ───────────────────
                          StreamBuilder<QuerySnapshot>(
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
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF3B82F6),
                                      strokeWidth: 2.5),
                                );
                              }

                              final docs = snapshot.data!.docs;

                              if (docs.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Column(
                                      children: [
                                        Icon(Icons.cloud_upload_outlined,
                                            size: 52,
                                            color:
                                                Colors.white.withOpacity(0.15)),
                                        const SizedBox(height: 14),
                                        Text('No materials uploaded yet',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                itemBuilder: (_, index) {
                                  final doc = docs[index];
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final fileUrl = data["fileUrl"] as String;
                                  final fName =
                                      data["fileName"] as String? ?? '';
                                  final gradient = _fileGradient(fName);

                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: Offset(0, 0.2 + index * 0.05),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _fadeController,
                                      curve: Interval(
                                        (index * 0.08).clamp(0.0, 0.6),
                                        (0.5 + index * 0.08).clamp(0.0, 1.0),
                                        curve: Curves.easeOutCubic,
                                      ),
                                    )),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF131929),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.white
                                                .withOpacity(0.07)),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                gradient[0].withOpacity(0.08),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // File icon badge
                                            Container(
                                              width: 48, height: 48,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: gradient,
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(_fileIcon(fName),
                                                  color: Colors.white,
                                                  size: 24),
                                            ),
                                            const SizedBox(width: 14),

                                            // File name
                                            Expanded(
                                              child: Text(fName,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: -0.2,
                                                  )),
                                            ),

                                            const SizedBox(width: 8),

                                            // Open button
                                            GestureDetector(
                                              onTap: () =>
                                                  openFile(fileUrl, fName),
                                              child: Container(
                                                width: 36, height: 36,
                                                decoration: BoxDecoration(
                                                  color: gradient[0]
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: gradient[0]
                                                          .withOpacity(0.25)),
                                                ),
                                                child: Icon(
                                                    Icons.open_in_new_rounded,
                                                    color: gradient[0],
                                                    size: 17),
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Download button
                                            GestureDetector(
                                              onTap: () =>
                                                  downloadFile(fileUrl),
                                              child: Container(
                                                width: 36, height: 36,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: const Color(
                                                              0xFF10B981)
                                                          .withOpacity(0.25)),
                                                ),
                                                child: const Icon(
                                                    Icons.download_rounded,
                                                    color: Color(0xFF10B981),
                                                    size: 17),
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Delete button
                                            GestureDetector(
                                              onTap: () =>
                                                  deleteMaterial(doc.id),
                                              child: Container(
                                                width: 36, height: 36,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEF4444)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: const Color(
                                                              0xFFEF4444)
                                                          .withOpacity(0.25)),
                                                ),
                                                child: const Icon(
                                                    Icons.delete_outline_rounded,
                                                    color: Color(0xFFEF4444),
                                                    size: 17),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dark PDF Viewer ───────────────────────────────────────────────────────────
class _DarkPdfViewer extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const _DarkPdfViewer({required this.fileUrl, required this.fileName});

  @override
  State<_DarkPdfViewer> createState() => _DarkPdfViewerState();
}

class _DarkPdfViewerState extends State<_DarkPdfViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: FadeTransition(
        opacity: _fadeController,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white.withOpacity(0.8), size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(widget.fileName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
              ),

              // PDF viewer
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: FutureBuilder<http.Response>(
                    future: http.get(Uri.parse(widget.fileUrl)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF3B82F6), strokeWidth: 2.5),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(
                          child: Text('Failed to load PDF',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4))),
                        );
                      }
                      return SfPdfViewer.memory(snapshot.data!.bodyBytes);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}