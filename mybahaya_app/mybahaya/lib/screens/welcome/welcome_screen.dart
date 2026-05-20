import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mascot Lifebuoy Painter (High fidelity drawn placeholder for the logo)
// ─────────────────────────────────────────────────────────────────────────────
class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.35;

    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintRed = Paint()
      ..color = const Color(0xFFB22222)
      ..style = PaintingStyle.fill;

    final paintOutline = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // 1. Draw shadow under mascot feet
    canvas.drawOval(
      Rect.fromLTRB(cx - radius * 0.7, cy + radius * 1.1, cx + radius * 0.7, cy + radius * 1.3),
      shadowPaint,
    );

    // 2. Draw little legs / feet at the bottom
    final pathLegs = Path()
      ..moveTo(cx - radius * 0.3, cy + radius * 0.6)
      ..lineTo(cx - radius * 0.35, cy + radius * 1.1)
      ..lineTo(cx - radius * 0.5, cy + radius * 1.15)
      ..lineTo(cx - radius * 0.25, cy + radius * 1.15)
      ..lineTo(cx - radius * 0.15, cy + radius * 0.6)
      ..close()
      ..moveTo(cx + radius * 0.3, cy + radius * 0.6)
      ..lineTo(cx + radius * 0.35, cy + radius * 1.1)
      ..lineTo(cx + radius * 0.5, cy + radius * 1.15)
      ..lineTo(cx + radius * 0.25, cy + radius * 1.15)
      ..lineTo(cx + radius * 0.15, cy + radius * 0.6)
      ..close();
    canvas.drawPath(pathLegs, paintWhite);
    canvas.drawPath(pathLegs, paintOutline);

    // 3. Draw little arms on the sides
    final pathArms = Path()
      // Left arm
      ..moveTo(cx - radius * 0.8, cy - radius * 0.1)
      ..quadraticBezierTo(cx - radius * 1.2, cy - radius * 0.05, cx - radius * 1.25, cy + radius * 0.2)
      ..quadraticBezierTo(cx - radius * 1.2, cy + radius * 0.4, cx - radius * 0.9, cy + radius * 0.5)
      ..lineTo(cx - radius * 0.8, cy + radius * 0.35)
      ..close()
      // Right arm
      ..moveTo(cx + radius * 0.8, cy - radius * 0.1)
      ..quadraticBezierTo(cx + radius * 1.2, cy - radius * 0.05, cx + radius * 1.25, cy + radius * 0.2)
      ..quadraticBezierTo(cx + radius * 1.2, cy + radius * 0.4, cx + radius * 0.9, cy + radius * 0.5)
      ..lineTo(cx + radius * 0.8, cy + radius * 0.35)
      ..close();
    canvas.drawPath(pathArms, paintWhite);
    canvas.drawPath(pathArms, paintOutline);

    // 4. Draw lifebuoy circular base (White body)
    canvas.drawCircle(Offset(cx, cy), radius, paintWhite);
    canvas.drawCircle(Offset(cx, cy), radius, paintOutline);

    // 5. Draw 4 red straps (top, bottom, left, right)
    final clipPath = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.save();
    canvas.clipPath(clipPath);

    // Top strap
    canvas.drawRect(Rect.fromLTWH(cx - radius * 0.25, cy - radius, radius * 0.5, radius * 0.45), paintRed);
    // Bottom strap
    canvas.drawRect(Rect.fromLTWH(cx - radius * 0.25, cy + radius * 0.55, radius * 0.5, radius * 0.45), paintRed);
    // Left strap
    canvas.drawRect(Rect.fromLTWH(cx - radius, cy - radius * 0.25, radius * 0.45, radius * 0.5), paintRed);
    // Right strap
    canvas.drawRect(Rect.fromLTWH(cx + radius * 0.55, cy - radius * 0.25, radius * 0.45, radius * 0.5), paintRed);

    canvas.restore();

    // Re-outline the lifebuoy ring
    canvas.drawCircle(Offset(cx, cy), radius, paintOutline);

    // 6. Draw lifebuoy inner hollow center (grey/dark background)
    final hollowPaint = Paint()
      ..color = const Color(0xFF1E0C0C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius * 0.5, hollowPaint);
    canvas.drawCircle(Offset(cx, cy), radius * 0.5, paintOutline);

    // 7. Draw inner target/eye shield
    canvas.drawCircle(Offset(cx, cy), radius * 0.3, paintRed);
    canvas.drawCircle(Offset(cx, cy), radius * 0.3, paintOutline);

    // Draw little center dot/eye
    canvas.drawCircle(Offset(cx, cy), radius * 0.1, paintWhite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome Screen
// ─────────────────────────────────────────────────────────────────────────────
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  const WelcomeScreen({
    super.key,
    required this.onSignIn,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      body: Container(
        color: AppTheme.solidBg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),

                // ── Logo Section ──
                Center(
                  child: SizedBox(
                    width: 130,
                    height: 130,
                    child: Image.asset(
                      'assets/images/logos/logo.png',
                      // Fallback dynamically to custom painted mascot if assets are not loaded yet
                      errorBuilder: (context, error, stackTrace) {
                        return CustomPaint(
                          painter: _MascotPainter(),
                          size: const Size(130, 130),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Titles ──
                Center(
                  child: Column(
                    children: [
                      Text(
                        'WELCOME',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'TO',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'MyBahaya',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Detailed Description Paragraph ──
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      'Hello and thank you for all users and especially Malaysians. This app is to acknowledge people about all kind of dangers and a faster reporting with evidence while keeping the reporter privacy and identity while helping those who in trouble getting help faster and safer. A strict legal action will be taken for users who create fake reports and scamming.\n\nStay Safe and "Kita Jaga Kita".',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFFACA494),
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // ── Buttons Row (Side-by-Side Pill-shaped outlines) ──
                Row(
                  children: [
                    Expanded(
                      child: _buildWelcomeButton('Sign In', onSignIn),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildWelcomeButton('Sign Up', onSignUp),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Outlined Pill Welcome Buttons ──
  Widget _buildWelcomeButton(String label, VoidCallback onTap) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withOpacity(0.8),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}