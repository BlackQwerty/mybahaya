import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mybahaya/widgets/app_bar.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../../widgets/app_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emergencyAlerts = true;
  bool _safeZoneEntry = true;
  bool _ghostMode = false;
  bool _hideUsername = false;

  // Exact theme color tokens from the user request
  static const Color nudeColor = Color(0xFFACA494);
  static const Color pinkColor = Color(0xFFFFABBB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody:
          true, // Let the background scroll seamlessly below the nav bar
      appBar: const MyBahayaAppBar(),

      // FIX: Removed the outer SafeArea wrapper from here
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          130, // Increased to 130 to give your premium custom buttons clear padding from the nav bar
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // ── Header Title & Subtitle ──
              const AppHeader(title: 'Settings'),
              const SizedBox(height: 32),

              // ── Section 1: Edit Profile ──
              _buildSectionHeader(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF422E2E).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F4C81).withOpacity(0.2),
                      border: Border.all(
                        color: pinkColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logos/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person_rounded,
                            color: pinkColor,
                            size: 28,
                          );
                        },
                      ),
                    ),
                  ),
                  title: Text(
                    'Bro Kirk',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: pinkColor,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'p---------@gmail.com',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: pinkColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white54,
                    size: 24,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // ── Section 2: Notifications Toggles ──
              _buildSectionHeader(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications Toggles',
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF422E2E).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    _buildToggleRow(
                      title: 'Emergency Alerts',
                      subtitle: 'Critical danger proximity notifications',
                      value: _emergencyAlerts,
                      onChanged: (v) => setState(() => _emergencyAlerts = v),
                    ),
                    _buildDivider(),
                    _buildToggleRow(
                      title: 'Safe-Zone Entry',
                      subtitle: 'Chime when entering verified safe zones',
                      value: _safeZoneEntry,
                      onChanged: (v) => setState(() => _safeZoneEntry = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Section 3: Privacy Controls ──
              _buildSectionHeader(
                icon: Icons.security_rounded,
                label: 'Privacy Controls',
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF422E2E).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    _buildToggleRow(
                      title: 'Ghost Mode',
                      subtitle: 'Hide your real-time position from others',
                      value: _ghostMode,
                      onChanged: (v) => setState(() => _ghostMode = v),
                    ),
                    _buildDivider(),
                    _buildToggleRow(
                      title: 'Hide Username',
                      subtitle: 'Hides your username from others',
                      value: _hideUsername,
                      onChanged: (v) => setState(() => _hideUsername = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Section 4: Log Out & Utilities ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF422E2E).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: _buildActionRow(
                  title: 'Log Out',
                  icon: Icons.logout_rounded,
                  color: pinkColor,
                  onTap: () {},
                ),
              ),
            ],
          ),
      ),
    );
  }

  // ── Section Header Widget ──
  Widget _buildSectionHeader({required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: pinkColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: nudeColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom Toggle Row Widget ──
  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: pinkColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: nudeColor.withOpacity(0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // High-fidelity custom Switch to match the mockup exactly
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    value
                        ? const Color(0xFFB22222).withOpacity(0.2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.85),
                  width: 1.5,
                ),
              ),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Row Widget (For Log Out) ──
  Widget _buildActionRow({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color.withOpacity(0.5),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  // ── Custom Divider Widget ──
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white.withOpacity(0.06),
    );
  }
}
