import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  // Notifications
  bool _emergencyAlerts = true;
  bool _safeZoneEntry   = true;

  // Privacy
  bool _anonymousReports = false;

  // Alert radius
  double _alertRadius = 5;

  // Medical info
  String _bloodType = '';
  final _allergiesCtrl = TextEditingController();

  // Emergency contacts (max 3)
  List<Map<String, String>> _contacts = [];
  // null=viewing, -1=adding new, 0/1/2=editing that index
  int? _editingIndex;
  final _editNameCtrl  = TextEditingController();
  final _editPhoneCtrl = TextEditingController();

  static const Color nude     = Color(0xFFACA494);
  static const Color burgundy = Color(0xFFB22222);
  static const Color _green   = Color(0xFF34C759);

  static const _bloodTypes = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    _editNameCtrl.dispose();
    _editPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Load contacts (migrate old single-ICE format if needed)
    final count = prefs.getInt('em_contacts_count') ?? -1;
    final contacts = <Map<String, String>>[];

    if (count >= 0) {
      for (int i = 0; i < count && i < 3; i++) {
        contacts.add({
          'name':  prefs.getString('em_contact_${i}_name')  ?? '',
          'phone': prefs.getString('em_contact_${i}_phone') ?? '',
        });
      }
    } else {
      // migrate legacy single ICE contact
      final oldName  = prefs.getString('em_ice_name')  ?? '';
      final oldPhone = prefs.getString('em_ice_phone') ?? '';
      if (oldName.isNotEmpty || oldPhone.isNotEmpty) {
        contacts.add({'name': oldName, 'phone': oldPhone});
      }
    }

    setState(() {
      _alertRadius      = (prefs.getDouble('alert_radius') ?? 5).clamp(1, 50);
      _emergencyAlerts  = prefs.getBool('notif_emergency') ?? true;
      _safeZoneEntry    = prefs.getBool('notif_safezone')  ?? true;
      _anonymousReports = prefs.getBool('priv_anon') ?? false;
      _bloodType        = prefs.getString('em_blood')      ?? '';
      _contacts         = contacts;
    });
    _allergiesCtrl.text = prefs.getString('em_allergies') ?? '';
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveMedical() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('em_blood',     _bloodType);
    await prefs.setString('em_allergies', _allergiesCtrl.text.trim());
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Medical info saved.'),
      backgroundColor: _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('em_contacts_count', _contacts.length);
    for (int i = 0; i < _contacts.length; i++) {
      await prefs.setString('em_contact_${i}_name',  _contacts[i]['name']!);
      await prefs.setString('em_contact_${i}_phone', _contacts[i]['phone']!);
    }
  }

  void _startEdit(int index) {
    final isNew = index == -1;
    setState(() {
      _editingIndex = index;
      _editNameCtrl.text  = isNew ? '' : _contacts[index]['name']!;
      _editPhoneCtrl.text = isNew ? '' : _contacts[index]['phone']!;
    });
  }

  Future<void> _commitEdit() async {
    final name  = _editNameCtrl.text.trim();
    final phone = _editPhoneCtrl.text.trim();
    if (name.isEmpty && phone.isEmpty) {
      _cancelEdit();
      return;
    }
    setState(() {
      if (_editingIndex == -1) {
        _contacts.add({'name': name, 'phone': phone});
      } else {
        _contacts[_editingIndex!] = {'name': name, 'phone': phone};
      }
      _editingIndex = null;
    });
    FocusScope.of(context).unfocus();
    await _saveContacts();
  }

  void _cancelEdit() {
    FocusScope.of(context).unfocus();
    setState(() => _editingIndex = null);
  }

  Future<void> _deleteContact(int index) async {
    setState(() {
      _contacts.removeAt(index);
      _editingIndex = null;
    });
    await _saveContacts();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
            const AppHeader(title: 'Settings'),
            const SizedBox(height: 32),

            // 1. Profile
            _sectionHeader(CupertinoIcons.person, 'Edit Profile'),
            const SizedBox(height: 12),
            _buildProfileCard(),
            const SizedBox(height: 28),

            // 2. Contribution
            _sectionHeader(CupertinoIcons.rosette, 'My Contribution'),
            const SizedBox(height: 12),
            _buildContributionCard(),
            const SizedBox(height: 28),

            // 3. Emergency Profile — medical
            _sectionHeader(CupertinoIcons.heart, 'Emergency Profile'),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Helps first responders if you are in an incident.',
                style: TextStyle(fontSize: 11, color: nude.withOpacity(0.55)),
              ),
            ),
            _buildMedicalCard(),
            const SizedBox(height: 16),

            // 3b. Emergency contacts
            _sectionHeader(CupertinoIcons.person_2, 'Emergency Contacts'),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Up to 3 contacts. Visible to responders accessing your profile.',
                style: TextStyle(fontSize: 11, color: nude.withOpacity(0.55)),
              ),
            ),
            _buildContactsCard(),
            const SizedBox(height: 28),

            // 4. Alert Radius
            _sectionHeader(CupertinoIcons.scope, 'Alert Radius'),
            const SizedBox(height: 12),
            _buildAlertRadiusCard(),
            const SizedBox(height: 28),

            // 5. Notifications
            _sectionHeader(CupertinoIcons.bell, 'Notifications'),
            const SizedBox(height: 12),
            _buildCard(Column(children: [
              _toggleRow(
                'Emergency Alerts',
                'Critical danger proximity notifications',
                _emergencyAlerts,
                (v) {
                  setState(() => _emergencyAlerts = v);
                  _saveBool('notif_emergency', v);
                },
              ),
              _divider(),
              _toggleRow(
                'Safe-Zone Entry',
                'Chime when entering a verified safe zone',
                _safeZoneEntry,
                (v) {
                  setState(() => _safeZoneEntry = v);
                  _saveBool('notif_safezone', v);
                },
              ),
            ])),
            const SizedBox(height: 28),

            // 6. Privacy
            _sectionHeader(CupertinoIcons.lock, 'Privacy'),
            const SizedBox(height: 12),
            _buildCard(Column(children: [
              _toggleRow(
                'Anonymous Reports',
                'Your username appears as "Community Member" on reports you submit',
                _anonymousReports,
                (v) {
                  setState(() => _anonymousReports = v);
                  _saveBool('priv_anon', v);
                },
              ),
            ])),
            const SizedBox(height: 28),

            // 7. Log Out
            _buildCard(_actionRow(
              'Log Out',
              CupertinoIcons.square_arrow_right,
              Colors.white,
              _confirmLogout,
            )),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: nude)),
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
        final profile  = snapshot.data;
        final username = profile?.username ?? '—';
        final email    = profile?.email    ?? '—';
        final photoUrl = profile?.photoUrl;
        return _buildCard(ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          leading: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F4C81).withOpacity(0.2),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl, fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white)),
                      errorWidget: (_, __, ___) =>
                          const Icon(CupertinoIcons.person_fill, color: Colors.white, size: 28),
                    )
                  : Image.asset('assets/images/logos/logo.png', fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(CupertinoIcons.person_fill, color: Colors.white, size: 28)),
            ),
          ),
          title: Text(username,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(email,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55))),
          ),
          trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.white54, size: 24),
          onTap: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
            if (mounted) setState(() {});
          },
        ));
      },
    );
  }

  // ── Contribution card ─────────────────────────────────────────────────────
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
        String badge; String emoji; Color color; String next;
        if (count >= 20) {
          badge = 'Guardian of the Nation'; emoji = '🥇';
          color = const Color(0xFFFFD700); next = 'Highest tier — Congratulations!';
        } else if (count >= 5) {
          badge = 'Community Hero'; emoji = '🥈';
          color = const Color(0xFFB0C4DE);
          next  = '${20 - count} more reports to reach Guardian';
        } else {
          badge = 'Observer'; emoji = '🥉';
          color = const Color(0xFFCD7F32);
          next  = count == 0 ? 'Submit your first report!'
                             : '${5 - count} more to reach Community Hero';
        }
        return _buildCard(Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(color: color.withOpacity(0.4), width: 2),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(badge, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 3),
              Text('$count report${count == 1 ? '' : 's'} submitted',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 6),
              Text(next, style: TextStyle(fontSize: 10, color: nude.withOpacity(0.55), height: 1.3)),
            ])),
          ]),
        ));
      },
    );
  }

  // ── Medical info card ─────────────────────────────────────────────────────
  Widget _buildMedicalCard() {
    return _buildCard(Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Blood type
        const Text('Blood Type',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: nude)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _bloodTypes.map((bt) {
            final sel = _bloodType == bt;
            return GestureDetector(
              onTap: () => setState(() => _bloodType = bt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 50, height: 36,
                decoration: BoxDecoration(
                  color: sel ? burgundy : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? Colors.transparent : Colors.white.withOpacity(0.1)),
                ),
                alignment: Alignment.center,
                child: Text(bt, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : nude,
                )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        _divider(),
        const SizedBox(height: 18),
        // Allergies
        _fieldLabel(CupertinoIcons.exclamationmark_triangle_fill, 'Allergies'),
        const SizedBox(height: 6),
        _textInput(_allergiesCtrl, 'e.g. Penicillin, peanuts...'),
        const SizedBox(height: 18),
        // Save medical
        SizedBox(
          width: double.infinity, height: 44,
          child: ElevatedButton.icon(
            onPressed: _saveMedical,
            icon: const Icon(CupertinoIcons.checkmark, size: 18),
            label: const Text('Save Medical Info',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: burgundy, foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    ));
  }

  // ── Emergency contacts card ───────────────────────────────────────────────
  Widget _buildContactsCard() {
    final isEditing = _editingIndex != null;
    return _buildCard(Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Existing contacts
        ..._contacts.asMap().entries.map((e) {
          final i    = e.key;
          final c    = e.value;
          final isMe = _editingIndex == i;

          if (isMe) {
            return _contactEditForm(i);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: burgundy.withOpacity(0.15),
                    border: Border.all(color: burgundy.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                          color: burgundy)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['name']!.isNotEmpty ? c['name']! : '—',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(c['phone']!.isNotEmpty ? c['phone']! : '—',
                      style: TextStyle(fontSize: 12, color: nude.withOpacity(0.7))),
                ])),
                // Edit / Delete buttons (only when not editing another)
                if (!isEditing) ...[
                  GestureDetector(
                    onTap: () => _startEdit(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Edit',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _deleteContact(i),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(CupertinoIcons.trash,
                          color: Colors.redAccent, size: 16),
                    ),
                  ),
                ],
              ]),
            ),
          );
        }),

        // Inline "add new" form
        if (_editingIndex == -1) _contactEditForm(-1),

        // Action buttons row
        if (!isEditing) ...[
          if (_contacts.length < 3)
            SizedBox(
              width: double.infinity, height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _startEdit(-1),
                icon: const Icon(CupertinoIcons.add, size: 18, color: Colors.white70),
                label: const Text('Add New Contact',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (_contacts.length >= 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Maximum 3 emergency contacts reached.',
                  style: TextStyle(fontSize: 11, color: nude.withOpacity(0.45))),
            ),
        ],
      ]),
    ));
  }

  Widget _contactEditForm(int index) {
    final isNew = index == -1;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isNew ? 'New Contact' : 'Edit Contact ${index + 1}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: Colors.white70)),
        const SizedBox(height: 10),
        _fieldLabel(CupertinoIcons.person, 'Name'),
        const SizedBox(height: 5),
        _textInput(_editNameCtrl, 'Family member name...'),
        const SizedBox(height: 10),
        _fieldLabel(CupertinoIcons.phone_fill, 'Phone Number'),
        const SizedBox(height: 5),
        _textInput(_editPhoneCtrl, '+60 12-345 6789',
            keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        // Cancel + Save row
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: _cancelEdit,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(fontSize: 13, color: Colors.white54)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _commitEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: burgundy, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Alert radius ──────────────────────────────────────────────────────────
  Widget _buildAlertRadiusCard() {
    return _buildCard(Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Alert me within ',
              style: TextStyle(fontSize: 13, color: Colors.white70)),
          Text('${_alertRadius.round()} km',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ]),
        const SizedBox(height: 4),
        Text('All reports within this radius appear in your home feed.',
            style: TextStyle(fontSize: 11, color: nude.withOpacity(0.5))),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: burgundy,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: Colors.white,
            overlayColor: burgundy.withOpacity(0.2),
            trackHeight: 3,
          ),
          child: Slider(
            value: _alertRadius, min: 1, max: 50, divisions: 49,
            onChanged: (v) => setState(() => _alertRadius = v),
            onChangeEnd: (v) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('alert_radius', v);
            },
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('1 km', style: TextStyle(fontSize: 10, color: nude.withOpacity(0.4))),
          Text('50 km', style: TextStyle(fontSize: 10, color: nude.withOpacity(0.4))),
        ]),
      ]),
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _fieldLabel(IconData icon, String label) {
    return Row(children: [
      Icon(icon, color: Colors.white.withOpacity(0.5), size: 14),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: nude)),
    ]);
  }

  Widget _textInput(TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: nude.withOpacity(0.35)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // iOS-style toggle
  Widget _iosToggle(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.5),
          color: value ? _green : Colors.white.withOpacity(0.22),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              width: 27, height: 27,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 6, offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleRow(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(
              fontSize: 11, color: nude.withOpacity(0.65), height: 1.3)),
        ])),
        const SizedBox(width: 14),
        _iosToggle(value, onChanged),
      ]),
    );
  }

  Widget _divider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    color: Colors.white.withOpacity(0.06),
  );

  Widget _actionRow(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Icon(icon, color: color, size: 20),
      title: Text(title, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      trailing: Icon(CupertinoIcons.chevron_right,
          color: color.withOpacity(0.5), size: 20),
      onTap: onTap,
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) await FirebaseAuth.instance.signOut();
  }
}
