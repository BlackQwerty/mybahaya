import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
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
  bool _autoShareLocation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody: true,
      body: Container(
        color: AppTheme.solidBg,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeader(title: 'Settings'),
                const SizedBox(height: 28),

                // ── Section 1 — User Profile Card ─────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Profile',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.90),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1B1B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: const CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.maroonPrimary,
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          title: Text(
                            'Bro Kirk',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'p.........@gmail.com',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.50),
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white.withOpacity(0.30),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Section 2 — Notifications Toggles ─────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.90),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1B1B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _settingTile(
                              title: 'Emergency Alerts',
                              subtitle:
                                  'Critical danger proximity notifications',
                              icon: Icons.warning_rounded,
                              iconColor: AppTheme.alertRed,
                              value: _emergencyAlerts,
                              onChanged: (v) =>
                                  setState(() => _emergencyAlerts = v),
                            ),
                            _navDivider(),
                            _settingTile(
                              title: 'Safe-Zone Entry',
                              subtitle: 'Chime when entering verified safe zones',
                              icon: Icons.shield_rounded,
                              iconColor: AppTheme.alertGreen,
                              value: _safeZoneEntry,
                              onChanged: (v) =>
                                  setState(() => _safeZoneEntry = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Section 3 — Privacy Controls ──────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Controls',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.90),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1B1B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _settingTile(
                              title: 'Ghost Mode',
                              subtitle: 'Hide your real-time position from others',
                              icon: Icons.visibility_off_rounded,
                              iconColor: const Color(0xFF9B59B6),
                              value: _ghostMode,
                              onChanged: (v) =>
                                  setState(() => _ghostMode = v),
                            ),
                            _navDivider(),
                            _settingTile(
                              title: 'Hide Username',
                              subtitle: 'Hides your username from others',
                              icon: Icons.person_off_rounded,
                              iconColor: const Color(0xFF007AFF),
                              value: _hideUsername,
                              onChanged: (v) =>
                                  setState(() => _hideUsername = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Section 4 — Account Utilities ─────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.90),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1B1B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _utilityTile(
                              'Change Password',
                              Icons.lock_reset_rounded,
                            ),
                            _navDivider(),
                            _utilityTile(
                              'Help & Support',
                              Icons.help_outline_rounded,
                              iconColor: AppTheme.maroonGlow,
                            ),
                            _navDivider(),
                            _utilityTile(
                              'Logout',
                              Icons.logout_rounded,
                              iconColor: AppTheme.alertRed,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom safety spacer — clears liquid-glass nav bar ──
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Setting toggle tile ───────────────────────────────────────
  Widget _settingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.40),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.greenAccent[700] ?? Colors.green,
            activeTrackColor: Colors.green.withOpacity(0.8),
            inactiveThumbColor: Colors.white.withOpacity(0.3),
            inactiveTrackColor: Colors.white.withOpacity(0.08),
          ),
        ],
      ),
    );
  }

  // ─── Utility list tile ─────────────────────────────────────────
  Widget _utilityTile(String title, IconData icon, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.white).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Colors.white70,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.25),
            size: 18,
          ),
        ],
      ),
    );
  }

  // ─── Divider ───────────────────────────────────────────────────
  Widget _navDivider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white.withOpacity(0.06),
      );
}