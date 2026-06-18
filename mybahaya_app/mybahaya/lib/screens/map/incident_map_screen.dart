import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../services/geocoding_service.dart';

class IncidentMapScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const IncidentMapScreen({super.key, required this.report});

  @override
  State<IncidentMapScreen> createState() => _IncidentMapScreenState();
}

class _IncidentMapScreenState extends State<IncidentMapScreen> {
  final MapController _mapController = MapController();
  bool _showPopup = true;
  String _placeName = 'Loading...';

  static const Color burgundy = Color(0xFFB22222);
  static const Color nude     = Color(0xFFACA494);
  static const Color pink = Colors.white;

  late final LatLng _incidentLatLng;
  late final String _category;
  late final String _details;
  late final String _imageUrl;

  @override
  void initState() {
    super.initState();
    final location = widget.report['location'] as Map<String, dynamic>? ?? {};
    final lat = (location['latitude']  as num?)?.toDouble() ?? 3.1390;
    final lng = (location['longitude'] as num?)?.toDouble() ?? 101.6869;
    _incidentLatLng = LatLng(lat, lng);
    _category = widget.report['category'] as String? ?? 'Unknown';
    _details  = widget.report['details']  as String? ?? '';
    _imageUrl = widget.report['imageUrl'] as String? ?? '';
    _loadPlaceName(lat, lng);
  }

  Future<void> _loadPlaceName(double lat, double lng) async {
    final name = await GeocodingService.getPlaceName(lat, lng);
    if (mounted) setState(() => _placeName = name);
  }

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'fire':    return const Color(0xFFFF6B35);
      case 'theft':   return const Color(0xFF9B59B6);
      case 'assault': return const Color(0xFFE74C3C);
      case 'medical': return const Color(0xFF2ECC71);
      default:        return burgundy;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'fire':    return Icons.local_fire_department_rounded;
      case 'theft':   return Icons.no_encryption_rounded;
      case 'assault': return Icons.personal_injury_rounded;
      case 'medical': return Icons.medical_services_rounded;
      default:        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(_category);

    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4D0A18),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFACA494),
              ),
            ),
            Text(
              _placeName,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _incidentLatLng,
              initialZoom: 16,
              minZoom: 10,
              maxZoom: 19,
              onTap: (_, __) {
                if (_showPopup) setState(() => _showPopup = false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://cartodb-basemaps-{s}.global.ssl.fastly.net/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.shukri.mybahaya',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _incidentLatLng,
                    width: 250,
                    height: _showPopup ? 280 : 56,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_showPopup) ...[
                          _buildPopup(catColor),
                          const SizedBox(height: 6),
                        ],
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showPopup = !_showPopup),
                          child: _buildPin(catColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Legend — top-left, always visible ────────────────
          Positioned(
            left: 12,
            top: 12,
            child: _buildLegend(),
          ),

          // ── Recenter FAB ──────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 32,
            child: GestureDetector(
              onTap: () => _mapController.move(_incidentLatLng, 16),
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
                child: Icon(Icons.my_location_rounded,
                    color: burgundy, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      _LegendItem(Icons.local_fire_department_rounded, const Color(0xFFFF6B35), 'Fire'),
      _LegendItem(Icons.no_encryption_rounded,         const Color(0xFF9B59B6), 'Theft'),
      _LegendItem(Icons.personal_injury_rounded,       const Color(0xFFE74C3C), 'Assault'),
      _LegendItem(Icons.medical_services_rounded,      const Color(0xFF2ECC71), 'Medical'),
      _LegendItem(Icons.warning_amber_rounded,         burgundy,               'Other'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LEGEND',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: item.color.withOpacity(0.3), blurRadius: 4),
                    ],
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 10),
                ),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: burgundy, width: 1.5),
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logos/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'You',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPin(Color catColor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: catColor,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: catColor.withOpacity(0.6),
            blurRadius: 14,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Icon(_categoryIcon(_category), color: Colors.white, size: 22),
    );
  }

  Widget _buildPopup(Color catColor) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF2A1515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: _imageUrl,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 90,
                  color: Colors.white.withOpacity(0.05),
                  child: Icon(Icons.broken_image_rounded,
                      color: nude.withOpacity(0.3)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: catColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_categoryIcon(_category), color: catColor, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        _category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: catColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: pink.withOpacity(0.7), size: 11),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        _placeName,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (_details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _details,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Tap pin to close',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  final IconData icon;
  final Color color;
  final String label;
  const _LegendItem(this.icon, this.color, this.label);
}
