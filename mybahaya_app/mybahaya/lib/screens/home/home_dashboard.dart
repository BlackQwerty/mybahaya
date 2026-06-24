import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_header.dart';
import '../../services/user_service.dart';
import '../../services/geocoding_service.dart';
import '../map/incident_map_screen.dart';

// Filter options for the home feed
enum _FeedFilter { nearby, state, malaysia }

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  _FeedFilter _filter = _FeedFilter.nearby;
  Position? _userPosition;
  String _userState = '';
  bool _locationLoading = true;

  static const Color nude     = Color(0xFFACA494);
  static const Color pink = Colors.white;
  static const Color burgundy = Color(0xFFB22222);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Phase 1 — GPS obtained: stop spinner immediately, show coordinates
      if (mounted) {
        setState(() {
          _userPosition    = pos;
          _locationLoading = false;
          // Show coordinates as fallback while geocoding runs
          _userState =
              '${pos.latitude.toStringAsFixed(2)}°N, ${pos.longitude.toStringAsFixed(2)}°E';
        });
      }

      // Phase 2 — geocode in background; doesn't block the UI
      final state = await GeocodingService.getState(
          pos.latitude, pos.longitude);
      if (mounted) setState(() => _userState = state);

      // Save location to Firestore so backend can find nearby users for geo-radius alerts
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        }).catchError((_) {});
      }

    } catch (_) {
      // Silently fall through — finally always runs
    } finally {
      if (mounted && _locationLoading) {
        setState(() => _locationLoading = false);
      }
    }
  }

  // Haversine formula — returns distance in km between two coordinates
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;

  // Apply the selected filter to a list of Firestore docs
  List<QueryDocumentSnapshot> _applyFilter(
      List<QueryDocumentSnapshot> docs) {
    switch (_filter) {
      case _FeedFilter.malaysia:
        return docs;

      case _FeedFilter.nearby:
        if (_userPosition == null) return docs;
        return docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final loc  = data['location'] as Map<String, dynamic>?;
          if (loc == null) return false;
          final lat = (loc['latitude']  as num?)?.toDouble() ?? 0;
          final lng = (loc['longitude'] as num?)?.toDouble() ?? 0;
          return _distanceKm(
                _userPosition!.latitude, _userPosition!.longitude,
                lat, lng) <= 5;
        }).toList();

      case _FeedFilter.state:
        // State filter is applied asynchronously — handled in StreamBuilder
        return docs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateLabel = _userState.isNotEmpty ? _userState : 'My State';

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
            // ── Greeting ──────────────────────────────────────────
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
            const SizedBox(height: 20),

            // ── Location chip ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.location_fill,
                      color: burgundy, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _locationLoading
                        ? 'Locating...'
                        : _userState.isNotEmpty
                            ? _userState
                            : 'Location unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: nude,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Filter Pills ──────────────────────────────────────
            Row(
              children: [
                _FilterPill(
                  label: 'Nearby',
                  icon: CupertinoIcons.location_fill,
                  isActive: _filter == _FeedFilter.nearby,
                  onTap: () => setState(() => _filter = _FeedFilter.nearby),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: stateLabel,
                  icon: CupertinoIcons.flag_fill,
                  isActive: _filter == _FeedFilter.state,
                  onTap: () => setState(() => _filter = _FeedFilter.state),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Malaysia',
                  icon: CupertinoIcons.globe,
                  isActive: _filter == _FeedFilter.malaysia,
                  onTap: () =>
                      setState(() => _filter = _FeedFilter.malaysia),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Feed ─────────────────────────────────────────────
            StreamBuilder<QuerySnapshot>(
              // Community feed reads the sanitized public feed (not locked reports).
              stream: FirebaseFirestore.instance
                  .collection('public_incidents')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeleton();
                }
                if (snapshot.hasError) {
                  return _buildEmpty(
                      'Could not load reports. Check your connection.');
                }

                final allDocs = snapshot.data?.docs ?? [];
                final filtered = _applyFilter(allDocs);

                if (filtered.isEmpty) {
                  return _buildEmpty(_emptyMessage());
                }

                return _FeedList(
                  docs: filtered,
                  userState: _userState,
                  filterMode: _filter,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _emptyMessage() {
    switch (_filter) {
      case _FeedFilter.nearby:
        return 'No incidents reported within 5 km of you.';
      case _FeedFilter.state:
        return 'No incidents reported in $_userState.';
      case _FeedFilter.malaysia:
        return 'No incidents reported yet.';
    }
  }

  Widget _buildEmpty(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(CupertinoIcons.shield,
                size: 52, color: nude.withOpacity(0.25)),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: nude.withOpacity(0.45)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 280,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

// ── Feed list — handles state filter async ────────────────────────────────
class _FeedList extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final String userState;
  final _FeedFilter filterMode;

  const _FeedList({
    required this.docs,
    required this.userState,
    required this.filterMode,
  });

  @override
  State<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<_FeedList> {
  List<QueryDocumentSnapshot> _stateDocs = [];
  bool _stateLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.filterMode == _FeedFilter.state) _filterByState();
  }

  @override
  void didUpdateWidget(_FeedList old) {
    super.didUpdateWidget(old);
    if (widget.filterMode == _FeedFilter.state &&
        (old.filterMode != _FeedFilter.state ||
            old.docs.length != widget.docs.length)) {
      _filterByState();
    }
  }

  Future<void> _filterByState() async {
    if (widget.userState.isEmpty) {
      setState(() => _stateDocs = widget.docs);
      return;
    }
    setState(() => _stateLoading = true);
    final results = <QueryDocumentSnapshot>[];
    for (final doc in widget.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final loc  = data['location'] as Map<String, dynamic>?;
      if (loc == null) continue;
      final lat = (loc['latitude']  as num?)?.toDouble() ?? 0;
      final lng = (loc['longitude'] as num?)?.toDouble() ?? 0;
      final state = await GeocodingService.getState(lat, lng);
      if (state == widget.userState) results.add(doc);
    }
    if (mounted) setState(() { _stateDocs = results; _stateLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filterMode == _FeedFilter.state) {
      if (_stateLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(
                color: Color(0xFFB22222), strokeWidth: 2),
          ),
        );
      }
      if (_stateDocs.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Center(
            child: Text(
              'No incidents reported in ${widget.userState}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFFACA494).withOpacity(0.45)),
            ),
          ),
        );
      }
      return _buildList(_stateDocs);
    }
    return _buildList(widget.docs);
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final data = docs[i].data() as Map<String, dynamic>;
        return _IncidentCard(data: data);
      },
    );
  }
}

