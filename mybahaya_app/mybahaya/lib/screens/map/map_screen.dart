import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar.dart';
import '../../services/geocoding_service.dart';
import 'incident_map_screen.dart';

// ── Data types ────────────────────────────────────────────────────────────────

class _ReportGroup {
  final double lat;
  final double lng;
  final List<Map<String, dynamic>> items;
  _ReportGroup(this.lat, this.lng, this.items);
}


// ── MapScreen ─────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _locating = true;

  static const LatLng _klCenter = LatLng(3.1390, 101.6869);
  static const Color burgundy   = Color(0xFFB22222);

  bool _mapReady = false;
  LatLng? _pendingFocus;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _locating = false); return; }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;

      final userLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentPosition = userLatLng;
        _locating = false;
      });

      // Zoom 10.5 shows ~70 km radius — enough to see the whole state.
      // No Nominatim call needed; GPS position IS the state center.
      if (_mapReady) {
        _mapController.move(userLatLng, 10.5);
      } else {
        _pendingFocus = userLatLng;
      }
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onMapReady() {
    _mapReady = true;
    if (_pendingFocus != null) {
      _mapController.move(_pendingFocus!, 10.5);
      _pendingFocus = null;
    }
  }

  // Group reports within ~100 m (0.001° ≈ 111 m) under one cluster key
  List<_ReportGroup> _groupByLocation(List<QueryDocumentSnapshot> docs) {
    final Map<String, _ReportGroup> groups = {};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final loc  = data['location'] as Map<String, dynamic>?;
      if (loc == null) continue;
      final lat = (loc['latitude']  as num?)?.toDouble();
      final lng = (loc['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
      if (!groups.containsKey(key)) groups[key] = _ReportGroup(lat, lng, []);
      groups[key]!.items.add(data);
    }
    return groups.values.toList();
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

  List<Marker> _buildClusteredMarkers(
      List<QueryDocumentSnapshot> docs, BuildContext context) {
    final groups  = _groupByLocation(docs);
    final markers = <Marker>[];

    for (final group in groups) {
      if (group.items.length == 1) {
        // ── Single report → category pin ─────────────────────────────
        final data  = group.items[0];
        final cat   = data['category'] as String? ?? 'Other';
        final color = _catColor(cat);
        final icon  = _catIcon(cat);

        markers.add(Marker(
          point:     LatLng(group.lat, group.lng),
          width: 40, height: 40,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () => _showIncidentSheet(context, data),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 8, spreadRadius: 1,
                  offset: const Offset(0, 2),
                )],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
        ));
      } else {
        // ── Multiple reports → cluster marker with color ring ─────────
        markers.add(Marker(
          point:     LatLng(group.lat, group.lng),
          width: 54, height: 54,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _showClusterSheet(context, group.items),
            child: _ClusterMarker(items: group.items, catColor: _catColor),
          ),
        ));
      }
    }
    return markers;
  }

  void _showIncidentSheet(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _IncidentSheet(
        report: data,
        onViewMap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => IncidentMapScreen(report: data),
          ));
        },
      ),
    );
  }

  void _showClusterSheet(
      BuildContext context, List<Map<String, dynamic>> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ClusterSheet(
        items:       items,
        catColor:    _catColor,
        catIcon:     _catIcon,
        onTapReport: (data) {
          Navigator.pop(context);
          _showIncidentSheet(context, data);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody: true,
      appBar: const MyBahayaAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        // Community map reads the sanitized public feed (not the locked reports).
        stream: FirebaseFirestore.instance
            .collection('public_incidents')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _klCenter,
                  initialZoom: 7,
                  minZoom: 5,
                  maxZoom: 19,
                  onMapReady: _onMapReady,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://cartodb-basemaps-{s}.global.ssl.fastly.net/rastertiles/voyager/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.shukri.mybahaya',
                    maxZoom: 19,
                  ),
                  MarkerLayer(markers: _buildClusteredMarkers(docs, context)),
                  if (_currentPosition != null)
                    MarkerLayer(markers: [_buildUserMarker()]),
                ],
              ),
              Positioned(
                top: 12, left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInfoStrip(docs.length),
                    const SizedBox(height: 8),
                    _buildLegend(),
                  ],
                ),
              ),
              Positioned(
                right: 12, bottom: 110,
                child: _buildRecenterFab(),
              ),
            ],
          );
        },
      ),
    );
  }

  Marker _buildUserMarker() {
    return Marker(
      point: _currentPosition!,
      width: 48, height: 48,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: burgundy, width: 2.5),
          boxShadow: [BoxShadow(
            color: burgundy.withOpacity(0.35),
            blurRadius: 10, spreadRadius: 2,
          )],
          color: Colors.white,
        ),
        child: ClipOval(
          child: Image.asset('assets/images/logos/logo.png', fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildInfoStrip(int count) {
    const bgColor = Color(0xFF4D0A18);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.60),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.map_fill, color: Colors.white.withOpacity(0.85), size: 15),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count incident${count == 1 ? '' : 's'} on map',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              Text(
                'Tap any pin for details',
                style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.60)),
              ),
            ],
          ),
          const SizedBox(width: 10),
          if (_locating)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 10, height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Text('Locating', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.6))),
              ],
            )
          else if (_currentPosition != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF2ECC71),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Live', style: TextStyle(
                  fontSize: 9, color: Color(0xFF2ECC71), fontWeight: FontWeight.w700,
                )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      _LegendItem(CupertinoIcons.flame_fill,                     const Color(0xFFFF6B35), 'Fire'),
      _LegendItem(CupertinoIcons.lock_open_fill,                 const Color(0xFF9B59B6), 'Theft'),
      _LegendItem(CupertinoIcons.exclamationmark_circle_fill,    const Color(0xFFE74C3C), 'Assault'),
      _LegendItem(CupertinoIcons.plus_circle_fill,               const Color(0xFF2ECC71), 'Medical'),
      _LegendItem(CupertinoIcons.exclamationmark_triangle_fill,  burgundy,                'Other'),
    ];
    const bgColor = Color(0xFF4D0A18);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.60),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LEGEND',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.50), letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: item.color,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [BoxShadow(color: item.color.withOpacity(0.5), blurRadius: 6)],
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.90),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset('assets/images/logos/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 8),
              Text('You', style: TextStyle(
                fontSize: 12, color: Colors.white.withOpacity(0.90), fontWeight: FontWeight.w500,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecenterFab() {
    return GestureDetector(
      onTap: () {
        if (_currentPosition != null) _mapController.move(_currentPosition!, 15);
      },
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: Icon(CupertinoIcons.location_fill, color: burgundy, size: 22),
      ),
    );
  }
}

// ── Cluster marker — colored arc ring + count badge ────────────────────────

class _ClusterMarker extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Color Function(String) catColor;

  const _ClusterMarker({required this.items, required this.catColor});

  Map<String, int> _categoryCounts() {
    final counts = <String, int>{};
    for (final item in items) {
      final cat = item['category'] as String? ?? 'Other';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _categoryCounts();
    return SizedBox(
      width: 54, height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Colored arc ring
          CustomPaint(
            size: const Size(54, 54),
            painter: _RingPainter(counts: counts, catColor: catColor),
          ),
          // Dark inner circle with count
          Container(
            width: 38, height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1A0A0A),
            ),
            child: Center(
              child: Text(
                '${items.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Map<String, int> counts;
  final Color Function(String) catColor;

  const _RingPainter({required this.counts, required this.catColor});

  @override
  void paint(Canvas canvas, Size size) {
    final total  = counts.values.fold(0, (a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final paint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap   = StrokeCap.butt;

    // Small gap between segments (in radians)
    const gap       = 0.06;
    double startAngle = -math.pi / 2;

    counts.forEach((cat, count) {
      final sweepAngle = (count / total) * 2 * math.pi - gap;
      paint.color = catColor(cat);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gap / 2,
        sweepAngle.clamp(0.01, 2 * math.pi),
        false,
        paint,
      );
      startAngle += (count / total) * 2 * math.pi;
    });
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.counts.toString() != counts.toString();
}

// ── Cluster bottom sheet — scrollable list of all reports ─────────────────

class _ClusterSheet extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Color Function(String)    catColor;
  final IconData Function(String) catIcon;
  final void Function(Map<String, dynamic>) onTapReport;

  const _ClusterSheet({
    required this.items,
    required this.catColor,
    required this.catIcon,
    required this.onTapReport,
  });

  String _fmtTime(dynamic ts) {
    if (ts == null) return '—';
    DateTime dt;
    try { dt = (ts as dynamic).toDate(); } catch (_) { return '—'; }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours   < 1)  return '${diff.inMinutes}m ago';
    if (diff.inDays    < 1)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return '${dt.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB22222).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length} incidents here',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB22222),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tap one to see details',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          // Scrollable report list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, i) {
                final data     = items[i];
                final cat      = data['category'] as String? ?? 'Other';
                final details  = data['details']  as String? ?? '';
                final imageUrl = data['imageUrl'] as String? ?? '';
                final color    = catColor(cat);
                final icon     = catIcon(cat);
                final ts       = data['createdAt'];

                return InkWell(
                  onTap: () => onTapReport(data),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        // Thumbnail
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 54, height: 54,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 54, height: 54,
                                color: Colors.grey.shade100,
                                child: Icon(CupertinoIcons.photo,
                                    color: Colors.grey.shade300, size: 20),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                        const SizedBox(width: 12),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: color.withOpacity(0.25)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, color: color, size: 10),
                                        const SizedBox(width: 4),
                                        Text(cat.toUpperCase(), style: TextStyle(
                                          fontSize: 9, fontWeight: FontWeight.w700, color: color,
                                        )),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(_fmtTime(ts), style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade400,
                                  )),
                                ],
                              ),
                              if (details.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  details,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ] else ...[
                                const SizedBox(height: 5),
                                Text('No description', style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic,
                                )),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(CupertinoIcons.chevron_right,
                            color: Colors.grey.shade300, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single incident bottom sheet ──────────────────────────────────────────

class _IncidentSheet extends StatefulWidget {
  final Map<String, dynamic> report;
  final VoidCallback onViewMap;

  const _IncidentSheet({required this.report, required this.onViewMap});

  @override
  State<_IncidentSheet> createState() => _IncidentSheetState();
}

class _IncidentSheetState extends State<_IncidentSheet> {
  String _placeName = 'Loading location...';
  static const Color burgundy = Color(0xFFB22222);

  @override
  void initState() {
    super.initState();
    final loc = widget.report['location'] as Map<String, dynamic>? ?? {};
    final lat = (loc['latitude']  as num?)?.toDouble();
    final lng = (loc['longitude'] as num?)?.toDouble();
    if (lat != null && lng != null) {
      GeocodingService.getPlaceName(lat, lng).then((name) {
        if (mounted) setState(() => _placeName = name);
      });
    } else {
      _placeName = 'Unknown location';
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

  @override
  Widget build(BuildContext context) {
    final category = widget.report['category'] as String? ?? 'Other';
    final details  = widget.report['details']  as String? ?? '';
    final imageUrl = widget.report['imageUrl'] as String? ?? '';
    final catColor = _catColor(category);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.grey.shade100,
                  child: Icon(CupertinoIcons.photo, color: Colors.grey.shade300, size: 40),
                ),
              ),
            ).withPadding(horizontal: 16),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: catColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_catIcon(category), color: catColor, size: 13),
                      const SizedBox(width: 5),
                      Text(category.toUpperCase(), style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: catColor, letterSpacing: 0.5,
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.location_fill,
                          color: Colors.grey.shade400, size: 13),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _placeName,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                details,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity, height: 46,
              child: ElevatedButton.icon(
                onPressed: widget.onViewMap,
                icon: const Icon(CupertinoIcons.map_fill, size: 17),
                label: const Text('View on Map',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: burgundy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _PaddingExtension on Widget {
  Widget withPadding({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        child: this,
      );
}

class _LegendItem {
  final IconData icon;
  final Color    color;
  final String   label;
  const _LegendItem(this.icon, this.color, this.label);
}
