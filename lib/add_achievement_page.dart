import 'dart:io';
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

class _AddAchievementPageState extends State<AddAchievementPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  String selectedFaculty = "Computing";
  String selectedDepartment = "Software Engineering";
  String selectedPosition = "1st";

  // ✅ Changed from File? to Uint8List? — same as profile image
  Uint8List? selectedImageBytes;
  bool loading = false;

  final faculties = ["Engineering", "Science", "Computing", "Business"];
  final departments = [
    "Software Engineering",
    "Data Science",
    "Cyber Security",
    "Business Management"
  ];
  final positions = ["1st", "2nd", "3rd"];

  // ✅ Same as profile image — reads bytes, encodes to base64
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      selectedImageBytes = bytes;
    });
  }

  void showEditDialog(String docId, Map<String, dynamic> data) {
    final editTitle = TextEditingController(text: data["title"]);
    final editDesc = TextEditingController(text: data["description"]);
    String editFaculty = data["faculty"] ?? "Computing";
    String editDepartment = data["department"] ?? "Software Engineering";
    String editPosition = data["position"] ?? "1st";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Achievement"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: editTitle,
                  decoration: const InputDecoration(
                      labelText: "Title", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: editDesc,
                  decoration: const InputDecoration(
                      labelText: "Description", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: editFaculty,
                  items: faculties
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => editFaculty = val!),
                  decoration: const InputDecoration(
                      labelText: "Faculty", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: editDepartment,
                  items: departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => editDepartment = val!),
                  decoration: const InputDecoration(
                      labelText: "Department", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: editPosition,
                  items: positions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => editPosition = val!),
                  decoration: const InputDecoration(
                      labelText: "Position", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Achievement updated")),
                );
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
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

      // ✅ Same as profile image — encode bytes to base64 string
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
        "certificateBase64": certificateBase64, // ✅ base64 string, no Storage
        "createdAt": FieldValue.serverTimestamp(),
      });

      titleController.clear();
      descController.clear();
      setState(() => selectedImageBytes = null);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Saved Successfully")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  void deleteAchievement(String docId) {
    FirebaseFirestore.instance.collection("achievements").doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("My Achievements")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // -------- FORM --------
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                  labelText: "Title", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: descController,
              decoration: const InputDecoration(
                  labelText: "Description", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: selectedFaculty,
              items: faculties
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (val) => setState(() => selectedFaculty = val!),
              decoration: const InputDecoration(
                  labelText: "Faculty", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: selectedDepartment,
              items: departments
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) => setState(() => selectedDepartment = val!),
              decoration: const InputDecoration(
                  labelText: "Department", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: selectedPosition,
              items: positions
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) => setState(() => selectedPosition = val!),
              decoration: const InputDecoration(
                  labelText: "Position", border: OutlineInputBorder()),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.upload),
              label: const Text("Upload Certificate (Optional)"),
            ),

            // ✅ Same as profile image — display using MemoryImage
            if (selectedImageBytes != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Image(
                  image: MemoryImage(selectedImageBytes!),
                  height: 120,
                ),
              ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loading ? null : saveAchievement,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Save Achievement"),
            ),

            const Divider(height: 40),

            // -------- MY ACHIEVEMENTS --------
            const Text("My Achievements",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("achievements")
                  .where("studentId", isEqualTo: user?.uid)
                  // ✅ removed orderBy to avoid index error
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final docs = snapshot.data!.docs;

                // ✅ sort in Dart instead
                docs.sort((a, b) {
                  final aTime = a["createdAt"];
                  final bTime = b["createdAt"];
                  if (aTime == null || bTime == null) return 0;
                  return (bTime as dynamic).compareTo(aTime as dynamic);
                });

                if (docs.isEmpty) return const Text("No achievements yet");

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    // ✅ decode base64 to show thumbnail — same as profile image
                    Uint8List? certBytes;
                    final base64Str = data["certificateBase64"] ?? "";
                    if (base64Str.isNotEmpty) {
                      certBytes = base64Decode(base64Str);
                    }

                    return Card(
                      child: ListTile(
                        leading: certBytes != null
                            ? Image(
                                image: MemoryImage(certBytes),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.emoji_events),
                        title: Text(data["title"] ?? ""),
                        subtitle: Text(
                            "${data["faculty"]} - ${data["department"]}\n${data["position"]}"),
                        // ✅ edit + delete buttons
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  showEditDialog(docs[index].id, data), // ✅
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  deleteAchievement(docs[index].id),
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
    );
  }
}