// ── Single incident card ──────────────────────────────────────────────────
class _IncidentCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _IncidentCard({required this.data});

  @override
  State<_IncidentCard> createState() => _IncidentCardState();
}

class _IncidentCardState extends State<_IncidentCard> {
  String _placeName = 'Loading location...';

  static const Color nude     = Color(0xFFACA494);
  static const Color pink = Colors.white;
  static const Color burgundy = Color(0xFFB22222);

  @override
  void initState() {
    super.initState();
    _loadPlace();
  }

  Future<void> _loadPlace() async {
    final loc = widget.data['location'] as Map<String, dynamic>?;
    if (loc == null) return;
    final lat = (loc['latitude']  as num?)?.toDouble() ?? 0;
    final lng = (loc['longitude'] as num?)?.toDouble() ?? 0;
    final name = await GeocodingService.getPlaceName(lat, lng);
    if (mounted) setState(() => _placeName = name);
  }

  Color _catColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'fire':    return const Color(0xFFFF6B35);
      case 'theft':   return const Color(0xFF9B59B6);
      case 'assault': return const Color(0xFFE74C3C);
      case 'medical': return const Color(0xFF2ECC71);
      default:        return burgundy;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'fire':    return CupertinoIcons.flame_fill;
      case 'theft':   return CupertinoIcons.lock_open_fill;
      case 'assault': return CupertinoIcons.exclamationmark_circle_fill;
      case 'medical': return CupertinoIcons.plus_circle_fill;
      default:        return CupertinoIcons.exclamationmark_triangle_fill;
    }
  }

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else {
      return '';
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _verificationBadge(String? status) {
    if (status == 'VERIFIED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF30d158).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF30d158).withOpacity(0.3)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(CupertinoIcons.checkmark_shield_fill,
              color: Color(0xFF30d158), size: 11),
          SizedBox(width: 4),
          Text('VERIFIED', style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800,
              color: Color(0xFF30d158), letterSpacing: 0.4)),
        ]),
      );
    }
    if (status == 'REJECTED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(CupertinoIcons.xmark_shield_fill,
              color: Colors.redAccent, size: 11),
          SizedBox(width: 4),
          Text('FALSE ALARM', style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800,
              color: Colors.redAccent, letterSpacing: 0.4)),
        ]),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final category           = widget.data['category'] as String? ?? 'Unknown';
    final details            = widget.data['details']  as String? ?? '';
    final imageUrl           = widget.data['imageUrl'] as String? ?? '';
    final verificationStatus = widget.data['verificationStatus'] as String?;
    final catColor           = _catColor(category);

    return GestureDetector(
      onTap: () => _showDetailSheet(context),
      child: Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF422E2E).withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header badge ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1A1A).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'INCIDENT REPORT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _verificationBadge(verificationStatus),
                const Spacer(),
                Text(
                  _timeAgo(widget.data['createdAt']),
                  style: TextStyle(
                    fontSize: 11,
                    color: nude.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // ── Reported image ───────────────────────────────────
          if (imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180,
                    color: Colors.white.withOpacity(0.05),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: burgundy, strokeWidth: 1.5),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 100,
                    color: Colors.white.withOpacity(0.04),
                    child: Icon(CupertinoIcons.photo,
                        color: nude.withOpacity(0.3), size: 32),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Category + place name ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: catColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_catIcon(category),
                          color: catColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: catColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Place name
                Expanded(
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.location_fill,
                          color: pink.withOpacity(0.6), size: 12),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _placeName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: nude,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Details ──────────────────────────────────────────
          if (details.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                details,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.75),
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── View Details button ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              height: 38,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IncidentMapScreen(
                      report: widget.data,
                    ),
                  ),
                ),
                icon: const Icon(CupertinoIcons.map_fill,
                    color: Colors.white, size: 15),
                label: Text(
                  'View Details on Map',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF261212).withOpacity(0.8),
                  side: BorderSide(
                      color: Colors.white.withOpacity(0.12)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncidentDetailSheet(data: widget.data),
    );
  }
}

