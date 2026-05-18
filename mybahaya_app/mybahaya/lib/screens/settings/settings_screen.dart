import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

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
    // Calculate the space occupied by your floating bottom navigation bar
    // pillHeight (64) + bottom padding margin (16) + a little safety buffer (20)
    final double absoluteBottomPadding = 64.0 + 16.0 + 20.0;

    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody: true,
      body: Container(
        color: AppTheme.solidBg,
        child: SafeArea(
          bottom:
              false, // Prevents layout snapping away from the glass navigation footprint
          child: SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(), // Gives it that smooth native iOS/Android feel
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top navigation bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'MyBahaya',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.maroonGlow,
                        ),
                      ),
                      Text(
                        ' < Settings',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Profile card
                _buildProfileCard(),
                const SizedBox(height: 20),

                // Notifications section
                _sectionHeader('NOTIFICATIONS & PRIVACY'),
                const SizedBox(height: 10),
                _glassSection([
                  _toggleTile(
                    title: 'Emergency Alerts',
                    subtitle: 'Critical danger proximity notifications',
                    icon: Icons.warning_rounded,
                    iconColor: AppTheme.alertRed,
                    value: _emergencyAlerts,
                    onChanged: (v) => setState(() => _emergencyAlerts = v),
                  ),
                  _divider(),
                  _toggleTile(
                    title: 'Safe-Zone Entry',
                    subtitle: 'Chime when entering verified safe zones',
                    icon: Icons.shield_rounded,
                    iconColor: AppTheme.alertGreen,
                    value: _safeZoneEntry,
                    onChanged: (v) => setState(() => _safeZoneEntry = v),
                  ),
                  _divider(),
                  _toggleTile(
                    title: 'Ghost Mode',
                    subtitle: 'Hide your real-time position from others',
                    icon: Icons.visibility_off_rounded,
                    iconColor: const Color(0xFF9B59B6),
                    value: _ghostMode,
                    onChanged: (v) => setState(() => _ghostMode = v),
                  ),
                  _divider(),
                  _toggleTile(
                    title: 'Hide Username',
                    subtitle: 'Prevent others from seeing your display name',
                    icon: Icons.person_off_rounded,
                    iconColor: const Color(0xFF007AFF),
                    value: _hideUsername,
                    onChanged: (v) => setState(() => _hideUsername = v),
                  ),
                  _divider(),
                  _toggleTile(
                    title: 'Auto Share Location',
                    subtitle: 'Share location during active incidents',
                    icon: Icons.share_location_rounded,
                    iconColor: AppTheme.maroonGlow,
                    value: _autoShareLocation,
                    onChanged: (v) => setState(() => _autoShareLocation = v),
                  ),
                ]),
                const SizedBox(height: 20),

                // Account section
                _sectionHeader('ACCOUNT'),
                const SizedBox(height: 10),
                _glassSection([
                  _actionTile(
                    'Change Number',
                    Icons.phone_android_rounded,
                    Colors.white70,
                  ),
                  _divider(),
                  _actionTile(
                    'Change Password',
                    Icons.lock_reset_rounded,
                    Colors.white70,
                  ),
                  _divider(),
                  _actionTile(
                    'Help & Support',
                    Icons.help_outline_rounded,
                    AppTheme.maroonGlow,
                  ),
                  _divider(),
                  _actionTile(
                    'About MyBahaya',
                    Icons.info_outline_rounded,
                    Colors.white70,
                  ),
                ]),
                const SizedBox(height: 20),

                // History button
                _buildHistoryButton(),
                const SizedBox(height: 12),

                // Logout button
                _buildLogoutButton(),

                // IMPORTANT EXTRA SPACE:
                // This stops your items from getting stuck behind the glass navigation bar panel!
                SizedBox(height: absoluteBottomPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.4),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      color: Colors.white.withOpacity(0.05),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.maroonLight, AppTheme.maroonPrimary],
                  ),
                  border: Border.all(
                    color: AppTheme.maroonGlow.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.maroonGlow.withOpacity(0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.maroonLight,
                    border: Border.all(
                      color: AppTheme.backgroundDeep,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bro Kirk',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'p.........@gmail.com',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.alertGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.alertGreen.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.alertGreen,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Verified Reporter',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.alertGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassSection(List<Widget> children) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    color: Colors.white.withOpacity(0.05),
    child: Column(children: children),
  );

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Padding(
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
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
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

  Widget _actionTile(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
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

  Widget _divider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: Colors.white.withOpacity(0.06),
  );

  Widget _buildHistoryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_rounded,
                  color: Colors.white.withOpacity(0.6),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'VIEW ALL HISTORY',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.alertRed.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.alertRed.withOpacity(0.25)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout_rounded, color: AppTheme.alertRed, size: 18),
                const SizedBox(width: 8),
                Text(
                  'LOGOUT',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.alertRed,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
