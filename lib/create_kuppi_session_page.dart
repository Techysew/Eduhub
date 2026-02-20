import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateKuppiSessionPage extends StatefulWidget {
  final String tutorName;

  const CreateKuppiSessionPage({super.key, required this.tutorName});

  @override
  State<CreateKuppiSessionPage> createState() => _CreateKuppiSessionPageState();
}

class _CreateKuppiSessionPageState extends State<CreateKuppiSessionPage> {
  final _formKey = GlobalKey<FormState>();

  final title = TextEditingController();
  final subject = TextEditingController();
  final topic = TextEditingController();
  final zoomLink = TextEditingController();
  final materials = TextEditingController();
  final description = TextEditingController();

  DateTime? selectedDate;

  Future<void> createSession() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) return;

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection("kuppi_sessions").add({
      "title": title.text.trim(),
      "subject": subject.text.trim(),
      "topic": topic.text.trim(),
      "zoomLink": zoomLink.text.trim(),
      "materials": materials.text.trim(),
      "description": description.text.trim(),
      "dateTime": selectedDate,
      "tutorId": user?.uid,
      "tutorName": widget.tutorName,
      "createdAt": Timestamp.now(),

      // ✅ SOFT DELETE FIELD
      "isDeleted": false,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Session Created")));

    Navigator.pop(context);
  }

  Future pickDate() async {
    final date = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime(2030),
        initialDate: DateTime.now());

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Kuppi Session")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: "Session Title")),
            TextFormField(
                controller: subject,
                decoration: const InputDecoration(labelText: "Subject")),
            TextFormField(
                controller: topic,
                decoration: const InputDecoration(labelText: "Topic")),
            TextFormField(
                controller: zoomLink,
                decoration: const InputDecoration(labelText: "Meeting Link")),
            TextFormField(
                controller: materials,
                decoration: const InputDecoration(
                    labelText: "Materials Link (optional)")),
            TextFormField(
                controller: description,
                decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 15),
            ElevatedButton(
                onPressed: pickDate,
                child: Text(selectedDate == null
                    ? "Pick Date"
                    : selectedDate.toString())),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: createSession, child: const Text("Create Session"))
          ]),
        ),
      ),
    );
  }
}
