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

  late final TextEditingController title;
  late final TextEditingController subject;
  late final TextEditingController topic;
  late final TextEditingController zoomLink;
  late final TextEditingController materials;
  late final TextEditingController description;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _loading = false;

  late AnimationController _fadeController;

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
      final dt = (d!['dateTime'] as Timestamp).toDate();
      selectedDate = DateTime(dt.year, dt.month, dt.day);
      selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    title.dispose();
    subject.dispose();
    topic.dispose();
    zoomLink.dispose();
    materials.dispose();
    description.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        selectedDate == null ||
        selectedTime == null) {
      _showSnackBar('Please fill all required fields, pick a date and a time');
      return;
    }

    setState(() => _loading = true);

    try {
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
      _showSnackBar(isEditMode ? 'Session updated!' : 'Session created!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e');
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
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF3B82F6),
            surface: Color(0xFF131929),
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF3B82F6),
            surface: Color(0xFF131929),
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => selectedTime = time);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // ── Dark text field ───────────────────────────────────────────────────────
  Widget _darkField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.35), fontSize: 13),
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.white.withOpacity(0.3), size: 20)
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 14 : 16,
            ),
          ),
          validator: required
              ? (v) => (v == null || v.isEmpty) ? 'Required' : null
              : null,
        ),
      ),
    );
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
                                color: Colors.white.withOpacity(0.8),
                                size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditMode
                                  ? 'Edit Kuppi Session'
                                  : 'Create Kuppi Session',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              isEditMode
                                  ? 'Update session details'
                                  : 'Schedule a new live session',
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

                  // ── Form ────────────────────────────
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Session details card ─────────────
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
                                        width: 4, height: 18,
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
                                      const Text('Session Details',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  _darkField(title, 'Session Title',
                                      required: true,
                                      icon: Icons.video_camera_front_rounded),
                                  _darkField(subject, 'Subject',
                                      icon: Icons.school_rounded),
                                  _darkField(topic, 'Topic',
                                      icon: Icons.topic_rounded),
                                  _darkField(zoomLink,
                                      'Meeting Link (Zoom / Meet)',
                                      icon: Icons.link_rounded),
                                  _darkField(materials,
                                      'Materials link (optional)',
                                      icon: Icons.attach_file_rounded),
                                  _darkField(description, 'Description',
                                      maxLines: 3,
                                      icon: Icons.notes_rounded),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Date & Time card ─────────────────
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131929),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.07)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6)
                                        .withOpacity(0.08),
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
                                            colors: [
                                              Color(0xFF8B5CF6),
                                              Color(0xFFEC4899)
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text('Date & Time',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Picker buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _pickDate,
                                          child: Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: selectedDate != null
                                                  ? const Color(0xFF3B82F6)
                                                      .withOpacity(0.12)
                                                  : Colors.white
                                                      .withOpacity(0.05),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: selectedDate != null
                                                    ? const Color(0xFF3B82F6)
                                                        .withOpacity(0.4)
                                                    : Colors.white
                                                        .withOpacity(0.08),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                    Icons
                                                        .calendar_today_rounded,
                                                    size: 16,
                                                    color: selectedDate != null
                                                        ? const Color(
                                                            0xFF3B82F6)
                                                        : Colors.white
                                                            .withOpacity(0.4)),
                                                const SizedBox(width: 7),
                                                Text(
                                                  selectedDate == null
                                                      ? 'Pick Date *'
                                                      : _formatDate(
                                                          selectedDate!),
                                                  style: TextStyle(
                                                    color: selectedDate != null
                                                        ? const Color(
                                                            0xFF3B82F6)
                                                        : Colors.white
                                                            .withOpacity(0.4),
                                                    fontSize: 13,
                                                    fontWeight:
                                                        selectedDate != null
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _pickTime,
                                          child: Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: selectedTime != null
                                                  ? const Color(0xFF3B82F6)
                                                      .withOpacity(0.12)
                                                  : Colors.white
                                                      .withOpacity(0.05),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: selectedTime != null
                                                    ? const Color(0xFF3B82F6)
                                                        .withOpacity(0.4)
                                                    : Colors.white
                                                        .withOpacity(0.08),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                    Icons.access_time_rounded,
                                                    size: 16,
                                                    color: selectedTime != null
                                                        ? const Color(
                                                            0xFF3B82F6)
                                                        : Colors.white
                                                            .withOpacity(0.4)),
                                                const SizedBox(width: 7),
                                                Text(
                                                  selectedTime == null
                                                      ? 'Pick Time *'
                                                      : _formatTime(
                                                          selectedTime!),
                                                  style: TextStyle(
                                                    color: selectedTime != null
                                                        ? const Color(
                                                            0xFF3B82F6)
                                                        : Colors.white
                                                            .withOpacity(0.4),
                                                    fontSize: 13,
                                                    fontWeight:
                                                        selectedTime != null
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Combined summary
                                  if (selectedDate != null &&
                                      selectedTime != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFF10B981)
                                                .withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF10B981),
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Session on ${_formatDate(selectedDate!)} at ${_formatTime(selectedTime!)}',
                                              style: const TextStyle(
                                                color: Color(0xFF10B981),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Submit button ────────────────────
                            GestureDetector(
                              onTap: _loading ? null : _submit,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: _loading
                                      ? null
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF3B82F6),
                                            Color(0xFF06B6D4),
                                          ],
                                        ),
                                  color: _loading
                                      ? Colors.white.withOpacity(0.06)
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: _loading
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: const Color(0xFF3B82F6)
                                                .withOpacity(0.3),
                                            blurRadius: 14,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                ),
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22, height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5),
                                        )
                                      : Text(
                                          isEditMode
                                              ? 'Save Changes'
                                              : 'Create Session',
                                          style: const TextStyle(
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