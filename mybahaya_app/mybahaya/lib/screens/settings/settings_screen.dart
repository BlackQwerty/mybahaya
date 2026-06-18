import 'package:flutter/material.dart';
import 'package:mybahaya/widgets/app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../../widgets/app_header.dart';
import '../../services/user_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification toggles
  bool _emergencyAlerts = true;
  bool _safeZoneEntry   = true;
  bool _ghostMode       = false;
  bool _hideUsername    = false;

  // Alert radius
  double _alertRadius = 5;

  // Language
  bool _isBM = false;

  // Emergency profile
  String _bloodType  = '';
  String _allergies  = '';
  String _iceName    = '';
  String _icePhone   = '';

  final _allergiesCtrl = TextEditingController();
  final _iceNameCtrl   = TextEditingController();
  final _icePhoneCtrl  = TextEditingController();

  static const Color nude     = Color(0xFFACA494);
  static const Color pink = Colors.white;
  static const Color burgundy = Color(0xFFB22222);

  static const _bloodTypes = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    _iceNameCtrl.dispose();
    _icePhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _alertRadius  = (prefs.getDouble('alert_radius') ?? 5).clamp(1, 50);
      _isBM         = prefs.getBool('lang_bm') ?? false;
      _bloodType    = prefs.getString('em_blood')    ?? '';
      _allergies    = prefs.getString('em_allergies') ?? '';
      _iceName      = prefs.getString('em_ice_name')  ?? '';
      _icePhone     = prefs.getString('em_ice_phone') ?? '';
    });
    _allergiesCtrl.text = _allergies;
    _iceNameCtrl.text   = _iceName;
    _icePhoneCtrl.text  = _icePhone;
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('alert_radius', _alertRadius);
    await prefs.setBool('lang_bm', _isBM);
    await prefs.setString('em_blood',      _bloodType);
    await prefs.setString('em_allergies',  _allergiesCtrl.text.trim());
    await prefs.setString('em_ice_name',   _iceNameCtrl.text.trim());
    await prefs.setString('em_ice_phone',  _icePhoneCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBM ? 'Profil kecemasan disimpan.' : 'Emergency profile saved.',
            style: TextStyle(),
          ),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody: true,
      appBar: const MyBahayaAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeader(title: _isBM ? 'Tetapan' : 'Settings'),
            const SizedBox(height: 32),

            // ── 1. Profile ─────────────────────────────────────
            _sectionHeader(Icons.person_outline_rounded,
                _isBM ? 'Edit Profil' : 'Edit Profile'),
            const SizedBox(height: 12),
            _buildProfileCard(),
            const SizedBox(height: 28),

            // ── 2. My Contribution ──────────────────────────────
            _sectionHeader(Icons.emoji_events_rounded,
                _isBM ? 'Sumbangan Saya' : 'My Contribution'),
            const SizedBox(height: 12),
            _buildContributionCard(),
            const SizedBox(height: 28),

            // ── 3. Emergency Profile ────────────────────────────
            _sectionHeader(Icons.favorite_border_rounded,
                _isBM ? 'Profil Kecemasan' : 'Emergency Profile'),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                _isBM
                    ? 'Maklumat ini membantu responder pertolongan cemas.'
                    : 'This info helps first responders if you are in an incident.',
                style: TextStyle(
                    fontSize: 11, color: nude.withOpacity(0.55)),
              ),
            ),
            _buildEmergencyProfile(),
            const SizedBox(height: 28),

            // ── 4. Alert Radius ─────────────────────────────────
            _sectionHeader(Icons.radar_rounded,
                _isBM ? 'Radius Amaran' : 'Alert Radius'),
            const SizedBox(height: 12),
            _buildAlertRadiusCard(),
            const SizedBox(height: 28),

            // ── 5. Notifications ────────────────────────────────
            _sectionHeader(Icons.notifications_none_rounded,
                _isBM ? 'Pemberitahuan' : 'Notifications'),
            const SizedBox(height: 12),
            _buildCard(Column(children: [
              _toggleRow(
                _isBM ? 'Amaran Kecemasan' : 'Emergency Alerts',
                _isBM ? 'Pemberitahuan bahaya berdekatan' : 'Critical danger proximity notifications',
                _emergencyAlerts,
                (v) => setState(() => _emergencyAlerts = v),
              ),
              _divider(),
              _toggleRow(
                _isBM ? 'Masuk Zon Selamat' : 'Safe-Zone Entry',
                _isBM ? 'Bunyi apabila masuk zon selamat' : 'Chime when entering verified safe zones',
                _safeZoneEntry,
                (v) => setState(() => _safeZoneEntry = v),
              ),
            ])),
            const SizedBox(height: 28),

            // ── 6. Language ──────────────────────────────────────
            _sectionHeader(Icons.language_rounded,
                _isBM ? 'Bahasa' : 'Language'),
            const SizedBox(height: 12),
            _buildLanguageCard(),
            const SizedBox(height: 28),

            // ── 7. Privacy ──────────────────────────────────────
            _sectionHeader(Icons.security_rounded,
                _isBM ? 'Privasi' : 'Privacy'),
            const SizedBox(height: 12),
            _buildCard(Column(children: [
              _toggleRow(
                _isBM ? 'Mod Hantu' : 'Ghost Mode',
                _isBM ? 'Sembunyikan kedudukan sebenar anda' : 'Hide your real-time position from others',
                _ghostMode,
                (v) => setState(() => _ghostMode = v),
              ),
              _divider(),
              _toggleRow(
                _isBM ? 'Sembunyikan Nama Pengguna' : 'Hide Username',
                _isBM ? 'Sembunyikan nama pengguna anda' : 'Hides your username from others',
                _hideUsername,
                (v) => setState(() => _hideUsername = v),
              ),
            ])),
            const SizedBox(height: 28),

            // ── 8. Log Out ──────────────────────────────────────
            _buildCard(_actionRow(
              _isBM ? 'Log Keluar' : 'Log Out',
              Icons.logout_rounded,
              pink,
              _confirmLogout,
            )),
          ],
        ),
      ),
    );
  }

  // ── Section header ───────────────────────────────────────────────────────
  Widget _sectionHeader(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: pink, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: nude,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF422E2E).withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }

  // ── Profile card ─────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return StreamBuilder<UserProfile?>(
      stream: UserService.profileStream(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final username = profile?.username ?? '—';
        final email    = profile?.email    ?? '—';
        final photoUrl = profile?.photoUrl;

        return _buildCard(ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F4C81).withOpacity(0.2),
              border: Border.all(color: pink.withOpacity(0.3), width: 1.5),
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: pink),
                      ),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.person_rounded, color: pink, size: 28),
                    )
                  : Image.asset('assets/images/logos/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person_rounded, color: pink, size: 28)),
            ),
          ),
          title: Text(username,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: pink)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(email,
                style: TextStyle(
                    fontSize: 12, color: pink.withOpacity(0.7))),
          ),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: Colors.white54, size: 24),
          onTap: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
            if (mounted) setState(() {});
          },
        ));
      },
    );
  }

  // ── Contribution card ────────────────────────────────────────────────────
  Widget _buildContributionCard() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        String badgeName;
        String badgeEmoji;
        Color badgeColor;
        String nextGoal;

        if (count >= 20) {
          badgeName  = _isBM ? 'Penjaga Negara' : 'Guardian of the Nation';
          badgeEmoji = '🥇';
          badgeColor = const Color(0xFFFFD700);
          nextGoal   = _isBM ? 'Tahap tertinggi — Tahniah!' : 'Highest tier — Congratulations!';
        } else if (count >= 5) {
          badgeName  = _isBM ? 'Wira Komuniti' : 'Community Hero';
          badgeEmoji = '🥈';
          badgeColor = const Color(0xFFB0C4DE);
          nextGoal   = _isBM
              ? '${20 - count} laporan lagi untuk Penjaga Negara'
              : '${20 - count} more reports to reach Guardian';
        } else {
          badgeName  = _isBM ? 'Pemerhati' : 'Observer';
          badgeEmoji = '🥉';
          badgeColor = const Color(0xFFCD7F32);
          nextGoal   = count == 0
              ? (_isBM ? 'Buat laporan pertama anda!' : 'Submit your first report!')
              : (_isBM
                  ? '${5 - count} laporan lagi untuk Wira Komuniti'
                  : '${5 - count} more to reach Community Hero');
        }

        return _buildCard(
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Badge circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor.withOpacity(0.15),
                    border: Border.all(color: badgeColor.withOpacity(0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(badgeEmoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badgeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isBM
                            ? '$count laporan dikemukakan'
                            : '$count report${count == 1 ? '' : 's'} submitted',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        nextGoal,
                        style: TextStyle(
                          fontSize: 10,
                          color: nude.withOpacity(0.55),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Emergency profile ────────────────────────────────────────────────────
  Widget _buildEmergencyProfile() {
    return _buildCard(
      Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blood type selector
            Text(
              _isBM ? 'Kumpulan Darah' : 'Blood Type',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: nude),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bloodTypes.map((bt) {
                final sel = _bloodType == bt;
                return GestureDetector(
                  onTap: () => setState(() => _bloodType = bt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 50,
                    height: 36,
                    decoration: BoxDecoration(
                      color: sel ? burgundy : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      bt,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : nude,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            _divider(),
            const SizedBox(height: 18),

            // Allergies
            _profileField(
              label: _isBM ? 'Alahan' : 'Allergies',
              hint: _isBM
                  ? 'cth. Penicillin, kacang...'
                  : 'e.g. Penicillin, peanuts...',
              controller: _allergiesCtrl,
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 14),

            // ICE contact
            _profileField(
              label: _isBM ? 'Hubungi Dalam Kecemasan (Nama)' : 'ICE Contact Name',
              hint: _isBM ? 'Nama ahli keluarga...' : 'Family member name...',
              controller: _iceNameCtrl,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            _profileField(
              label: _isBM ? 'No. Telefon ICE' : 'ICE Phone Number',
              hint: '+60 12-345 6789',
              controller: _icePhoneCtrl,
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 18),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _savePrefs,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _isBM ? 'Simpan Profil' : 'Save Profile',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: burgundy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: pink.withOpacity(0.6), size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: nude),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  fontSize: 12, color: nude.withOpacity(0.35)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  // ── Alert radius ─────────────────────────────────────────────────────────
  Widget _buildAlertRadiusCard() {
    return _buildCard(
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _isBM ? 'Terima amaran dalam ' : 'Alert me within ',
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withOpacity(0.7)),
                ),
                Text(
                  '${_alertRadius.round()} km',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _isBM
                  ? 'Semua laporan dalam radius ini akan dipaparkan di halaman utama.'
                  : 'All reports within this radius appear in your home feed.',
              style: TextStyle(
                  fontSize: 11, color: nude.withOpacity(0.5)),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: burgundy,
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                thumbColor: Colors.white,
                overlayColor: burgundy.withOpacity(0.2),
                trackHeight: 3,
              ),
              child: Slider(
                value: _alertRadius,
                min: 1,
                max: 50,
                divisions: 49,
                onChanged: (v) => setState(() => _alertRadius = v),
                onChangeEnd: (_) => _savePrefs(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 km',
                    style: TextStyle(
                        fontSize: 10, color: nude.withOpacity(0.4))),
                Text('50 km',
                    style: TextStyle(
                        fontSize: 10, color: nude.withOpacity(0.4))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Language card ─────────────────────────────────────────────────────────
  Widget _buildLanguageCard() {
    return _buildCard(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isBM ? 'Bahasa / Language' : 'Language / Bahasa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: pink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _isBM ? 'Bahasa Melayu dipilih' : 'English selected',
                    style: TextStyle(
                        fontSize: 11, color: nude.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            // EN / BM toggle pill
            GestureDetector(
              onTap: () async {
                setState(() => _isBM = !_isBM);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('lang_bm', _isBM);
              },
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _langPill('EN', !_isBM),
                    _langPill('BM', _isBM),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _langPill(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        color: active ? burgundy : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : nude,
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _toggleRow(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: pink)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: nude.withOpacity(0.65),
                        height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value
                    ? burgundy.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.85), width: 1.5),
              ),
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white.withOpacity(0.06),
      );

  Widget _actionRow(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Icon(icon, color: color, size: 20),
      title: Text(title,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: color.withOpacity(0.5), size: 20),
      onTap: onTap,
    );
  }

  Future<void> _confirmLogout() async {
    final label = _isBM ? 'Log Keluar' : 'Log Out';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label,
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          _isBM
              ? 'Adakah anda pasti mahu log keluar?'
              : 'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isBM ? 'Batal' : 'Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(label,
                style: TextStyle(
                    color: pink, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }
}
