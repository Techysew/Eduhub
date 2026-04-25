import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class AddAchievementPage extends StatefulWidget {
  const AddAchievementPage({super.key});

  @override
  State<AddAchievementPage> createState() => _AddAchievementPageState();
}

class _AddAchievementPageState extends State<AddAchievementPage>
    with SingleTickerProviderStateMixin {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  String selectedFaculty = "Computing";
  String selectedDepartment = "Software Engineering";
  String selectedPosition = "1st";

  Uint8List? selectedImageBytes;
  bool loading = false;

  late AnimationController _fadeController;

  final faculties = ["Engineering", "Science", "Computing", "Business"];
  final departments = [
    "Software Engineering",
    "Data Science",
    "Cyber Security",
    "Business Management"
  ];
  final positions = ["1st", "2nd", "3rd"];

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
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => selectedImageBytes = bytes);
  }

  Future<void> saveAchievement() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || titleController.text.trim().isEmpty) return;

    setState(() => loading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      final userData = userDoc.data();

      String certificateBase64 = "";
      if (selectedImageBytes != null) {
        certificateBase64 = base64Encode(selectedImageBytes!);
      }

      await FirebaseFirestore.instance.collection("achievements").add({
        "studentId": user.uid,
        "studentName": userData?["username"] ?? "Unknown",
        "studentEmail": user.email,
        "faculty": selectedFaculty,
        "department": selectedDepartment,
        "position": selectedPosition,
        "title": titleController.text.trim(),
        "description": descController.text.trim(),
        "certificateBase64": certificateBase64,
        "createdAt": FieldValue.serverTimestamp(),
      });

      titleController.clear();
      descController.clear();
      setState(() => selectedImageBytes = null);

      if (!mounted) return;
      _showSnackBar('Achievement saved successfully');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e');
    }

    setState(() => loading = false);
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

  void deleteAchievement(String docId) async {
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(height: 16),
              const Text('Delete Achievement?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('This will permanently remove this achievement.',
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
    FirebaseFirestore.instance.collection("achievements").doc(docId).delete();
  }

  void showEditDialog(String docId, Map<String, dynamic> data) {
    final editTitle = TextEditingController(text: data["title"]);
    final editDesc = TextEditingController(text: data["description"]);
    String editFaculty = data["faculty"] ?? "Computing";
    String editDepartment = data["department"] ?? "Software Engineering";
    String editPosition = data["position"] ?? "1st";

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF131929),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit Achievement',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  _darkField(editTitle, 'Title'),
                  const SizedBox(height: 12),
                  _darkField(editDesc, 'Description'),
                  const SizedBox(height: 12),
                  _darkDropdown<String>(
                    label: 'Faculty',
                    value: editFaculty,
                    items: faculties,
                    onChanged: (v) =>
                        setDialogState(() => editFaculty = v!),
                  ),
                  const SizedBox(height: 12),
                  _darkDropdown<String>(
                    label: 'Department',
                    value: editDepartment,
                    items: departments,
                    onChanged: (v) =>
                        setDialogState(() => editDepartment = v!),
                  ),
                  const SizedBox(height: 12),
                  _darkDropdown<String>(
                    label: 'Position',
                    value: editPosition,
                    items: positions,
                    onChanged: (v) =>
                        setDialogState(() => editPosition = v!),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
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
                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection("achievements")
                                .doc(docId)
                                .update({
                              "title": editTitle.text.trim(),
                              "description": editDesc.text.trim(),
                              "faculty": editFaculty,
                              "department": editDepartment,
                              "position": editPosition,
                            });
                            if (!mounted) return;
                            Navigator.pop(context);
                            _showSnackBar('Achievement updated');
                          },
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF3B82F6),
                                  Color(0xFF06B6D4)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('Save',
                                  style: TextStyle(
                                      color: Colors.white,
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
        ),
      ),
    );
  }

  // ── Dark text field ───────────────────────────────────────────────────────
  Widget _darkField(TextEditingController controller, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Dark dropdown ─────────────────────────────────────────────────────────
  Widget _darkDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A2235),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          hint: Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 13)),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // ── Background blobs ──────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
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
            bottom: -100,
            left: -70,
            child: Container(
              width: 300,
              height: 300,
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
                children: [
                  // ── Header ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white.withOpacity(0.8),
                                size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Achievements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Add & manage your achievements',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12.5,
                              ),
                            ),
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
                          // ── Form card ──────────────────────────
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131929),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.07)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6)
                                      .withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section label
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF3B82F6),
                                            Color(0xFF06B6D4)
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'New Achievement',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                _darkField(titleController, 'Title'),
                                const SizedBox(height: 12),
                                _darkField(descController, 'Description'),
                                const SizedBox(height: 12),
                                _darkDropdown<String>(
                                  label: 'Faculty',
                                  value: selectedFaculty,
                                  items: faculties,
                                  onChanged: (v) =>
                                      setState(() => selectedFaculty = v!),
                                ),
                                const SizedBox(height: 12),
                                _darkDropdown<String>(
                                  label: 'Department',
                                  value: selectedDepartment,
                                  items: departments,
                                  onChanged: (v) =>
                                      setState(() => selectedDepartment = v!),
                                ),
                                const SizedBox(height: 12),
                                _darkDropdown<String>(
                                  label: 'Position',
                                  value: selectedPosition,
                                  items: positions,
                                  onChanged: (v) =>
                                      setState(() => selectedPosition = v!),
                                ),

                                const SizedBox(height: 16),

                                // Upload certificate button
                                GestureDetector(
                                  onTap: pickImage,
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withOpacity(0.05),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF3B82F6)
                                            .withOpacity(0.3),
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.upload_rounded,
                                            color: const Color(0xFF3B82F6),
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Upload Certificate (Optional)',
                                          style: TextStyle(
                                            color: const Color(0xFF3B82F6),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Image preview
                                if (selectedImageBytes != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image(
                                      image:
                                          MemoryImage(selectedImageBytes!),
                                      height: 130,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 18),

                                // Save button
                                GestureDetector(
                                  onTap: loading ? null : saveAchievement,
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: loading
                                          ? null
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFF3B82F6),
                                                Color(0xFF06B6D4),
                                              ],
                                            ),
                                      color: loading
                                          ? Colors.white.withOpacity(0.06)
                                          : null,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      boxShadow: loading
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: const Color(
                                                        0xFF3B82F6)
                                                    .withOpacity(0.3),
                                                blurRadius: 12,
                                                offset:
                                                    const Offset(0, 4),
                                              ),
                                            ],
                                    ),
                                    child: Center(
                                      child: loading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              'Save Achievement',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── My Achievements section label ──────
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFFEC4899)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'My Achievements',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ── Achievement list ───────────────────
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("achievements")
                                .where("studentId", isEqualTo: user?.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text("Error: ${snapshot.error}",
                                    style: TextStyle(
                                        color:
                                            Colors.white.withOpacity(0.4)));
                              }
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF3B82F6),
                                    strokeWidth: 2.5,
                                  ),
                                );
                              }

                              final docs = snapshot.data!.docs;
                              docs.sort((a, b) {
                                final aTime = a["createdAt"];
                                final bTime = b["createdAt"];
                                if (aTime == null || bTime == null)
                                  return 0;
                                return (bTime as dynamic)
                                    .compareTo(aTime as dynamic);
                              });

                              if (docs.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Column(
                                      children: [
                                        Icon(
                                            Icons
                                                .emoji_events_outlined,
                                            size: 48,
                                            color: Colors.white
                                                .withOpacity(0.15)),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No achievements yet',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.3),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final data = docs[index].data()
                                      as Map<String, dynamic>;
                                  final gradient = _gradients[
                                      index % _gradients.length];

                                  Uint8List? certBytes;
                                  final base64Str =
                                      data["certificateBase64"] ?? "";
                                  if (base64Str.isNotEmpty) {
                                    certBytes = base64Decode(base64Str);
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(
                                        bottom: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF131929),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white
                                              .withOpacity(0.07)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: gradient[0]
                                              .withOpacity(0.08),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Certificate thumbnail or icon
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    14),
                                            child: certBytes != null
                                                ? Image(
                                                    image: MemoryImage(
                                                        certBytes),
                                                    width: 52,
                                                    height: 52,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    width: 52,
                                                    height: 52,
                                                    decoration:
                                                        BoxDecoration(
                                                      gradient:
                                                          LinearGradient(
                                                        colors: gradient,
                                                        begin: Alignment
                                                            .topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  14),
                                                    ),
                                                    child: const Icon(
                                                        Icons
                                                            .emoji_events_rounded,
                                                        color:
                                                            Colors.white,
                                                        size: 26),
                                                  ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  data["title"] ?? "",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${data["faculty"]} · ${data["department"]}',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.45),
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                // Position chip
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: gradient[0]
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(20),
                                                  ),
                                                  child: Text(
                                                    '${data["position"]} Place',
                                                    style: TextStyle(
                                                      color: gradient[0],
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Edit + Delete buttons
                                          Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () => showEditDialog(
                                                    docs[index].id, data),
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                            0xFF3B82F6)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(10),
                                                    border: Border.all(
                                                        color: const Color(
                                                                0xFF3B82F6)
                                                            .withOpacity(
                                                                0.25)),
                                                  ),
                                                  child: const Icon(
                                                      Icons
                                                          .edit_outlined,
                                                      color:
                                                          Color(0xFF3B82F6),
                                                      size: 17),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              GestureDetector(
                                                onTap: () =>
                                                    deleteAchievement(
                                                        docs[index].id),
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                            0xFFEF4444)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(10),
                                                    border: Border.all(
                                                        color: const Color(
                                                                0xFFEF4444)
                                                            .withOpacity(
                                                                0.25)),
                                                  ),
                                                  child: const Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      color:
                                                          Color(0xFFEF4444),
                                                      size: 17),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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