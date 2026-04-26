import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'choose_role_page.dart';
import 'edit_profile_page.dart';

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

class _ClubDashboardPageState extends State<ClubDashboardPage>
    with SingleTickerProviderStateMixin {
  final programTitleController = TextEditingController();
  final programDescController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
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
    programTitleController.dispose();
    programDescController.dispose();
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

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> addProgram() async {
    final title = programTitleController.text.trim();
    final desc = programDescController.text.trim();

    if (title.isEmpty || selectedDate == null || selectedTime == null) {
      _showSnackBar('Please fill all fields');
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
      _showSnackBar('Program added successfully');
    } catch (e) {
      _showSnackBar('Error adding program: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> deleteProgram(String programId) async {
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
              const Text('Delete Program?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('This will permanently remove this program.',
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
        .collection("clubs")
        .doc(widget.username)
        .collection("programs")
        .doc(programId)
        .delete();

    if (!mounted) return;
    _showSnackBar('Program deleted');
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

  Widget _darkField(TextEditingController controller, String hint) {
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
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13.5),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}  •  $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
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
                        // Club avatar
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.groups_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Club Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Text(
                                widget.username,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification button
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Icon(Icons.notifications_outlined,
                                color: Colors.white.withOpacity(0.7),
                                size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Settings menu
                        _SettingsMenu(
                          username: widget.username,
                          roles: widget.roles,
                          onEditProfile: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  EditProfilePage(username: widget.username),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 350),
                            ),
                          ),
                          onSwitchRole: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChooseRolePage(
                                username: widget.username,
                                roles: widget.roles,
                              ),
                            ),
                          ),
                          onLogout: logout,
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
                          // ── Create Program card ──────────────
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
                                      'Create New Program',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                _darkField(
                                    programTitleController, 'Program Title'),
                                const SizedBox(height: 12),
                                _darkField(programDescController,
                                    'Program Description (optional)'),
                                const SizedBox(height: 12),

                                // Date & Time pickers
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: pickDate,
                                        child: Container(
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: Colors.white
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
                                                    ? 'Pick Date'
                                                    : _formatDate(
                                                        selectedDate!),
                                                style: TextStyle(
                                                  color: selectedDate != null
                                                      ? const Color(
                                                          0xFF3B82F6)
                                                      : Colors.white
                                                          .withOpacity(0.4),
                                                  fontSize: 13,
                                                  fontWeight: selectedDate !=
                                                          null
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
                                        onTap: pickTime,
                                        child: Container(
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: Colors.white
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
                                                  Icons
                                                      .access_time_rounded,
                                                  size: 16,
                                                  color: selectedTime != null
                                                      ? const Color(
                                                          0xFF3B82F6)
                                                      : Colors.white
                                                          .withOpacity(0.4)),
                                              const SizedBox(width: 7),
                                              Text(
                                                selectedTime == null
                                                    ? 'Pick Time'
                                                    : selectedTime!
                                                        .format(context),
                                                style: TextStyle(
                                                  color: selectedTime != null
                                                      ? const Color(
                                                          0xFF3B82F6)
                                                      : Colors.white
                                                          .withOpacity(0.4),
                                                  fontSize: 13,
                                                  fontWeight: selectedTime !=
                                                          null
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

                                const SizedBox(height: 16),

                                // Post button
                                GestureDetector(
                                  onTap: loading ? null : addProgram,
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
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              'Post Program',
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

                          // ── Programs section label ───────────
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
                                'Ongoing Programs',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ── Program list ─────────────────────
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("clubs")
                                .doc(widget.username)
                                .collection("programs")
                                .orderBy("dateTime")
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF3B82F6),
                                    strokeWidth: 2.5,
                                  ),
                                );
                              }

                              final docs = snapshot.data!.docs;

                              if (docs.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Column(
                                      children: [
                                        Icon(Icons.event_outlined,
                                            size: 48,
                                            color:
                                                Colors.white.withOpacity(0.15)),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No programs scheduled',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.3),
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
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final data = docs[index].data()
                                      as Map<String, dynamic>;
                                  final dateTime =
                                      (data["dateTime"] as Timestamp).toDate();
                                  final gradient =
                                      _gradients[index % _gradients.length];

                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin:
                                          Offset(0, 0.2 + index * 0.05),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _fadeController,
                                      curve: Interval(
                                        (index * 0.08).clamp(0.0, 0.6),
                                        (0.5 + index * 0.08)
                                            .clamp(0.0, 1.0),
                                        curve: Curves.easeOutCubic,
                                      ),
                                    )),
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 14),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Icon badge
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: gradient,
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: const Icon(
                                                  Icons.event_rounded,
                                                  color: Colors.white,
                                                  size: 24),
                                            ),
                                            const SizedBox(width: 14),

                                            // Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
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
                                                  if ((data["description"] ??
                                                          "")
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      data["description"],
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.4),
                                                        fontSize: 12.5,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          Icons.event_rounded,
                                                          size: 13,
                                                          color: gradient[0]),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        _formatDateTime(
                                                            dateTime),
                                                        style: TextStyle(
                                                          color: gradient[0],
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            // Delete button
                                            GestureDetector(
                                              onTap: () =>
                                                  deleteProgram(docs[index].id),
                                              child: Container(
                                                width: 36,
                                                height: 36,
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
                                                    Icons
                                                        .delete_outline_rounded,
                                                    color: Color(0xFFEF4444),
                                                    size: 18),
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

// ── Settings Menu ─────────────────────────────────────────────────────────────

class _SettingsMenu extends StatelessWidget {
  final String username;
  final List<String> roles;
  final VoidCallback onEditProfile;
  final VoidCallback onSwitchRole;
  final VoidCallback onLogout;

  const _SettingsMenu({
    required this.username,
    required this.roles,
    required this.onEditProfile,
    required this.onSwitchRole,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF1A2235),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child:
            Icon(Icons.settings_outlined, color: Colors.white.withOpacity(0.7), size: 20),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEditProfile();
            break;
          case 'switch':
            onSwitchRole();
            break;
          case 'logout':
            onLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  color: Colors.white.withOpacity(0.7), size: 18),
              const SizedBox(width: 10),
              Text('Edit Profile',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'switch',
          child: Row(
            children: [
              Icon(Icons.swap_horiz_rounded,
                  color: Colors.white.withOpacity(0.7), size: 18),
              const SizedBox(width: 10),
              Text('Switch Role',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded,
                  color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 10),
              const Text('Logout',
                  style: TextStyle(
                      color: Color(0xFFEF4444), fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}