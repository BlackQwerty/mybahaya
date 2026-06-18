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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _locating = true;

  // Default: Kuala Lumpur — map shows immediately before GPS resolves
  static const LatLng _klCenter = LatLng(3.1390, 101.6869);
  static const Color burgundy = Color(0xFFB22222);

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
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          _locating = false;
        });
        _mapController.move(_currentPosition!, 15);
      }
    } catch (_) {
      if (mounted) setState(() => _locating = false);
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
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody: true,
      appBar: const MyBahayaAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          return Stack(
            children: [
              // ── Map ────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _klCenter,
                  initialZoom: 11,
                  minZoom: 5,
                  maxZoom: 19,
                ),
                children: [
                  // CartoDB Voyager — warm Google-Maps-like style, free, no API key
                  TileLayer(
                    urlTemplate:
                        'https://cartodb-basemaps-{s}.global.ssl.fastly.net/rastertiles/voyager/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.shukri.mybahaya',
                    maxZoom: 19,
                  ),

                  // Incident markers from Firestore
                  MarkerLayer(
                    markers: _buildIncidentMarkers(docs, context),
                  ),

                  // User location — logo marker on top
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: [_buildUserMarker()],
                    ),
                ],
              ),

              // ── Info strip + Legend — stacked top-left ─────────────
              Positioned(
                top: 12,
                left: 12,
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

              // ── Recenter FAB — bottom-right ─────────────────────────
              Positioned(
                right: 12,
                bottom: 110,
                child: _buildRecenterFab(),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Marker> _buildIncidentMarkers(
      List<QueryDocumentSnapshot> docs, BuildContext context) {
    final markers = <Marker>[];
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final loc = data['location'] as Map<String, dynamic>?;
      if (loc == null) continue;
      final lat = (loc['latitude']  as num?)?.toDouble();
      final lng = (loc['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final cat = data['category'] as String? ?? 'other';
      final color = _catColor(cat);
      final icon  = _catIcon(cat);

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () => _showIncidentSheet(context, data),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.45),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Marker _buildUserMarker() {
    return Marker(
      point: _currentPosition!,
      width: 48,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: burgundy, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: burgundy.withOpacity(0.35),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          color: Colors.white,
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/logos/logo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IncidentMapScreen(report: data),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoStrip(int count) {
    // Shared maroon style — 60% opacity, same as legend
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Tap any pin for details',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.60),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          if (_locating)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Locating',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            )
          else if (_currentPosition != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2ECC71),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 9,
                    color: const Color(0xFF2ECC71),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      _LegendItem(CupertinoIcons.flame_fill, const Color(0xFFFF6B35), 'Fire'),
      _LegendItem(CupertinoIcons.lock_open_fill,         const Color(0xFF9B59B6), 'Theft'),
      _LegendItem(CupertinoIcons.exclamationmark_circle_fill,       const Color(0xFFE74C3C), 'Assault'),
      _LegendItem(CupertinoIcons.plus_circle_fill,      const Color(0xFF2ECC71), 'Medical'),
      _LegendItem(CupertinoIcons.exclamationmark_triangle_fill,         burgundy,               'Other'),
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
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.50),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.90),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )),
          // You — logo marker
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logos/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'You',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.90),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecenterFab() {
    return GestureDetector(
      onTap: () {
        if (_currentPosition != null) {
          _mapController.move(_currentPosition!, 15);
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(CupertinoIcons.location_fill, color: burgundy, size: 22),
      ),
    );
  }
}

// ── Incident bottom sheet ─────────────────────────────────────────────────────
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
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Image
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
                  child: Icon(CupertinoIcons.photo,
                      color: Colors.grey.shade300, size: 40),
                ),
              ),
            ).withPadding(horizontal: 16),

          const SizedBox(height: 14),

          // Category + location row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
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
                      Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: catColor,
                          letterSpacing: 0.5,
                        ),
                      ),
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
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
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

          // Details text
          if (details.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                details,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // View on Map button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: widget.onViewMap,
                icon: const Icon(CupertinoIcons.map_fill, size: 17),
                label: Text(
                  'View on Map',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: burgundy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Convenience extension to avoid wrapping widgets in extra Padding widgets
extension _PaddingExtension on Widget {
  Widget withPadding({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding: EdgeInsets.symmetric(
            horizontal: horizontal, vertical: vertical),
        child: this,
      );
}

// ── Data class ────────────────────────────────────────────────────────────────
class _LegendItem {
  final IconData icon;
  final Color color;
  final String label;
  const _LegendItem(this.icon, this.color, this.label);
}
