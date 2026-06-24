import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_header.dart';
import '../map/incident_map_screen.dart';

class LiveAlertsScreen extends StatefulWidget {
  const LiveAlertsScreen({super.key});

  @override
  State<LiveAlertsScreen> createState() => _LiveAlertsScreenState();
}

class _LiveAlertsScreenState extends State<LiveAlertsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  Position? _userPosition;
  String _filter = 'All';

  static const Color burgundy = Color(0xFFB22222);
  static const Color nude     = Color(0xFFACA494);
  static const Color pink = Colors.white;
  static const Color maroon   = Color(0xFF341515);

  static const _filters = ['All', 'Fire', 'Theft', 'Assault', 'Medical', 'Other'];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.10)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _initLocation();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      bool svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open dialler. Call $number manually.')),
        );
      }
    }
  }

  Color _catColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'fire':    return const Color(0xFFFF6B35);
      case 'theft':   return const Color(0xFF9B59B6);
      case 'assault': return const Color(0xFFE74C3C);
      case 'medical': return const Color(0xFF2ECC71);
      default:        return burgundy;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'fire':    return CupertinoIcons.flame_fill;
      case 'theft':   return CupertinoIcons.lock_open_fill;
      case 'assault': return CupertinoIcons.exclamationmark_circle_fill;
      case 'medical': return CupertinoIcons.plus_circle_fill;
      default:        return CupertinoIcons.exclamationmark_triangle_fill;
    }
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String _formatDistance(double? km) {
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m away';
    return '${km.toStringAsFixed(1)}km away';
  }

  String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    final date = createdAt is Timestamp ? createdAt.toDate() : null;
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody: true,
      appBar: const MyBahayaAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(title: 'Alerts'),
            const SizedBox(height: 24),
            _buildSOSHub(),
            const SizedBox(height: 28),
            _buildFeedSection(),
          ],
        ),
      ),
    );
  }

  // ── SOS Emergency Hub ────────────────────────────────────────────────────
  Widget _buildSOSHub() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: nude,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFCC0000).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCC0000).withOpacity(0.45)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 6, height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFCC0000),
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'EMERGENCY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFCC0000),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Malaysia 24/7',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: maroon.withOpacity(0.55),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Pulsing SOS button
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: GestureDetector(
                onTap: () => _callNumber('999'),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFCC0000),
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCC0000).withOpacity(0.55),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.phone_fill, color: Colors.white, size: 44),
                      Text(
                        '999',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Tap to call 999 immediately',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: maroon.withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 20),

          // Three quick-dial tiles
          Row(
            children: [
              _dialTile('112', 'Talian Kecemasan Mobile',
                  CupertinoIcons.exclamationmark_circle_fill, const Color(0xFFDC2626)),
              const SizedBox(width: 8),
              _dialTile('994', 'Bomba & Penyelamat',
                  CupertinoIcons.flame_fill, const Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              _dialTile('991', 'Kecemasan Perubatan',
                  CupertinoIcons.plus_circle_fill, const Color(0xFF2ECC71)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dialTile(String number, String label, IconData icon, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _callNumber(number),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.55)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 5),
              Text(
                number,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: maroon,
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: maroon.withOpacity(0.65),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Live Incidents Feed ──────────────────────────────────────────────────
  Widget _buildFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Text(
              'Live Incidents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(
                            (_pulseAnim.value - 1.0) * 6 + 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Filter pills
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _filters[i];
              final active = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: active ? nude : Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? maroon : Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Firestore stream — community alerts read the sanitized public feed.
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('public_incidents')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeleton();
            }
            if (snapshot.hasError) {
              return _buildEmpty('Could not load alerts. Check your connection.');
            }

            var docs = snapshot.data?.docs ?? [];

            // Apply category filter
            if (_filter != 'All') {
              docs = docs
                  .where((d) =>
                      ((d.data() as Map)['category'] as String? ?? '')
                          .toLowerCase() ==
                      _filter.toLowerCase())
                  .toList();
            }

            if (docs.isEmpty) {
              return _buildEmpty(
                _filter == 'All'
                    ? 'No incidents reported yet.'
                    : 'No $_filter incidents reported.',
              );
            }

            // Sort by distance if location available
            if (_userPosition != null) {
              docs.sort((a, b) {
                final da = _docDistance(a.data() as Map<String, dynamic>);
                final db = _docDistance(b.data() as Map<String, dynamic>);
                return da.compareTo(db);
              });
            }

            return Column(
              children: docs
                  .map((d) => _buildAlertCard(
                      d.data() as Map<String, dynamic>))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  double _docDistance(Map<String, dynamic> data) {
    if (_userPosition == null) return double.infinity;
    final loc = data['location'] as Map<String, dynamic>?;
    if (loc == null) return double.infinity;
    final lat = (loc['latitude']  as num?)?.toDouble();
    final lng = (loc['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return double.infinity;
    return _distanceKm(
        _userPosition!.latitude, _userPosition!.longitude, lat, lng);
  }

  // Palette-faithful verification chip (maroon / white only).
  Widget _verificationChip(String? status) {
    if (status == 'VERIFIED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: maroon,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.white, size: 10),
          SizedBox(width: 3),
          Text('VERIFIED', style: TextStyle(
              fontSize: 8, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: 0.3)),
        ]),
      );
    }
    if (status == 'REJECTED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: maroon.withOpacity(0.55)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(CupertinoIcons.xmark_seal_fill, color: maroon, size: 10),
          SizedBox(width: 3),
          Text('FALSE ALARM', style: TextStyle(
              fontSize: 8, fontWeight: FontWeight.w800,
              color: maroon, letterSpacing: 0.3)),
        ]),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAlertCard(Map<String, dynamic> data) {
    final category           = data['category'] as String? ?? 'Other';
    final details            = data['details']  as String? ?? '';
    final verificationStatus = data['verificationStatus'] as String?;
    final catColor = _catColor(category);
    final catIcon  = _catIcon(category);
    final dist     = _userPosition != null ? _docDistance(data) : null;
    final timeAgo  = _timeAgo(data['createdAt']);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentMapScreen(report: data),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: nude,
          borderRadius: BorderRadius.circular(18),
          // Left accent keeps the category's own colour.
          border: Border(left: BorderSide(color: catColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon — keeps its own category colour
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: catColor,
                ),
                child: Icon(catIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: maroon,
                            ),
                          ),
                        ),
                        if (dist != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _formatDistance(dist),
                              style: TextStyle(
                                fontSize: 10,
                                color: catColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 12,
                          color: maroon.withOpacity(0.75),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(CupertinoIcons.clock,
                            size: 11, color: maroon.withOpacity(0.55)),
                        const SizedBox(width: 3),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 10,
                            color: maroon.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _verificationChip(verificationStatus),
                        const Spacer(),
                        const Row(
                          children: [
                            Text(
                              'View on Map',
                              style: TextStyle(
                                fontSize: 10,
                                color: maroon,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(CupertinoIcons.chevron_forward,
                                size: 10, color: maroon),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(3, (_) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
        ),
      )),
    );
  }

  Widget _buildEmpty(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            Icon(CupertinoIcons.bell_slash_fill,
                size: 48, color: nude.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(
              msg,
              style: TextStyle(
                  fontSize: 13, color: nude.withOpacity(0.45)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
