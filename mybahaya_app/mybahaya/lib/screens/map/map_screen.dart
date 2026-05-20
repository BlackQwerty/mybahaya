import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_header.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentPosition != null) {
          _mapController.move(_currentPosition!, 15);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody: true,
      appBar: MyBahayaAppBar(),
      body: Stack(
        children: [
          // ── BASE LAYER: MAP VIEWER ──────────────────────────────────────────
          _isLoading || _currentPosition == null
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.maroonGlow),
              )
              : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition!,
                  initialZoom: 15,
                  minZoom: 10,
                  maxZoom: 18,
                ),
                children: [
                  // Free, High-Stability OpenStreetMap Tile Alternative
                  // Standard OpenStreetMap tile layer
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mybahaya.app',
                  ),

                  // User Location Target Vector Highlight Marker
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition!,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.maroonGlow,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.maroonGlow.withOpacity(0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

          // ── TOP NAVIGATION APP BAR HEADER overlay ──────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.solidBg.withOpacity(0.92),
                    AppTheme.solidBg.withOpacity(0.00),
                  ],
                ),
              ),
              child: const AppHeader(title: 'Map Overview'),
            ),
          ),

          // ── SLIDER/HUD CONTROLLER PANEL (Flexible Width Boundary Fix) ──────
          Positioned(
            top: 125, // Adjusted from 165 to perfectly clear the non-SafeArea header
            left: 20,
            child: SizedBox(
              width: 190, // 1. Increased from 175 to prevent the inner width crash
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ), // 2. Optimized padding
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.40),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: Colors.white.withOpacity(0.6),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tactical Overlay',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _tacticalPill(
                          icon: Icons.gpp_maybe_rounded,
                          label: 'Danger Zones',
                          iconColor: AppTheme.alertRed,
                          onTap: () {},
                        ),
                        const SizedBox(height: 6),
                        _tacticalPill(
                          icon: Icons.warning_amber_rounded,
                          label: 'Incidents',
                          iconColor: AppTheme.alertYellow,
                          onTap: () {},
                        ),
                        const SizedBox(height: 6),
                        _tacticalPill(
                          icon: Icons.shield_rounded,
                          label: 'Safe Havens',
                          iconColor: AppTheme.alertGreen,
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),

                        // 3. Replaced fixed row widths with natural space distribution
                        _metricRow(
                          title: 'Local Risk',
                          value: '3.8',
                          valueColor: Colors.blueAccent,
                        ),
                        const SizedBox(height: 6),
                        _metricRow(
                          title: 'Active Alerts',
                          value: '12',
                          valueColor: AppTheme.alertYellow,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── FLOATING ACTUATORS (FAB Placement) ─────────────────────────────
          Positioned(
            right: 20,
            bottom: 115,
            child: Column(
              children: [
                _glassFab(icon: Icons.layers_rounded, onTap: () {}),
                const SizedBox(height: 12),
                _glassFab(
                  icon: Icons.my_location_rounded,
                  onTap: () {
                    if (_currentPosition != null) {
                      _mapController.move(_currentPosition!, 15);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tacticalPill({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.8),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.90),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassFab({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sleek Custom Incident Pin ──────────────────────────────────────────
class _IncidentMarker extends StatelessWidget {
  final String severity;
  final String type;

  const _IncidentMarker({required this.severity, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final icon = _getIncidentIcon(type);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Color _color() {
    switch (severity.toLowerCase()) {
      case 'high':
        return const Color(0xFFFF3B30);
      case 'medium':
        return const Color(0xFFFFCC00);
      case 'low':
        return const Color(0xFF34C759);
      default:
        return const Color(0xFFFF3B30);
    }
  }

  IconData _getIncidentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'accident':
        return Icons.car_crash_rounded;
      case 'theft':
        return Icons.gpp_bad_rounded;
      default:
        return Icons.warning_rounded;
    }
  }
}

// ─── Floating Hospital Label Marker ─────────────────────────────────
class _HospitalMarker extends StatelessWidget {
  final String label;

  const _HospitalMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A).withOpacity(0.85),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(
          Icons.location_on_rounded,
          color: Color(0xFFFF3B30),
          size: 18,
        ),
      ],
    );
  }
}