// ── Report detail bottom sheet ────────────────────────────────────────────
class _IncidentDetailSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  const _IncidentDetailSheet({required this.data});

  @override
  State<_IncidentDetailSheet> createState() => _IncidentDetailSheetState();
}

class _IncidentDetailSheetState extends State<_IncidentDetailSheet> {
  int _photoIndex = 0;
  String _placeName = 'Loading...';

  static const Color nude     = Color(0xFFACA494);
  static const Color burgundy = Color(0xFFB22222);

  @override
  void initState() {
    super.initState();
    _loadPlace();
  }

  Future<void> _loadPlace() async {
    final loc = widget.data['location'] as Map<String, dynamic>?;
    if (loc == null) return;
    final lat = (loc['latitude']  as num?)?.toDouble() ?? 0;
    final lng = (loc['longitude'] as num?)?.toDouble() ?? 0;
    final name = await GeocodingService.getPlaceName(lat, lng);
    if (mounted) setState(() => _placeName = name);
  }

  // Rewrite raw MinIO URLs to the HTTPS proxy (same as the web's safeImageUrl).
  String _safe(String url) =>
      url.replaceFirst('http://178.105.158.80:9000', 'https://api.mybahaya.com/minio');

  List<String> _photos() {
    final urls = widget.data['imageUrls'];
    if (urls is List && urls.isNotEmpty) {
      return urls.map((e) => _safe(e.toString())).toList();
    }
    final single = widget.data['imageUrl'] as String?;
    if (single != null && single.isNotEmpty) return [_safe(single)];
    return [];
  }

  String? _videoUrl() {
    final v = widget.data['videoUrl'] as String?;
    return (v != null && v.isNotEmpty) ? _safe(v) : null;
  }

