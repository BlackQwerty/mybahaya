import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  static const Color nudeColor = Color(0xFFACA494);
  static const Color pinkColor = Colors.white;
  static const Color burgundyColor = Color(0xFFB22222);

  // Maps category to an icon
  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fire':       return Icons.local_fire_department_rounded;
      case 'theft':      return Icons.no_encryption_rounded;
      case 'assault':    return Icons.personal_injury_rounded;
      case 'medical':    return Icons.medical_services_rounded;
      default:           return Icons.warning_amber_rounded;
    }
  }

  // Maps category to a colour badge
  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fire':    return const Color(0xFFFF6B35);
      case 'theft':   return const Color(0xFF9B59B6);
      case 'assault': return const Color(0xFFE74C3C);
      case 'medical': return const Color(0xFF2ECC71);
      default:        return burgundyColor;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '—';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else {
      return '—';
    }
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final hour   = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4D0A18),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFACA494),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Report List ─────────────────────────────────────────
          Expanded(
            child: uid == null
                ? _buildEmpty('You are not logged in.')
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reports')
                        .where('userId', isEqualTo: uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: burgundyColor,
                            strokeWidth: 2,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildEmpty(
                          'Could not load reports.\n${snapshot.error}',
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return _buildEmpty(
                          'You have not submitted any reports yet.',
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          // Show LATEST badge only on the first item
                          return _ReportCard(
                            data: data,
                            isLatest: index == 0,
                            categoryIcon: _categoryIcon(
                              data['category'] as String? ?? '',
                            ),
                            categoryColor: _categoryColor(
                              data['category'] as String? ?? '',
                            ),
                            formattedDate: _formatDate(data['createdAt']),
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

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 56,
            color: nudeColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: nudeColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual Report Card ───────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLatest;
  final IconData categoryIcon;
  final Color categoryColor;
  final String formattedDate;

  static const Color nudeColor    = Color(0xFFACA494);
  static const Color pinkColor = Colors.white;
  static const Color burgundyColor = Color(0xFFB22222);

  const _ReportCard({
    required this.data,
    required this.isLatest,
    required this.categoryIcon,
    required this.categoryColor,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final category = data['category'] as String? ?? 'Unknown';
    final details  = data['details']  as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final location = data['location'] as Map<String, dynamic>?;
    final lat      = location?['latitude']  as double?;
    final lng      = location?['longitude'] as double?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF422E2E).withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 160,
                  color: Colors.white.withOpacity(0.05),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: burgundyColor,
                      strokeWidth: 1.5,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.white.withOpacity(0.05),
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: nudeColor.withOpacity(0.3),
                    size: 40,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Category badge + Latest tag ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: categoryColor.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, color: categoryColor, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: categoryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: burgundyColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: burgundyColor.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: burgundyColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'LATEST',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: burgundyColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // ── Details ──
                if (details.isNotEmpty) ...[
                  Text(
                    details,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Location coordinates ──
                if (lat != null && lng != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: pinkColor.withOpacity(0.7),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: nudeColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                // ── Timestamp ──
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: nudeColor.withOpacity(0.5),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: nudeColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
