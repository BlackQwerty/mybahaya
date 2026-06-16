import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_header.dart';
import '../../services/user_service.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final List<_IncidentData> _incidents = [
    _IncidentData(
      location: 'Bukit Katil, Melaka',
      title: 'Unauthorized Crowd Formation',
      descriptionPrefix:
          'An unusual gathering of 50+ individuals detected near ',
      highlightText: 'Taman Bukit Bayan',
      descriptionSuffix:
          '. Local authorities have been notified and are en route.',
    ),
    _IncidentData(
      location: 'Sungai Udang, Melaka',
      title: 'Suspicious Vehicle Loitering',
      descriptionPrefix:
          'A white Toyota Vellfire bearing plate WXY 8899 has been stationary outside ',
      highlightText: 'Sekolah Seri Puteri',
      descriptionSuffix:
          ' for the past 45 minutes. Plate check flagged as unregistered.',
    ),
    _IncidentData(
      location: 'Ayer Keroh, Melaka',
      title: 'Electrical Hazard Snap',
      descriptionPrefix:
          'Live power line snapped near Jalan Utama block. Residents advised to keep a ',
      highlightText: '15-metre radius',
      descriptionSuffix: '. TNB crew has been dispatched.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody:
          true, // Allows content to flow smoothly underneath the navigation bar
      appBar: const MyBahayaAppBar(),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          130, // Standardized bottom spacing clear of navigation bar
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting with real username from Firestore ──
            StreamBuilder<UserProfile?>(
              stream: UserService.profileStream(),
              builder: (context, snapshot) {
                final username = snapshot.data?.username;
                final greeting = (username != null && username.isNotEmpty)
                    ? 'Hello, $username'
                    : 'Hello';
                return AppHeader(title: greeting);
              },
            ),
            const SizedBox(height: 24),

            // ── Location Chip ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFB22222),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bukit Katil, Melaka',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFACA494),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Scrollable Card Feed ──
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _incidents.length,
              itemBuilder: (context, index) {
                return _buildIncidentCard(_incidents[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Incident Card Builder ──
  Widget _buildIncidentCard(_IncidentData incident) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(
          0xFF422E2E,
        ).withOpacity(0.55), // Lighter warm brown/maroon container
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Red Badge Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF8B1A1A,
                ).withOpacity(0.9), // Lighter red badge background
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NEARBY INCIDENT + SEVERITY',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Incident Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              incident.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.25,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Rich Highlighted Paragraph
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: incident.descriptionPrefix),
                  TextSpan(
                    text: incident.highlightText,
                    style: const TextStyle(
                      color: Color(0xFFACA494), // Warm gold highlight
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: incident.descriptionSuffix),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 4. View Details Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 38,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 16,
                ),
                label: Text(
                  'View Details',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF261212,
                  ).withOpacity(0.8), // Dark outline background
                  side: BorderSide(color: Colors.white.withOpacity(0.12)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 5. Malaysia Silhouette Mini-map
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFD9D5CD,
                ), // Beautiful light gold/gray map background
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(painter: _MalaysiaMapPainter()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Malaysia Map Silhouette Painter
// ─────────────────────────────────────────────────────────────────────────────
class _MalaysiaMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintMap =
        Paint()
          ..color = const Color(0xFF1D5F8A) // Premium Malaysia blue silhouette
          ..style = PaintingStyle.fill;

    final paintOverlay =
        Paint()
          ..color = const Color(
            0xFFB22222,
          ) // Red accent dot for threat location
          ..style = PaintingStyle.fill;

    final paintGlow =
        Paint()
          ..color = const Color(0xFFB22222).withOpacity(0.4)
          ..style = PaintingStyle.fill;

    // West Malaysia Path (Stylized polygon)
    final pathWest =
        Path()
          ..moveTo(size.width * 0.15, size.height * 0.40)
          ..quadraticBezierTo(
            size.width * 0.18,
            size.height * 0.22,
            size.width * 0.23,
            size.height * 0.18,
          )
          ..quadraticBezierTo(
            size.width * 0.28,
            size.height * 0.15,
            size.width * 0.32,
            size.height * 0.20,
          )
          ..lineTo(size.width * 0.35, size.height * 0.32)
          ..quadraticBezierTo(
            size.width * 0.38,
            size.height * 0.45,
            size.width * 0.36,
            size.height * 0.58,
          )
          ..lineTo(size.width * 0.38, size.height * 0.72)
          ..quadraticBezierTo(
            size.width * 0.32,
            size.height * 0.85,
            size.width * 0.28,
            size.height * 0.88,
          )
          ..quadraticBezierTo(
            size.width * 0.22,
            size.height * 0.72,
            size.width * 0.20,
            size.height * 0.65,
          )
          ..close();

    // East Malaysia Path (Stylized polygon)
    final pathEast =
        Path()
          ..moveTo(size.width * 0.50, size.height * 0.65)
          ..quadraticBezierTo(
            size.width * 0.55,
            size.height * 0.55,
            size.width * 0.62,
            size.height * 0.52,
          )
          ..quadraticBezierTo(
            size.width * 0.70,
            size.height * 0.56,
            size.width * 0.75,
            size.height * 0.48,
          )
          ..lineTo(size.width * 0.78, size.height * 0.35) // Sabah top tip
          ..quadraticBezierTo(
            size.width * 0.83,
            size.height * 0.38,
            size.width * 0.86,
            size.height * 0.45,
          )
          ..quadraticBezierTo(
            size.width * 0.88,
            size.height * 0.55,
            size.width * 0.84,
            size.height * 0.62,
          )
          ..quadraticBezierTo(
            size.width * 0.76,
            size.height * 0.68,
            size.width * 0.68,
            size.height * 0.72,
          )
          ..close();

    canvas.drawPath(pathWest, paintMap);
    canvas.drawPath(pathEast, paintMap);

    // Draw active incident radar dot (Bukit Katil, Melaka - Southern part of West Malaysia)
    final threatCenter = Offset(size.width * 0.32, size.height * 0.75);
    canvas.drawCircle(threatCenter, 12, paintGlow);
    canvas.drawCircle(threatCenter, 5, paintOverlay);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Incident Data Model
// ─────────────────────────────────────────────────────────────────────────────
class _IncidentData {
  final String location;
  final String title;
  final String descriptionPrefix;
  final String highlightText;
  final String descriptionSuffix;

  _IncidentData({
    required this.location,
    required this.title,
    required this.descriptionPrefix,
    required this.highlightText,
    required this.descriptionSuffix,
  });
}
