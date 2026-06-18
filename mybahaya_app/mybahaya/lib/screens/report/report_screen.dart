import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
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

  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;

  // Unified color tokens
  static const Color nudeColor = Color(0xFFACA494);
  static const Color pinkColor = Color(0xFFFFABBB);
  static const Color burgundyColor = Color(0xFFB22222);

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitReport() async {
    if (selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a hazard category');
      return;
    }
    if (_selectedImage == null) {
      setState(() => _errorMessage = 'Please upload an image for evidence');
      return;
    }
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) {
        setState(() => _errorMessage = 'Location is required. Please enable location permissions.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success = false;
    String errorMsg = '';

    try {
      await ApiService.submitReport(
        imageFile: _selectedImage!,
        category: selectedCategory!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        details: descriptionController.text.trim(),
      );
      success = true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    // Show result dialog
    await _showResultDialog(success: success, errorMsg: errorMsg);

    // Reset form after dialog is dismissed
    if (success && mounted) {
      setState(() {
        _selectedImage = null;
        selectedCategory = null;
        descriptionController.clear();
      });
    }
  }

  Future<void> _showResultDialog({
    required bool success,
    required String errorMsg,
  }) async {
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
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
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
              // ── Status Icon ──
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
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: success ? AppTheme.alertGreen : AppTheme.alertRed,
                  size: 44,
                ),
              ),

              const SizedBox(height: 20),

              // ── Title ──
              Text(
                success ? 'Report Submitted!' : 'Submission Failed',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // ── Message ──
              Text(
                success
                    ? 'Your incident report has been successfully submitted. Authorities have been notified.'
                    : errorMsg.isNotEmpty
                        ? errorMsg
                        : 'Something went wrong. Please try again.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.65),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // ── Buttons ──
              if (success) ...[
                // Two buttons: OK and View Report
                Row(
                  children: [
                    // OK → go home
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onReportSuccess?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // View Report → open My Reports screen
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
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Single OK button on failure
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
                      style: GoogleFonts.inter(
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
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          130, // Clear the custom bottom nav bar
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(title: 'Report'),
            const SizedBox(height: 28),
            // ── Location badge + View Reports button ──
            Row(
              children: [
                _buildLocationBadge(),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyReportsScreen(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.history_rounded,
                    size: 15,
                    color: Color(0xFFFFABBB),
                  ),
                  label: Text(
                    'View Reports',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFABBB),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF422E2E).withOpacity(0.55),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMediaUpload(),
            const SizedBox(height: 28),
            _buildFormInputs(),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF422E2E).withOpacity(0.55),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasLocation ? Icons.location_on_rounded : Icons.location_searching_rounded,
            color: hasLocation ? Colors.greenAccent : nudeColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            hasLocation ? 'Current Location Active' : 'Locating...',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: nudeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: _selectedImage != null
                ? Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        color: pinkColor.withOpacity(0.8),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Capture or Upload Media',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supports JPEG, PNG up to 50MB',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: nudeColor.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
      ),
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
            style: GoogleFonts.playfairDisplay(
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
            color: const Color(0xFF422E2E).withOpacity(0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: TextField(
            controller: descriptionController,
            maxLines: 4,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Provide detailed details on location, hazards, or safety threats...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: nudeColor.withOpacity(0.4),
              ),
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
            'SELECT HAZARD CATEGORY',
            style: GoogleFonts.playfairDisplay(
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
              color: isSelected 
                  ? burgundyColor 
                  : const Color(0xFF422E2E).withOpacity(0.55),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: Text(
              category,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : nudeColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Two-button row: Cancel (dismiss keyboard) + Report Incident
  Widget _buildBottomButtons() {
    return Row(
      children: [
        // Cancel — dismisses keyboard, stays on page
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => FocusScope.of(context).unfocus(),
              icon: const Icon(Icons.keyboard_hide_rounded,
                  size: 18, color: Colors.white54),
              label: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Report Incident — dark charcoal, not red
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
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.warning_amber_rounded,
                      size: 18, color: Colors.white),
              label: Text(
                _isLoading ? 'Submitting...' : 'Report Incident',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A1010),
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: Colors.white.withOpacity(0.15)),
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