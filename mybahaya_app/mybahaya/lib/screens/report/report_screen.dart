import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? selectedCategory;
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: 'Report'),
              const SizedBox(height: 20),
              _buildLocationBadge(),
              const SizedBox(height: 20),
              _buildMediaUpload(),
              const SizedBox(height: 20),
              _buildMediaUpload(),
              const SizedBox(height: 24),
              _buildFormInputs(),
              const SizedBox(height: 24),
              _buildReportButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF330000).withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: Colors.green,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Current Location',
            style: GoogleFonts.sourceSerif4(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaUpload() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0x80ACA494),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_rounded,
            color: Colors.white70,
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            'Capture or Upload',
            style: GoogleFonts.sourceSans3(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT HAPPENED?',
          style: GoogleFonts.sourceSans3(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x80ACA494),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: descriptionController,
            maxLines: 4,
            style: GoogleFonts.sourceSans3(
              fontSize: 14,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Describe the incident...',
              hintStyle: GoogleFonts.sourceSans3(
                fontSize: 14,
                color: Colors.white54,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'CATEGORY',
          style: GoogleFonts.sourceSans3(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF330000) : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.white38,
                width: 1,
              ),
            ),
            child: Text(
              category,
              style: GoogleFonts.sourceSans3(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF330000),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'REPORT NOW',
                  style: GoogleFonts.sourceSerif4(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
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