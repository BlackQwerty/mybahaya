import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final PageController _pageController = PageController();

  // The live list — guarded with ?.length at every access point
  final List<_IncidentData>? _incidents;

  _HomeDashboardState()
      : _incidents = [
          _IncidentData(
            location: 'Bukit Katil, Melaka',
            status: '3 Active',
            trend: 'High Risk',
            zone: 'Zone: B2',
            title: 'Unauthorized Crowd Formation',
            description:
                'An unusual gathering of 50+ individuals detected near Tambahan. '
                'Local authorities have been notified and are en route to the scene.',
          ),
          _IncidentData(
            location: 'Sungai Udang, Melaka',
            status: '5 Active',
            trend: 'Critical',
            zone: 'Zone: A1',
            title: 'Suspicious Vehicle Loitering',
            description:
                'A white Toyota Vellfire bearing plate WXY 8899 has been stationary '
                'outside Sekolah Seri Puteri for the past 45 minutes. Plate check '
                'flagged as unregistered.',
          ),
          _IncidentData(
            location: 'Ayer Keroh, Melaka',
            status: '2 Active',
            trend: 'Moderate',
            zone: 'Zone: C3',
            title: 'Electrical Hazard Reported',
            description:
                'Live power line snapped near Jalan Utama block. Residents advised '
                'to keep a 15-metre radius. TNB crew has been dispatched.',
          ),
        ];

  /// Factory-style safe mapper — demonstrates ?? '' pattern for incoming JSON
  factory _HomeDashboardState.fromJson(Map<String, dynamic> json) {
    final rawList = json['incidents'] as List<dynamic>?;
    final parsed = rawList
            ?.map((e) => _IncidentData.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];
    return _HomeDashboardState._internal(parsed);
  }

  // Named constructor used by the factory above
  _HomeDashboardState._internal(this._incidents);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── 1 │ Null-safe guard: empty / null list ────────────────────
    if (_incidents == null || _incidents.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.solidBg,
        extendBody: true,
        body: _emptyState(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody: true,
      body: Stack(
        children: [
          // ── 2 │ Swipeable Content Feed ─────────────────────────
          SafeArea(
            bottom: false,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _incidents!.length,
              itemBuilder: (context, index) {
                final incident = _incidents![index];
                return _IncidentCard(incident: incident);
              },
            ),
          ),

          // ── 3 │ Fixed Global Header ────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.72),
                    Colors.black.withOpacity(0.00),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.maroonLight,
                              AppTheme.maroonPrimary,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.saved_search_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'MyBahaya',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.maroonGlow,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Loading / empty placeholder when the list is null or empty
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 72,
              color: Colors.white.withOpacity(0.20),
            ),
            const SizedBox(height: 20),
            Text(
              'No active alerts in your immediate vicinity.',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.60),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Pull down to refresh or check back shortly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.35),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Incident Card ───────────────────────────────────────────────────
class _IncidentCard extends StatelessWidget {
  final _IncidentData incident;

  const _IncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundMid.withOpacity(0.64),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 30,
            spreadRadius: -4,
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── CRITICAL: structural spacer — clears the 110 px header ──
            const SizedBox(height: 110),

            // ── Location Ribbon ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFFF3B30),
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    incident.location.fallback('Location Unspecified'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Summary Metrics Panel ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusPill(
                    incident.status.fallback('Unknown Status'),
                    Icons.bolt_rounded,
                    const Color(0xFFFF3B30),
                    Colors.red.withOpacity(0.35),
                  ),
                  _statusPill(
                    incident.trend.fallback('Unknown Risk'),
                    incident.trendIcon ?? Icons.trending_up_rounded,
                    const Color(0xFFFFCC00),
                    Colors.transparent,
                  ),
                  _statusPill(
                    incident.zone.fallback('Zone: N/A'),
                    incident.zoneIcon ?? Icons.map_rounded,
                    const Color(0xFF7A5CFF),
                    Colors.transparent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                incident.title.fallback('Unknown Incident'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // ── Description ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                incident.description.fallback('No threat details provided.'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.75),
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 20),

            // ── View Details Button ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _viewDetailsButton(context: context),
            ),

            const SizedBox(height: 20),

            // ── Mini-map ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _MiniMap(),
            ),

            // ── Bottom spacer — clears liquid-glass bottom nav bar ──
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ─── Status Pill ──────────────────────────────────────────────────
Widget _statusPill(
  String label,
  IconData icon,
  Color fill,
  Color glow,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: fill.withOpacity(0.18),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: fill.withOpacity(0.42)),
      boxShadow:
          glow != Colors.transparent
              ? [BoxShadow(color: glow, blurRadius: 8, spreadRadius: 1)]
              : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: fill, size: 13),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fill,
          ),
        ),
      ],
    ),
  );
}

