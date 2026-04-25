import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateKuppiSessionPage extends StatefulWidget {
  final String tutorName;
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

class _CreateKuppiSessionPageState extends State<CreateKuppiSessionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController title, subject, topic, zoomLink, materials, description;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _loading = false;
  late AnimationController _fadeController;

  bool get isEditMode => widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();

    final d = widget.existingData;
    title = TextEditingController(text: d?['title'] ?? '');
    subject = TextEditingController(text: d?['subject'] ?? '');
    topic = TextEditingController(text: d?['topic'] ?? '');
    zoomLink = TextEditingController(text: d?['zoomLink'] ?? '');
    materials = TextEditingController(text: d?['materials'] ?? '');
    description = TextEditingController(text: d?['description'] ?? '');

    if (d?['dateTime'] is Timestamp) {
      final dt = (d!['dateTime'] as Timestamp).toDate();
      selectedDate = DateTime(dt.year, dt.month, dt.day);
      selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
  }

  @override
  void dispose() {
    title.dispose(); subject.dispose(); topic.dispose();
    zoomLink.dispose(); materials.dispose(); description.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _loading = true);
    try {
      final combined = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);
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
        await FirebaseFirestore.instance.collection('kuppi_sessions').doc(widget.sessionId).update(payload);
      } else {
        await FirebaseFirestore.instance.collection('kuppi_sessions').add({
          ...payload,
          'tutorId': FirebaseAuth.instance.currentUser?.uid,
          'tutorName': widget.tutorName,
          'createdAt': Timestamp.now(),
          'isDeleted': false,
        });
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isEditMode ? 'Edit Session' : 'Create Session', style: const TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _Blob(color: const Color(0xFF009639))),
          Positioned(bottom: -50, left: -50, child: _Blob(color: const Color(0xFF3B82F6))),
          
          FadeTransition(
            opacity: _fadeController,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildField(title, 'Session Title', required: true),
                  _buildField(subject, 'Subject'),
                  _buildField(topic, 'Topic'),
                  _buildField(zoomLink, 'Meeting Link'),
                  _buildField(materials, 'Materials link'),
                  _buildField(description, 'Description', maxLines: 3),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPickerBtn(Icons.calendar_today, selectedDate == null ? 'Pick date *' : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}', _pickDate),
                      const SizedBox(width: 12),
                      _buildPickerBtn(Icons.access_time, selectedTime == null ? 'Pick time *' : selectedTime!.format(context), _pickTime),
                    ],
                  ),

                  if (selectedDate != null && selectedTime != null)
                    Container(
                      margin: const EdgeInsets.only(top: 15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF009639).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('Scheduled: ${selectedDate!.day}/${selectedDate!.month} at ${selectedTime!.format(context)}', 
                        style: const TextStyle(color: Color(0xFF009639), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 7, 38, 44),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading ? const CircularProgressIndicator(color: Color.fromARGB(255, 228, 231, 227)) : Text(isEditMode ? 'Save Changes' : 'Create Session'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerBtn(IconData icon, String label, VoidCallback onTap) => Expanded(
    child: OutlinedButton.icon(
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: onTap,
    ),
  );

  Widget _buildField(TextEditingController controller, String label, {bool required = false, int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: const Color(0xFF131929),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    ),
  );

  Future<void> _pickDate() async {
    final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030), initialDate: selectedDate ?? DateTime.now());
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
    if (time != null) setState(() => selectedTime = time);
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  const _Blob({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 200, height: 200,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withOpacity(0.15), Colors.transparent])),
  );
}