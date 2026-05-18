import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    required this.title,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.90),
                  ),
                ),
                GestureDetector(
                  onTap: onProfileTap,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.maroonPrimary,
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getSubtitle(title),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.50),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitle(String title) {
    switch (title) {
      case 'Settings':
        return 'Configure your privacy preferences.';
      case 'Live Alerts':
        return 'Real-time safety intelligence for your current vicinity.';
      case 'Report':
        return 'Report incidents with photos and location data.';
      default:
        return '';
    }
  }
}