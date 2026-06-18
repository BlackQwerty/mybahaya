import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Theme color tokens
  static const Color nudeColor = Color(0xFFACA494);
  static const Color pinkColor = Colors.white;

  late TextEditingController _usernameController;
  late TextEditingController _phoneController;

  UserProfile? _profile;
  File? _pickedImage;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserService.fetchProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _usernameController.text = profile?.username ?? '';
          _phoneController.text = profile?.phone ?? '';
        });
      }
    } catch (_) {
      // Ensure screen is never left on infinite spinner
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Pick image from gallery or camera ──
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() {
        _pickedImage = File(picked.path);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not pick image.');
      }
    }
  }

  // ── Show bottom sheet to choose camera or gallery ──
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: pinkColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _sheetButton(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _sheetButton(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF422E2E).withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: pinkColor, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save all changes ──
  Future<void> _saveChanges() async {
    final newUsername = _usernameController.text.trim();
    final newPhone = _phoneController.text.trim();

    if (newUsername.isEmpty) {
      setState(() => _errorMessage = 'Username cannot be empty.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Upload image if a new one was picked
      if (_pickedImage != null) {
        await UserService.uploadProfileImage(_pickedImage!);
      }

      // Update username if changed
      if (newUsername != (_profile?.username ?? '')) {
        await UserService.updateUsername(newUsername);
      }

      // Update phone if changed
      if (newPhone != (_profile?.phone ?? '')) {
        await UserService.updatePhone(newPhone);
      }

      // Reload profile to reflect updates
      await _loadProfile();
      setState(() => _pickedImage = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF422E2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save changes. Try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Change phone dialog ──
  Future<void> _showChangePhoneDialog() async {
    final tempController = TextEditingController(text: _phoneController.text);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Change Phone Number',
          style: TextStyle(
            color: pinkColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: tempController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: '01123456789',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: nudeColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _phoneController.text = tempController.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Update',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    tempController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      appBar: const MyBahayaAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB22222),
                strokeWidth: 2.5,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Navigation Bar (Settings Back & Done) ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chevron_left_rounded,
                                color: nudeColor,
                                size: 24,
                              ),
                              Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: nudeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _isSaving ? null : _saveChanges,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: nudeColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Done',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: nudeColor,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Screen Title ──
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: nudeColor,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Main Card Container (avatar + username) ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF422E2E).withOpacity(0.55),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          // ── Avatar with Camera overlay ──
                          GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors.white.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _buildAvatarImage(),
                                  ),
                                ),
                                // Camera overlay
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.38),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // ── Username Edit field ──
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _usernameController,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: pinkColor,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 6),
                                          hintText: 'Enter username',
                                          hintStyle: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white38,
                                          ),
                                          border: const UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white30,
                                                width: 1),
                                          ),
                                          enabledBorder:
                                              const UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white30,
                                                width: 1),
                                          ),
                                          focusedBorder:
                                              const UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: pinkColor,
                                                width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.edit_rounded,
                                      color: pinkColor,
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Email display (read-only)
                                Text(
                                  _profile?.email ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Card description subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Tap the photo to change it. Edit your username above.',
                        style: TextStyle(
                          fontSize: 11,
                          color: nudeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Change Number Card ──
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF422E2E).withOpacity(0.55),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        title: Text(
                          'Change number',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: pinkColor,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _phoneController.text.isNotEmpty
                                  ? _phoneController.text
                                  : '—',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: pinkColor,
                              size: 20,
                            ),
                          ],
                        ),
                        onTap: _showChangePhoneDialog,
                      ),
                    ),

                    // ── Error Message ──
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFB22222),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),

                    // ── View All History Button ──
                    Center(
                      child: SizedBox(
                        width: 220,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF422E2E),
                            foregroundColor: nudeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'VIEW ALL HISTORY',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 120), // Spacing push

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF422E2E),
                          foregroundColor: const Color(0xFFB22222),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'LOG OUT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFB22222),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFB22222),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Builds the correct avatar widget depending on whether a new image was
  /// picked locally, a remote URL exists, or neither.
  Widget _buildAvatarImage() {
    // 1. Locally picked image (not yet uploaded)
    if (_pickedImage != null) {
      return Image.file(
        _pickedImage!,
        fit: BoxFit.cover,
        width: 72,
        height: 72,
      );
    }

    // 2. Remote URL stored in Firestore
    final photoUrl = _profile?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        width: 72,
        height: 72,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: pinkColor,
          ),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.person_rounded,
          color: Colors.white60,
          size: 36,
        ),
      );
    }

    // 3. Fallback to app logo or person icon
    return Image.asset(
      'assets/images/logos/logo.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.person_rounded,
          color: Colors.white60,
          size: 36,
        );
      },
    );
  }
}
