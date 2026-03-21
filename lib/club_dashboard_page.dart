import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'choose_role_page.dart';

class ClubDashboardPage extends StatefulWidget {
  final String username;
  final List<String> roles;

  const ClubDashboardPage({
    super.key,
    required this.username,
    required this.roles,
  });

  @override
  State<ClubDashboardPage> createState() => _ClubDashboardPageState();
}

class _ClubDashboardPageState extends State<ClubDashboardPage> {
  final programTitleController = TextEditingController();
  final programDescController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool loading = false;

  /// ================= ADD PROGRAM =================
  Future<void> addProgram() async {
    final title = programTitleController.text.trim();
    final desc = programDescController.text.trim();

    if (title.isEmpty || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final programDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // ✅ STEP 1: Ensure the club document exists
      await FirebaseFirestore.instance
          .collection("clubs")
          .doc(widget.username)
          .set({
        "name": widget.username,
        "createdAt": Timestamp.now(),
      }, SetOptions(merge: true));

      // ✅ STEP 2: Add program
      await FirebaseFirestore.instance
          .collection("clubs")
          .doc(widget.username)
          .collection("programs")
          .add({
        "title": title,
        "description": desc,
        "dateTime": programDateTime,
        "createdAt": Timestamp.now(),
      });

      // ✅ Clear inputs
      programTitleController.clear();
      programDescController.clear();
      selectedDate = null;
      selectedTime = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Program added successfully")),
      );
    } catch (e) {
      print("Add program error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding program: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  /// ================= DELETE PROGRAM =================
  Future<void> deleteProgram(String programId) async {
    await FirebaseFirestore.instance
        .collection("clubs")
        .doc(widget.username)
        .collection("programs")
        .doc(programId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Program deleted")),
    );
  }

  /// ================= PICK DATE =================
  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) setState(() => selectedDate = date);
  }

  /// ================= PICK TIME =================
  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) setState(() => selectedTime = time);
  }

  /// ================= LOGOUT =================
  void logout() => Navigator.pop(context);

  /// ================= SWITCH ROLE =================
  void switchRole() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChooseRolePage(username: widget.username, roles: widget.roles),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Club Dashboard"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, ${widget.username}!",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              /// ===== ACTION BUTTONS =====
              Row(
                children: [
                  ElevatedButton(
                    onPressed: logout,
                    child: const Text("Logout"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: switchRole,
                    child: const Text("Switch Role"),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// ===== ADD PROGRAM =====
              const Text(
                "Add New Program",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: programTitleController,
                decoration: const InputDecoration(
                  hintText: "Program Title",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: programDescController,
                decoration: const InputDecoration(
                  hintText: "Program Description",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  ElevatedButton(
                    onPressed: pickDate,
                    child: Text(selectedDate == null
                        ? "Select Date"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: pickTime,
                    child: Text(selectedTime == null
                        ? "Select Time"
                        : "${selectedTime!.hour}:${selectedTime!.minute}"),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: addProgram,
                      child: const Text("Add Program"),
                    ),

              const SizedBox(height: 30),

              /// ===== PROGRAM LIST =====
              const Text(
                "Your Programs",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("clubs")
                    .doc(widget.username)
                    .collection("programs")
                    .orderBy("dateTime")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text("No programs yet");
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final dateTime = (data["dateTime"] as Timestamp).toDate();

                      return Card(
                        child: ListTile(
                          title: Text(data["title"] ?? ""),
                          subtitle: Text(
                            "${data["description"]}\n"
                            "${dateTime.day}/${dateTime.month}/${dateTime.year} "
                            "${dateTime.hour}:${dateTime.minute}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteProgram(doc.id),
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
    );
  }
}
