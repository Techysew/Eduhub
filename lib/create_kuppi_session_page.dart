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
  TimeOfDay? selectedTime;
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

    // Pre-fill date AND time when editing
    if (d?['dateTime'] is Timestamp) {
      final dt = (d!['dateTime'] as Timestamp).toDate();
      selectedDate = DateTime(dt.year, dt.month, dt.day);
      selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
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
    if (!_formKey.currentState!.validate() ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please fill all required fields, pick a date and a time'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Combine date + time into a single DateTime
      final combined = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final payload = {
        'title': title.text.trim(),
        'subject': subject.text.trim(),
        'topic': topic.text.trim(),
        'zoomLink': zoomLink.text.trim(),
        'materials': materials.text.trim(),
        'description': description.text.trim(),
        'dateTime': Timestamp.fromDate(combined),
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

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => selectedTime = time);
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

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

              // ── Date + Time pickers side by side ──
              Row(
                children: [
                  // Date picker
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        selectedDate == null
                            ? 'Pick date *'
                            : _formatDate(selectedDate!),
                        overflow: TextOverflow.ellipsis,
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
                  ),

                  const SizedBox(width: 12),

                  // Time picker
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        selectedTime == null
                            ? 'Pick time *'
                            : _formatTime(selectedTime!),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF009639)),
                        foregroundColor: const Color(0xFF009639),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),

              // Show combined summary once both are picked
              if (selectedDate != null && selectedTime != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFF009639), width: 0.6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF009639), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Session on ${_formatDate(selectedDate!)} at ${_formatTime(selectedTime!)}',
                        style: const TextStyle(
                          color: Color(0xFF009639),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
