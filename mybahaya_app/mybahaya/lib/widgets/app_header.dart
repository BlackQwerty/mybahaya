import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppHeader extends StatelessWidget {
  final String title;

  const AppHeader({
    super.key,
    required this.title,
  });

  // Exact theme color tokens
  static const Color nudeColor = Color(0xFFACA494);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _getSubtitle(title),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: nudeColor,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  String _getSubtitle(String title) {
    if (title.startsWith('Hello')) {
      return 'Welcome back to your safety hub.';
    }
    switch (title) {
      case 'Settings':
        return 'Configure your privacy preferences.';
      case 'Live Alerts':
        return 'Real-time safety intelligence for your current vicinity.';
      case 'Report':
        return 'Report incidents with photos and location data.';
      case 'Map Overview':
      case 'Map':
        return 'Interactive tactical hazard & safe zones overview.';
      default:
        return '';
    }
  }
}
