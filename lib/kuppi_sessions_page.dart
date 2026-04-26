import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class KuppiSessionsPage extends StatefulWidget {
  const KuppiSessionsPage({super.key});

  @override
  State<KuppiSessionsPage> createState() => _KuppiSessionsPageState();
}

class _KuppiSessionsPageState extends State<KuppiSessionsPage>
    with SingleTickerProviderStateMixin {
  String searchText = '';
  late AnimationController _fadeController;

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
    super.dispose();
  }

  Future<void> _openLink(String link) async {
    if (link.isEmpty) return;
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDateTime(dynamic ts) {
    if (ts == null) return '—';
    final dt = (ts as Timestamp).toDate();
    return '${DateFormat('d MMM yyyy').format(dt)}  •  ${DateFormat('h:mm a').format(dt)}';
  }

  bool _isUpcoming(dynamic ts) {
    if (ts == null) return false;
    final dt = (ts as Timestamp).toDate();
    return dt.isAfter(DateTime.now().subtract(const Duration(minutes: 30)));
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

          // ── Content ───────────────────────────────────
          FadeTransition(
            opacity: _fadeController,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
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
                            const Text(
                              'Kuppi Sessions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Live & upcoming sessions',
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

                  const SizedBox(height: 16),

                  // ── Search bar ───────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF131929),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.07)),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search by title, subject, topic or tutor...',
                          hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3), fontSize: 13.5),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.white.withOpacity(0.3), size: 20),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (v) =>
                            setState(() => searchText = v.toLowerCase()),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Session list ──────────────────────
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('kuppi_sessions')
                          .where('isDeleted', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3B82F6),
                              strokeWidth: 2.5,
                            ),
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_camera_front_outlined,
                                    size: 52,
                                    color: Colors.white.withOpacity(0.15)),
                                const SizedBox(height: 14),
                                Text(
                                  'No Kuppi sessions available',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

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

                        filtered.sort((a, b) {
                          final tsA = (a.data() as Map)['dateTime'];
                          final tsB = (b.data() as Map)['dateTime'];
                          if (tsA == null || tsB == null) return 0;
                          return (tsA as Timestamp)
                              .toDate()
                              .compareTo((tsB as Timestamp).toDate());
                        });

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              'No sessions match your search',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 15,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final doc = filtered[i];
                            final d =
                                doc.data() as Map<String, dynamic>;
                            final upcoming = _isUpcoming(d['dateTime']);
                            return _SessionCard(
                              data: d,
                              index: i,
                              upcoming: upcoming,
                              slideController: _fadeController,
                              onJoin: () =>
                                  _openLink(d['zoomLink'] ?? ''),
                              onMaterials: (d['materials'] ?? '')
                                      .isNotEmpty
                                  ? () => _openLink(d['materials'])
                                  : null,
                              formatDateTime: _formatDateTime,
                            );
                          },
                        );
                      },
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

// ── Session Card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;
  final bool upcoming;
  final AnimationController slideController;
  final VoidCallback onJoin;
  final VoidCallback? onMaterials;
  final String Function(dynamic) formatDateTime;

  static const List<List<Color>> _gradients = [
    [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    [Color(0xFF10B981), Color(0xFF3B82F6)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  ];

  const _SessionCard({
    required this.data,
    required this.index,
    required this.upcoming,
    required this.slideController,
    required this.onJoin,
    required this.onMaterials,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[index % _gradients.length];
    final title = data['title'] ?? '';
    final subject = data['subject'] ?? '';
    final topic = data['topic'] ?? '';
    final tutorName = data['tutorName'] ?? '';
    final description = data['description'] ?? '';
    final hasDesc = description.isNotEmpty;
    final subjectLine =
        subject.isNotEmpty ? '$subject${topic.isNotEmpty ? '  —  $topic' : ''}' : '';

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2 + index * 0.05),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: slideController,
        curve: Interval(
          (index * 0.08).clamp(0.0, 0.6),
          (0.5 + index * 0.08).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top section ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.video_camera_front_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (upcoming) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.4)),
                                ),
                                child: const Text(
                                  'Upcoming',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (tutorName.isNotEmpty)
                          Text(
                            tutorName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 12.5,
                            ),
                          ),
                        const SizedBox(height: 6),
                        // Subject chip
                        if (subjectLine.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: gradient[0].withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              subjectLine,
                              style: TextStyle(
                                color: gradient[0],
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Date/time row ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.event_rounded,
                      size: 14, color: gradient[0]),
                  const SizedBox(width: 6),
                  Text(
                    formatDateTime(data['dateTime']),
                    style: TextStyle(
                      color: gradient[0],
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ── Description (if any) ─────────────────────
            if (hasDesc) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Divider ──────────────────────────────────
            Divider(
                height: 1,
                color: Colors.white.withOpacity(0.06),
                indent: 16,
                endIndent: 16),

            // ── Action buttons ───────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Join button
                  Expanded(
                    child: GestureDetector(
                      onTap: onJoin,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: upcoming
                              ? LinearGradient(colors: gradient)
                              : null,
                          color: upcoming
                              ? null
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: upcoming
                              ? [
                                  BoxShadow(
                                    color: gradient[0].withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_call_rounded,
                                color: upcoming
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.35),
                                size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Join Session',
                              style: TextStyle(
                                color: upcoming
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.35),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Materials button (if available)
                  if (onMaterials != null) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onMaterials,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: gradient[0].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: gradient[0].withOpacity(0.25)),
                        ),
                        child: Icon(Icons.attach_file_rounded,
                            color: gradient[0], size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}