// ─── View Details Button ───────────────────────────────────────────
Widget _viewDetailsButton({required BuildContext context}) {
  return GestureDetector(
    onTap: () {},
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.white70,
            size: 15,
          ),
          const SizedBox(width: 8),
          Text(
            'View Details',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.88),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Malaysia Silhouette Mini-map ──────────────────────────────────
class _MiniMap extends StatelessWidget {
  const _MiniMap();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Container(
          height: 108,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            children: [
              // Peninsular Malaysia
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 12,
                    right: 4,
                    top: 8,
                    bottom: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: _PeninsularPainter(),
                  ),
                ),
              ),
              // Borneo panel placeholder
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Borneo',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Threat dot — Peninsular
        _radarDot(const Color(0xFFFF3B30), left: 34, bottom: 26),
        // Safe dot — Borneo
        _radarDot(const Color(0xFF34C759), right: 28, top: 20),
      ],
    );
  }
}

Widget _radarDot(
  Color color, {
  double? left,
  double? right,
  double? top,
  double? bottom,
}) {
  return Positioned(
    left: left,
    right: right,
    top: top,
    bottom: bottom,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        return Transform.scale(
          scale: t,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6 * t),
                  blurRadius: 14,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ─── Peninsular Malaysia Silhouette Painter ─────────────────────────
class _PeninsularPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..style = PaintingStyle.fill;

    final h = size.height;
    final w = size.width;

    final pts = <Offset>[
      Offset(w * 0.05, h * 0.45),
      Offset(w * 0.20, h * 0.12),
      Offset(w * 0.40, h * 0.05),
      Offset(w * 0.60, h * 0.04),
      Offset(w * 0.75, h * 0.09),
      Offset(w * 0.90, h * 0.38),
      Offset(w * 0.85, h * 0.60),
      Offset(w * 0.60, h * 0.90),
      Offset(w * 0.40, h * 0.96),
      Offset(w * 0.20, h * 0.88),
      Offset(w * 0.08, h * 0.65),
    ];

    final path = Path()..addPolygon(pts, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════════════
//  _IncidentData  —  safe factory + mandatory fallback guarantees
// ════════════════════════════════════════════════════════════════════
class _IncidentData {
  final String? location;   // nullable — use .fallback() at call-site
  final String? status;
  final String? trend;
  final String? zone;
  final String? title;
  final String? description;
  final IconData? trendIcon;
  final IconData? zoneIcon;

  _IncidentData({
    this.location,
    this.status,
    this.trend,
    this.zone,
    this.title,
    this.description,
    this.trendIcon,
    this.zoneIcon,
  });

  // ── Named constructor with explicit ?? '' guards ─────────────
  _IncidentData.safe({
    String? location,
    String? status,
    String? trend,
    String? zone,
    String? title,
    String? description,
    IconData? trendIcon,
    IconData? zoneIcon,
  })  : location = location ?? 'Location Unspecified',
        status = status ?? 'Status Unknown',
        trend = trend ?? 'Risk Unknown',
        zone = zone ?? 'Zone: N/A',
        title = title ?? 'Unknown Incident',
        description = description ?? 'No threat details provided.',
        trendIcon = trendIcon ?? Icons.trending_up_rounded,
        zoneIcon = zoneIcon ?? Icons.map_rounded;

  // ── Factory mapper from Firestore / API JSON ──────────────────
  factory _IncidentData.fromMap(Map<String, dynamic> json) {
    return _IncidentData.safe(
      location: json['location']?.toString(),
      status: json['status']?.toString(),
      trend: json['trend']?.toString(),
      zone: json['zone']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      trendIcon: json['trendIcon'] is IconData
          ? json['trendIcon'] as IconData
          : null,
      zoneIcon: json['zoneIcon'] is IconData
          ? json['zoneIcon'] as IconData
          : null,
    );
  }

  /// Legacy safe mapper — mirrors the named constructor contract.
  static List<_IncidentData> safeFromMap(Map<String, dynamic> map) {
    return [_IncidentData.fromMap(map)];
  }
}

// ─── String extension — non-breaking fallback helper ─────────────────
extension _SafeString on String? {
  /// Returns this string if non-null/non-empty, otherwise the fallback.
  /// Guarantees a non-null String at every usage site.
  String fallback(String orElse) {
    final s = this;
    return (s == null || s.trim().isEmpty) ? orElse : s;
  }
}