  Future<void> _playVideo(String url) async {
    final uri = Uri.parse(url);
    // Don't gate on canLaunchUrl — it falsely returns false on Android 11+ when
    // the http/https intent isn't declared in <queries>. Just try to launch,
    // falling back to the in-app browser view, and surface any failure.
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the video.')),
        );
      }
    }
  }

  Color _catColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'fire':    return const Color(0xFFFF6B35);
      case 'theft':   return const Color(0xFF9B59B6);
      case 'assault': return const Color(0xFFE74C3C);
      case 'medical': return const Color(0xFF2ECC71);
      default:        return burgundy;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'fire':    return CupertinoIcons.flame_fill;
      case 'theft':   return CupertinoIcons.lock_open_fill;
      case 'assault': return CupertinoIcons.exclamationmark_circle_fill;
      case 'medical': return CupertinoIcons.plus_circle_fill;
      default:        return CupertinoIcons.exclamationmark_triangle_fill;
    }
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    final dt = ts is Timestamp ? ts.toDate() : null;
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final category           = widget.data['category'] as String? ?? 'Unknown';
    final details            = widget.data['details']  as String? ?? '';
    final verificationStatus = widget.data['verificationStatus'] as String?;
    final catColor           = _catColor(category);
    final photos             = _photos();
    final videoUrl           = _videoUrl();

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Color(0xFF1A0A0A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Photo gallery ──────────────────────────────
                  if (photos.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 220,
                        child: PageView.builder(
                          itemCount: photos.length,
                          onPageChanged: (i) => setState(() => _photoIndex = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: photos[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) => Container(
                              color: Colors.white.withOpacity(0.05),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFB22222), strokeWidth: 1.5)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white.withOpacity(0.04),
                              child: Icon(CupertinoIcons.photo,
                                  color: nude.withOpacity(0.3), size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (photos.length > 1) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(photos.length, (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _photoIndex == i ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _photoIndex == i
                                ? burgundy
                                : Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ],
                    const SizedBox(height: 18),
                  ],

                  // ── Video (opens in player) ────────────────────
                  if (videoUrl != null) ...[
                    GestureDetector(
                      onTap: () => _playVideo(videoUrl),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: burgundy.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: burgundy.withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.play_circle_fill,
                                color: burgundy, size: 22),
                            const SizedBox(width: 8),
                            const Text('Play Video',
                                style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── Badges row ─────────────────────────────────
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: catColor.withOpacity(0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_catIcon(category), color: catColor, size: 13),
                        const SizedBox(width: 5),
                        Text(category.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                                color: catColor, letterSpacing: 0.5)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    if (verificationStatus == 'VERIFIED')
                      _chip('VERIFIED', CupertinoIcons.checkmark_shield_fill,
                          const Color(0xFF30d158)),
                    if (verificationStatus == 'REJECTED')
                      _chip('FALSE ALARM', CupertinoIcons.xmark_shield_fill,
                          Colors.redAccent),
                    const Spacer(),
                    Text(_timeAgo(widget.data['createdAt']),
                        style: TextStyle(fontSize: 11, color: nude.withOpacity(0.5))),
                  ]),
                  const SizedBox(height: 16),

                  // ── Details ────────────────────────────────────
                  if (details.isNotEmpty) ...[
                    Text(details,
                        style: TextStyle(fontSize: 14,
                            color: Colors.white.withOpacity(0.85), height: 1.6)),
                    const SizedBox(height: 16),
                  ],

                  // ── Location ───────────────────────────────────
                  Row(children: [
                    Icon(CupertinoIcons.location_fill, color: burgundy, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_placeName,
                        style: TextStyle(fontSize: 13, color: nude))),
                  ]),
                  const SizedBox(height: 20),

                  // ── View on map button ─────────────────────────
                  SizedBox(
                    width: double.infinity, height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => IncidentMapScreen(report: widget.data)));
                      },
                      icon: const Icon(CupertinoIcons.map_fill,
                          color: Colors.white, size: 16),
                      label: const Text('View on Map',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF261212).withOpacity(0.8),
                        side: BorderSide(color: Colors.white.withOpacity(0.12)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
            color: color, letterSpacing: 0.4)),
      ]),
    );
  }
}

// ── Filter pill widget ────────────────────────────────────────────────────
class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFB22222)
              : const Color(0xFF422E2E).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : Colors.white.withOpacity(0.08),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFB22222).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isActive
                    ? Colors.white
                    : const Color(0xFFACA494)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : const Color(0xFFACA494),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
