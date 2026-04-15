import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for sign out
import 'choose_role_page.dart';
import 'edit_profile_page.dart'; // Ensure this exists

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

  /// ================= LOGOUT =================
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

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

      await FirebaseFirestore.instance
          .collection("clubs")
          .doc(widget.username)
          .set({
        "name": widget.username,
        "createdAt": Timestamp.now(),
      }, SetOptions(merge: true));

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

      programTitleController.clear();
      programDescController.clear();
      setState(() {
        selectedDate = null;
        selectedTime = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Program added successfully")),
      );
    } catch (e) {
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

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Program deleted")),
    );
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => selectedTime = time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      /// ================= APP BAR =================
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF009639), Color(0xFF00C853)],
            ),
          ),
        ),
        title: const Text("Club Dashboard"),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),

          /// SETTINGS POPUP MENU
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditProfilePage(username: widget.username),
                    ),
                  );
                  break;
                case 'switch':
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChooseRolePage(
                        username: widget.username,
                        roles: widget.roles,
                      ),
                    ),
                  );
                  break;
                case 'logout':
                  logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Edit Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'switch',
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Switch Role'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),

      /// ================= BODY =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ===== HEADER CARD =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF009639),
                    child: Icon(Icons.groups, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    "Welcome, ${widget.username}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// ===== ADD PROGRAM CARD =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create New Program",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: programTitleController,
                    decoration: InputDecoration(
                      hintText: "Program Title",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: programDescController,
                    decoration: InputDecoration(
                      hintText: "Program Description",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickDate,
                          icon: const Icon(Icons.date_range, size: 18),
                          label: Text(selectedDate == null
                              ? "Date"
                              : "${selectedDate!.day}/${selectedDate!.month}"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickTime,
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(selectedTime == null
                              ? "Time"
                              : selectedTime!.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : addProgram,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009639),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Post Program"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// ===== PROGRAM LIST =====
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ongoing Programs",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text("No programs scheduled"),
                  );

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final dateTime = (data["dateTime"] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(Icons.event, color: Color(0xFF009639)),
                        ),
                        title: Text(data["title"] ?? "",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "${data["description"]}\nDate: ${dateTime.day}/${dateTime.month}/${dateTime.year}"),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => deleteProgram(docs[index].id),
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
