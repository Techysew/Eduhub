import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateKuppiSessionPage extends StatefulWidget {
  final String tutorName;

  /// Pass these two to enable edit mode
  final String? sessionId;
  final Map<String, dynamic>? existingData;

  const CreateKuppiSessionPage({
    super.key,
    required this.tutorName,
    this.sessionId,
    this.existingData,
  });

  @override
  State<CreateKuppiSessionPage> createState() => _CreateKuppiSessionPageState();
}

class _CreateKuppiSessionPageState extends State<CreateKuppiSessionPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController title;
  late final TextEditingController subject;
  late final TextEditingController topic;
  late final TextEditingController zoomLink;
  late final TextEditingController materials;
  late final TextEditingController description;

  DateTime? selectedDate;
  bool _loading = false;

  bool get isEditMode => widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existingData;
    title = TextEditingController(text: d?['title'] ?? '');
    subject = TextEditingController(text: d?['subject'] ?? '');
    topic = TextEditingController(text: d?['topic'] ?? '');
    zoomLink = TextEditingController(text: d?['zoomLink'] ?? '');
    materials = TextEditingController(text: d?['materials'] ?? '');
    description = TextEditingController(text: d?['description'] ?? '');

    if (d?['dateTime'] is Timestamp) {
      selectedDate = (d!['dateTime'] as Timestamp).toDate();
    }
  }

  @override
  void dispose() {
    title.dispose();
    subject.dispose();
    topic.dispose();
    zoomLink.dispose();
    materials.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields and pick a date')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final payload = {
        'title': title.text.trim(),
        'subject': subject.text.trim(),
        'topic': topic.text.trim(),
        'zoomLink': zoomLink.text.trim(),
        'materials': materials.text.trim(),
        'description': description.text.trim(),
        'dateTime': Timestamp.fromDate(selectedDate!),
      };

      if (isEditMode) {
        await FirebaseFirestore.instance
            .collection('kuppi_sessions')
            .doc(widget.sessionId)
            .update(payload);
      } else {
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection('kuppi_sessions').add({
          ...payload,
          'tutorId': user?.uid,
          'tutorName': widget.tutorName,
          'createdAt': Timestamp.now(),
          'isDeleted': false,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(isEditMode ? 'Session updated!' : 'Session created!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: selectedDate ?? DateTime.now(),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Kuppi Session' : 'Create Kuppi Session'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF009639), Color(0xFF00C853)],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField(title, 'Session Title', required: true),
              _buildField(subject, 'Subject'),
              _buildField(topic, 'Topic'),
              _buildField(zoomLink, 'Meeting Link (Zoom / Meet)'),
              _buildField(materials, 'Materials link (optional)'),
              _buildField(description, 'Description', maxLines: 3),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  selectedDate == null
                      ? 'Pick a date *'
                      : 'Date: ${_formatDate(selectedDate!)}',
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF009639)),
                  foregroundColor: const Color(0xFF009639),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _pickDate,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009639),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditMode ? 'Save Changes' : 'Create Session',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF009639)),
          ),
        ),
        validator: required
            ? (v) => (v == null || v.isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}
