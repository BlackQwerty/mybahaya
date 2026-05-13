import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  final String title;
  final String buttonText;
  final VoidCallback onPressed;
  final int pageIndex; // 0=fire, 1=accident, 2=danger

  const OnboardingScreen({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onPressed,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: AppTheme.solidBg,
        child: Stack(
          children: [
            // Background particles/decorative elements
            ..._buildParticles(size),

            Column(
              children: [
                // Top 55% - Illustration area
                SizedBox(
                  height: size.height * 0.55,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppTheme.backgroundDeep.withOpacity(0.8),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      // Illustration placeholder
                      Center(
                        child: _buildIllustration(context),
                      ),
                      // Page indicator dots
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == pageIndex ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == pageIndex
                                    ? AppTheme.maroonGlow
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom 45% - Text content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.maroonPrimary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.maroonLight.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            'MyBahaya',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 12,
                              color: AppTheme.maroonGlow,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Report it. Help fast. Stay safe.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.55),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        // Action button
                        SizedBox(
                          width: double.infinity,
                          child: _buildActionButton(buttonText, onPressed),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    final icons = [
      {'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFF6B35), 'bg': const Color(0xFF4A1A00)},
      {'icon': Icons.car_crash_rounded, 'color': const Color(0xFFFFCC00), 'bg': const Color(0xFF4A3A00)},
      {'icon': Icons.warning_amber_rounded, 'color': const Color(0xFFFF3B30), 'bg': const Color(0xFF4A0A0A)},
    ];

    final item = icons[pageIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stack glow + icon circle together — no negative margin needed
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow layer (slightly larger, behind)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (item['color'] as Color).withOpacity(0.35),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
              // Icon circle (on top, centred)
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (item['bg'] as Color).withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: (item['color'] as Color).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  size: 90,
                  color: item['color'] as Color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Decorative rings
        _buildDecorativeRings(item['color'] as Color),
      ],
    );
  }

  Widget _buildDecorativeRings(Color color) {
    return SizedBox(
      width: 200,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  color.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParticles(Size size) {
    return [
      Positioned(
        top: -50,
        right: -30,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.maroonPrimary.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: -40,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.maroonLight.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB22222), Color(0xFF8B1A1A)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB22222).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
