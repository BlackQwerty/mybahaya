import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_bar.dart';
import 'my_reports_screen.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  final VoidCallback? onReportSuccess;

  const ReportScreen({super.key, this.onReportSuccess});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? selectedCategory;
  final TextEditingController descriptionController = TextEditingController();

  static const int maxPhotos = 3;
  final List<File> _selectedImages = [];

  // Videos are uploaded at original quality (no compression, no trimming) so
  // they play exactly like in the user's gallery. Instead, oversized videos are
  // rejected up front — the same approach used by WhatsApp, Telegram, etc.
  // Change this one number to adjust the cap.
  static const int maxVideoMB = 100;
  static const int _maxVideoBytes = maxVideoMB * 1024 * 1024;
  File? _selectedVideo;

  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;
  SubmitReportResult? _lastResult;

  // Unified color tokens
  static const Color nudeColor = Color(0xFFACA494);
  static const Color pinkColor = Colors.white;
  static const Color burgundyColor = Color(0xFFB22222);
  static const Color maroonColor = Color(0xFF341515);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
  }

  /* ── Media picking ───────────────────────────────────────── */

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= maxPhotos) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedImages.add(File(picked.path));
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickPhotosFromGallery() async {
    final remaining = maxPhotos - _selectedImages.length;
    if (remaining <= 0) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() {
        for (final x in picked.take(remaining)) {
          _selectedImages.add(File(x.path));
        }
        _errorMessage = null;
      });
    }
  }

  Future<void> _recordVideo() async {
    final picked = await ImagePicker().pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 15),
    );
    if (picked != null) await _acceptVideo(File(picked.path));
  }

  Future<void> _pickVideoFromGallery() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) await _acceptVideo(File(picked.path));
  }

  /// Accepts a video only if it's under the size cap; otherwise shows a clear
  /// message and rejects it (no broken/oversized uploads).
  Future<void> _acceptVideo(File file) async {
    final bytes = await file.length();
    if (bytes > _maxVideoBytes) {
      final mb = (bytes / (1024 * 1024)).round();
      if (!mounted) return;
      setState(() => _errorMessage =
          'Video is too large (${mb}MB). Please choose a video under ${maxVideoMB}MB.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _selectedVideo = file;
      _errorMessage = null;
    });
  }

  void _showPhotoSourceSheet() {
    if (_selectedImages.length >= maxPhotos) {
      setState(() => _errorMessage = 'You can attach up to $maxPhotos photos.');
      return;
    }
    _showSourceSheet(
      title: 'Add Photo',
      options: [
        _SheetOption(CupertinoIcons.camera_fill, 'Take Photo', _takePhoto),
        _SheetOption(CupertinoIcons.photo_on_rectangle, 'Choose from Gallery',
            _pickPhotosFromGallery),
      ],
    );
  }

  void _showVideoSourceSheet() {
    _showSourceSheet(
      title: 'Add Video (optional, max 15s)',
      options: [
        _SheetOption(CupertinoIcons.videocam_fill, 'Record Video', _recordVideo),
        _SheetOption(CupertinoIcons.film, 'Choose from Gallery',
            _pickVideoFromGallery),
      ],
    );
  }

  void _showSourceSheet({required String title, required List<_SheetOption> options}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1515),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            ...options.map((o) => ListTile(
                  leading: Icon(o.icon, color: burgundyColor),
                  title: Text(o.label,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15)),
                  onTap: () {
                    Navigator.pop(ctx);
                    o.onTap();
                  },
                )),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  /* ── Submit ──────────────────────────────────────────────── */

  Future<void> _submitReport() async {
    if (selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a hazard category');
      return;
    }
    if (_selectedImages.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one photo for evidence');
      return;
    }
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) {
        setState(() => _errorMessage =
            'Location is required. Please enable location permissions.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success = false;
    String errorMsg = '';
    String? newReportId;

    try {
      final result = await ApiService.submitReport(
        imageFiles: List<File>.from(_selectedImages),
        category: selectedCategory!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        details: descriptionController.text.trim(),
      );
      _lastResult = result;
      newReportId = result.reportId;
      success = true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    // Kick off the optional video upload in the BACKGROUND (do not await) so the
    // report itself is already recorded. A floating chip shows its progress.
    if (success && newReportId != null && _selectedVideo != null) {
      _startBackgroundVideoUpload(newReportId, _selectedVideo!);
    }

    await _showResultDialog(success: success, errorMsg: errorMsg);

    if (success && mounted) {
      setState(() {
        _selectedImages.clear();
        _selectedVideo = null;
        selectedCategory = null;
        _lastResult = null;
        descriptionController.clear();
      });
    }
  }

  /* ── Background video upload + floating progress chip ─────── */

  void _startBackgroundVideoUpload(String reportId, File videoFile) {
    final progress = ValueNotifier<double>(0);
    final status = ValueNotifier<String>('uploading'); // uploading | done | error
    final errorMsg = ValueNotifier<String>('');
    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) =>
          _VideoUploadChip(progress: progress, status: status, errorMsg: errorMsg),
    );
    overlay.insert(entry);

    ApiService.uploadVideo(
      reportId: reportId,
      videoFile: videoFile,
      onProgress: (p) => progress.value = p,
    ).then((_) {
      status.value = 'done';
    }).catchError((e) {
      errorMsg.value = e.toString().replaceFirst('Exception: ', '');
      status.value = 'error';
    }).whenComplete(() {
      // Errors linger longer so the user can read the reason.
      Future.delayed(Duration(seconds: status.value == 'error' ? 6 : 3), () {
        entry.remove();
        progress.dispose();
        status.dispose();
        errorMsg.dispose();
      });
    });
  }

  Future<void> _showResultDialog({
    required bool success,
    required String errorMsg,
  }) async {
    final result = _lastResult;
    final hasVideo = _selectedVideo != null;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1515),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: success
                      ? AppTheme.alertGreen.withOpacity(0.15)
                      : AppTheme.alertRed.withOpacity(0.15),
                  border: Border.all(
                    color: success
                        ? AppTheme.alertGreen.withOpacity(0.4)
                        : AppTheme.alertRed.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  success
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.xmark_circle_fill,
                  color: success ? AppTheme.alertGreen : AppTheme.alertRed,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                success ? 'Report Submitted!' : 'Submission Failed',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                success
                    ? (hasVideo
                        ? 'Your report has been received. Your video is uploading in the background.'
                        : 'Your report has been received. Authorities have been notified.')
                    : errorMsg.isNotEmpty
                        ? errorMsg
                        : 'Something went wrong. Please try again.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.65),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (success && result != null && result.assignedOrgName != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(CupertinoIcons.building_2_fill,
                              size: 14, color: AppTheme.alertGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.assignedOrgName!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (result.etaMinutes != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(CupertinoIcons.clock_fill,
                                size: 14, color: Colors.white54),
                            const SizedBox(width: 8),
                            Text(
                              'ETA: ~${result.etaMinutes} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              if (success) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onReportSuccess?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyReportsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: burgundyColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'View Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: burgundyColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
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
            const AppHeader(title: 'Report'),
            const SizedBox(height: 28),
            Row(
              children: [
                _buildLocationBadge(),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyReportsScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'My Reports',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildPhotoSection(),
            const SizedBox(height: 16),
            _buildVideoSection(),
            const SizedBox(height: 28),
            _buildFormInputs(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: AppTheme.alertRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 32),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBadge() {
    final hasLocation = _currentPosition != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.location_solid,
              color: maroonColor, size: 14),
          const SizedBox(width: 6),
          Text(
            hasLocation ? 'Current Location Active' : 'Locating...',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: maroonColor,
            ),
          ),
        ],
      ),
    );
  }

  /* ── Photo section: thumbnails + add tile (max 3) ────────── */

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PHOTOS',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: pinkColor,
                      letterSpacing: 0.5)),
              Text('${_selectedImages.length}/$maxPhotos',
                  style: TextStyle(fontSize: 12, color: nudeColor)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedImages.isEmpty)
          _buildEmptyMediaBox()
        else
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._selectedImages.asMap().entries.map(
                      (e) => _buildThumbnail(e.key, e.value),
                    ),
                if (_selectedImages.length < maxPhotos) _buildAddTile(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyMediaBox() {
    return GestureDetector(
      onTap: _showPhotoSourceSheet,
      child: Container(
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          color: nudeColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: maroonColor.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.camera_fill,
                  color: maroonColor, size: 30),
            ),
            const SizedBox(height: 14),
            const Text('Capture  or  Upload',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: maroonColor),
                textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text('MAKE IT CLEAR',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: maroonColor.withOpacity(0.55)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(int index, File file) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(file, width: 96, height: 96, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImages.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.xmark,
                    size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _showPhotoSourceSheet,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: nudeColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, color: maroonColor, size: 26),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(fontSize: 11, color: maroonColor)),
          ],
        ),
      ),
    );
  }

  /* ── Video section (optional) ────────────────────────────── */

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('VIDEO (OPTIONAL)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: pinkColor,
                  letterSpacing: 0.5)),
        ),
        const SizedBox(height: 10),
        if (_selectedVideo == null)
          GestureDetector(
            onTap: _showVideoSourceSheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: nudeColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.videocam_fill,
                      color: maroonColor, size: 20),
                  SizedBox(width: 10),
                  Text('Record  or  Upload short video ( 15s )',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: maroonColor)),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: nudeColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: maroonColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CupertinoIcons.play_fill,
                      color: maroonColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Video ready',
                          style: TextStyle(
                              color: maroonColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Will upload after you submit',
                          style: TextStyle(
                              color: maroonColor.withOpacity(0.7),
                              fontSize: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedVideo = null),
                  child: Icon(CupertinoIcons.xmark_circle_fill,
                      color: maroonColor.withOpacity(0.6), size: 22),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFormInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'WHAT HAPPENED?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: pinkColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: nudeColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: descriptionController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: maroonColor),
            cursorColor: maroonColor,
            decoration: InputDecoration(
              hintText: 'Describe the incident briefly ...',
              hintStyle:
                  TextStyle(fontSize: 13, color: maroonColor.withOpacity(0.5)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: pinkColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildCategoryChips(),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['Theft', 'Assault', 'Fire', 'Medical', 'Other'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((category) {
        final isSelected = selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              // Selected → nude fill. Unselected → translucent white pill
              // (same style as the "My Reports" button) with white text.
              color: isSelected ? nudeColor : Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? maroonColor : Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => FocusScope.of(context).unfocus(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.10),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitReport,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: maroonColor, strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                      size: 18, color: maroonColor),
              label: Text(
                _isLoading ? 'Submitting...' : 'Report Incident',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: maroonColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: nudeColor,
                foregroundColor: maroonColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ── Small helper types ────────────────────────────────────── */

class _SheetOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _SheetOption(this.icon, this.label, this.onTap);
}

/// Floating chip shown at the top of the app while a video uploads in the
/// background. Survives tab switches because it lives in the root overlay.
class _VideoUploadChip extends StatelessWidget {
  final ValueNotifier<double> progress;
  final ValueNotifier<String> status;
  final ValueNotifier<String> errorMsg;

  const _VideoUploadChip({
    required this.progress,
    required this.status,
    required this.errorMsg,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topInset + 8,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: ValueListenableBuilder<String>(
          valueListenable: status,
          builder: (context, st, _) {
            final bool done = st == 'done';
            final bool error = st == 'error';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1515),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    done
                        ? CupertinoIcons.checkmark_circle_fill
                        : error
                            ? CupertinoIcons.exclamationmark_circle_fill
                            : CupertinoIcons.cloud_upload_fill,
                    color: done
                        ? const Color(0xFF30D158)
                        : error
                            ? const Color(0xFFFF453A)
                            : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          done
                              ? 'Video uploaded'
                              : error
                                  ? 'Video upload failed'
                                  : 'Uploading video…',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        if (error) ...[
                          const SizedBox(height: 3),
                          ValueListenableBuilder<String>(
                            valueListenable: errorMsg,
                            builder: (context, msg, _) => Text(
                              msg.isEmpty ? 'Please try again.' : msg,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                  height: 1.3),
                            ),
                          ),
                        ],
                        if (!done && !error) ...[
                          const SizedBox(height: 6),
                          ValueListenableBuilder<double>(
                            valueListenable: progress,
                            builder: (context, p, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: p == 0 ? null : p,
                                minHeight: 5,
                                backgroundColor: Colors.white.withOpacity(0.12),
                                valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFB22222)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!done && !error) ...[
                    const SizedBox(width: 12),
                    ValueListenableBuilder<double>(
                      valueListenable: progress,
                      builder: (context, p, _) => Text(
                        '${(p * 100).clamp(0, 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
