import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class KuppiSessionsPage extends StatefulWidget {
  const KuppiSessionsPage({super.key});

  @override
  State<KuppiSessionsPage> createState() => _KuppiSessionsPageState();
}

class _KuppiSessionsPageState extends State<KuppiSessionsPage> {
  String searchText = '';

  Future<void> _openLink(String link) async {
    if (link.isEmpty) return;
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Returns "15 Aug 2025  •  10:30 AM"
  String _formatDateTime(dynamic ts) {
    if (ts == null) return '—';
    final dt = (ts as Timestamp).toDate();
    return '${DateFormat('d MMM yyyy').format(dt)}  •  ${DateFormat('h:mm a').format(dt)}';
  }

  /// True if the session is in the future (or within the last 30 min)
  bool _isUpcoming(dynamic ts) {
    if (ts == null) return false;
    final dt = (ts as Timestamp).toDate();
    return dt.isAfter(DateTime.now().subtract(const Duration(minutes: 30)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Kuppi Sessions'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF009639), Color(0xFF00C853)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title, subject, topic or tutor...',
                prefixIcon: const Icon(Icons.search),
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
              ),
              onChanged: (v) => setState(() => searchText = v.toLowerCase()),
            ),
          ),

          // Session list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('kuppi_sessions')
                  .where('isDeleted', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No Kuppi sessions available'));
                }

                // Filter by search text
                final filtered = snapshot.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return (d['title'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(searchText) ||
                      (d['subject'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(searchText) ||
                      (d['topic'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(searchText) ||
                      (d['tutorName'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(searchText);
                }).toList();

                // Sort upcoming first, then by dateTime
                filtered.sort((a, b) {
                  final tsA = (a.data() as Map)['dateTime'];
                  final tsB = (b.data() as Map)['dateTime'];
                  if (tsA == null || tsB == null) return 0;
                  return (tsA as Timestamp)
                      .toDate()
                      .compareTo((tsB as Timestamp).toDate());
                });

                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No sessions match your search'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final d = filtered[i].data() as Map<String, dynamic>;
                    final upcoming = _isUpcoming(d['dateTime']);
                    final hasDesc = (d['description'] ?? '').isNotEmpty;
                    final hasMats = (d['materials'] ?? '').isNotEmpty;
                    final zoomLink = d['zoomLink'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row with upcoming badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    d['title'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (upcoming)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: const Color(0xFF009639),
                                          width: 0.8),
                                    ),
                                    child: const Text(
                                      'Upcoming',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF009639),
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Subject & topic
                            if ((d['subject'] ?? '').isNotEmpty)
                              _InfoRow(
                                  icon: Icons.school_outlined,
                                  text:
                                      '${d['subject']}${(d['topic'] ?? '').isNotEmpty ? '  —  ${d['topic']}' : ''}'),

                            // Tutor
                            _InfoRow(
                                icon: Icons.person_outline,
                                text: d['tutorName'] ?? ''),

                            // Date AND time — the main addition
                            _InfoRow(
                              icon: Icons.event,
                              text: _formatDateTime(d['dateTime']),
                              bold: true,
                              color: const Color(0xFF009639),
                            ),

                            // Description (if any)
                            if (hasDesc) ...[
                              const SizedBox(height: 4),
                              _InfoRow(
                                  icon: Icons.notes,
                                  text: d['description'],
                                  maxLines: 2),
                            ],

                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon:
                                        const Icon(Icons.video_call, size: 18),
                                    label: const Text('Join session'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: upcoming
                                          ? const Color(0xFF009639)
                                          : Colors.grey.shade400,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _openLink(zoomLink),
                                  ),
                                ),
                                if (hasMats) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.attach_file,
                                          size: 18),
                                      label: const Text('Materials'),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Color(0xFF009639)),
                                        foregroundColor:
                                            const Color(0xFF009639),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      onPressed: () =>
                                          _openLink(d['materials']),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small info row helper ──────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;
  final Color? color;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.bold = false,
    this.color,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Colors.black87;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color ?? Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
