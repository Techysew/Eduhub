import 'dart:typed_data';
import 'dart:convert';

import 'package:eduhub/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'choose_role_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_kuppi_session_page.dart';
import 'manage_lessons_page.dart';

class TutorDashboardPage extends StatefulWidget {
  final String username;
  final List<String> roles;

  const TutorDashboardPage({
    super.key,
    required this.username,
    required this.roles,
  });

  @override
  State<TutorDashboardPage> createState() => _TutorDashboardPageState();
}

class _TutorDashboardPageState extends State<TutorDashboardPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final contentController = TextEditingController();

  bool loading = false;

  // ── Profile image ──────────────────────────────────────────
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    loadProfileImage();
  }

  Future<void> loadProfileImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('profile_image')) {
        setState(() {
          _profileImageBytes = base64Decode(doc.data()!['profile_image']);
        });
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  // ── Firestore streams ──────────────────────────────────────
  Stream<QuerySnapshot> getTutorCourses() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('courses')
        .where('tutorId', isEqualTo: uid)
        .where('isDeleted', isEqualTo: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getTutorSessions() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('kuppi_sessions')
        .where('tutorId', isEqualTo: uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('dateTime')
        .snapshots();
  }

  // ── Actions ────────────────────────────────────────────────
  Future<void> deleteCourse(String id) async {
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(id)
        .update({'isDeleted': true});
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Course deleted')));
  }

  Future<void> deleteSession(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('kuppi_sessions')
        .doc(id)
        .update({'isDeleted': true});
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Session deleted')));
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  // ── Add course ─────────────────────────────────────────────
  Future<void> addCourse() async {
    if (titleController.text.isEmpty) return;
    try {
      setState(() => loading = true);
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('courses').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': double.tryParse(priceController.text) ?? 0,
        'content': contentController.text.trim(),
        'tutor': widget.username,
        'tutorId': user?.uid,
        'createdAt': Timestamp.now(),
        'isDeleted': false,
      });
      _clearCourseFields();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => loading = false);
  }

  void _clearCourseFields() {
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    contentController.clear();
  }

  void showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create New Course'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Course Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Course Content'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: loading ? null : addCourse,
            child: loading
                ? const CircularProgressIndicator()
                : const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  String _formatDate(dynamic ts) {
    if (ts == null) return '—';
    final date = (ts as Timestamp).toDate();
    return DateFormat.yMMMd().format(date);
  }

  // ── UI ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
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
        title: const Text('Tutor Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
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
                  ).then((_) => loadProfileImage());
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Welcome header ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _profileImageBytes != null
                        ? MemoryImage(_profileImageBytes!)
                        : null,
                    child: _profileImageBytes == null
                        ? const Icon(Icons.person, size: 30, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Scrollable content ──────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── My Courses ────────────────────────
                    const Text(
                      'My Courses',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: getTutorCourses(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final courses = snapshot.data!.docs;
                        if (courses.isEmpty) {
                          return const Text('No courses yet');
                        }
                        return Column(
                          children: courses.map((course) {
                            final data = course.data() as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                title: Text(
                                  data['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(data['description'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => deleteCourse(course.id),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ManageLessonsPage(courseId: course.id),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    // ── My Kuppi Sessions ─────────────────
                    const Text(
                      'My Kuppi Sessions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: getTutorSessions(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final sessions = snapshot.data!.docs;
                        if (sessions.isEmpty) {
                          return const Text('No sessions yet');
                        }
                        return Column(
                          children: sessions.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return _SessionCard(
                              sessionId: doc.id,
                              data: data,
                              tutorName: widget.username,
                              formattedDate: _formatDate(data['dateTime']),
                              onDelete: () => deleteSession(doc.id),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Bottom action buttons ───────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.video_call),
                label: const Text('Create Kuppi Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009639),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateKuppiSessionPage(tutorName: widget.username),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add New Course'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF009639)),
                  foregroundColor: const Color(0xFF009639),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: showAddCourseDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session card widget ────────────────────────────────────────
class _SessionCard extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> data;
  final String tutorName;
  final String formattedDate;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.sessionId,
    required this.data,
    required this.tutorName,
    required this.formattedDate,
    required this.onDelete,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final hasLink = (d['zoomLink'] ?? '').isNotEmpty;
    final hasMaterials = (d['materials'] ?? '').isNotEmpty;
    final hasDesc = (d['description'] ?? '').isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Column(
        children: [
          // ── Header row (always visible) ──
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              d['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${d['subject'] ?? ''}  •  ${widget.formattedDate}',
              style: const TextStyle(fontSize: 13),
            ),
            trailing: IconButton(
              icon: Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),

          // ── Expanded detail section ──
          if (_expanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                      icon: Icons.topic,
                      label: 'Topic',
                      value: d['topic'] ?? '—'),
                  _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: widget.formattedDate),
                  if (hasLink)
                    _DetailRow(
                        icon: Icons.link,
                        label: 'Meeting link',
                        value: d['zoomLink']),
                  if (hasMaterials)
                    _DetailRow(
                        icon: Icons.attach_file,
                        label: 'Materials',
                        value: d['materials']),
                  if (hasDesc)
                    _DetailRow(
                        icon: Icons.notes,
                        label: 'Description',
                        value: d['description']),

                  const SizedBox(height: 12),

                  // ── Edit / Delete buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF009639)),
                            foregroundColor: const Color(0xFF009639),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateKuppiSessionPage(
                                tutorName: widget.tutorName,
                                sessionId: widget.sessionId,
                                existingData: widget.data,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: widget.onDelete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Small detail row ───────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF009639)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
