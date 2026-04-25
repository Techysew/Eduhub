import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramsByClubsPage extends StatefulWidget {
  const ProgramsByClubsPage({super.key});

  @override
  State<ProgramsByClubsPage> createState() => _ProgramsByClubsPageState();
}

class _ProgramsByClubsPageState extends State<ProgramsByClubsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  final Set<int> _expandedIndexes = {};

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

  static const List<List<Color>> _gradients = [
    [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    [Color(0xFF10B981), Color(0xFF3B82F6)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  ];

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
                              'Programs by Clubs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Explore club programs',
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

                  // ── Club list ────────────────────────
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("clubs")
                          .snapshots(),
                      builder: (context, clubSnapshot) {
                        if (!clubSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3B82F6),
                              strokeWidth: 2.5,
                            ),
                          );
                        }

                        final clubs = clubSnapshot.data!.docs;

                        if (clubs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.groups_outlined,
                                    size: 52,
                                    color: Colors.white.withOpacity(0.15)),
                                const SizedBox(height: 14),
                                Text(
                                  'No clubs found',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: clubs.length,
                          itemBuilder: (context, index) {
                            final clubName = clubs[index].id;
                            final gradient =
                                _gradients[index % _gradients.length];
                            final isExpanded =
                                _expandedIndexes.contains(index);

                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(0, 0.2 + index * 0.05),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _fadeController,
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
                                  border: Border.all(
                                      color:
                                          Colors.white.withOpacity(0.07)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradient[0].withOpacity(0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // ── Club header row ──────────────
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        if (isExpanded) {
                                          _expandedIndexes.remove(index);
                                        } else {
                                          _expandedIndexes.add(index);
                                        }
                                      }),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // Icon badge
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: gradient,
                                                  begin:
                                                      Alignment.topLeft,
                                                  end: Alignment
                                                      .bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        14),
                                              ),
                                              child: const Icon(
                                                  Icons.groups_rounded,
                                                  color: Colors.white,
                                                  size: 24),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                clubName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ),
                                            // Expand chevron
                                            AnimatedRotation(
                                              turns: isExpanded ? 0.5 : 0,
                                              duration: const Duration(
                                                  milliseconds: 250),
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: gradient[0]
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10),
                                                ),
                                                child: Icon(
                                                    Icons
                                                        .keyboard_arrow_down_rounded,
                                                    color: gradient[0],
                                                    size: 20),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // ── Programs list ────────────────
                                    AnimatedCrossFade(
                                      duration: const Duration(
                                          milliseconds: 280),
                                      crossFadeState: isExpanded
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      firstChild: const SizedBox.shrink(),
                                      secondChild: Column(
                                        children: [
                                          Divider(
                                            height: 1,
                                            color: Colors.white
                                                .withOpacity(0.06),
                                            indent: 16,
                                            endIndent: 16,
                                          ),
                                          StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore
                                                .instance
                                                .collection("clubs")
                                                .doc(clubName)
                                                .collection("programs")
                                                .orderBy("dateTime")
                                                .snapshots(),
                                            builder: (context,
                                                programSnapshot) {
                                              if (!programSnapshot
                                                  .hasData) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets
                                                          .all(20),
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: gradient[0],
                                                    strokeWidth: 2,
                                                  ),
                                                );
                                              }

                                              final programs =
                                                  programSnapshot
                                                      .data!.docs;

                                              if (programs.isEmpty) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets
                                                          .fromLTRB(
                                                          16, 14, 16, 16),
                                                  child: Text(
                                                    'No programs yet',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(
                                                              0.3),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                );
                                              }

                                              return ListView.separated(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        16, 12, 16, 16),
                                                itemCount: programs.length,
                                                separatorBuilder: (_,
                                                        __) =>
                                                    Divider(
                                                        height: 20,
                                                        color: Colors.white
                                                            .withOpacity(
                                                                0.05)),
                                                itemBuilder: (_, i) {
                                                  final program =
                                                      programs[i].data()
                                                          as Map<String,
                                                              dynamic>;
                                                  final title =
                                                      program["title"] ??
                                                          "";
                                                  final desc =
                                                      program["description"] ??
                                                          "";
                                                  final dateTime =
                                                      (program["dateTime"]
                                                              as Timestamp)
                                                          .toDate();

                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        title,
                                                        style:
                                                            const TextStyle(
                                                          color:
                                                              Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w600,
                                                        ),
                                                      ),
                                                      if (desc
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          desc,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .white
                                                                .withOpacity(
                                                                    0.4),
                                                            fontSize: 12.5,
                                                            height: 1.4,
                                                          ),
                                                        ),
                                                      ],
                                                      const SizedBox(
                                                          height: 6),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .event_rounded,
                                                              size: 13,
                                                              color:
                                                                  gradient[
                                                                      0]),
                                                          const SizedBox(
                                                              width: 5),
                                                          Text(
                                                            _formatDateTime(
                                                                dateTime),
                                                            style:
                                                                TextStyle(
                                                              color:
                                                                  gradient[
                                                                      0],
                                                              fontSize:
                                                                  11.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
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
            ),
          ),
        ],
      ),
    );
  }
}