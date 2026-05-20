import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_bar.dart';

class LiveAlertsScreen extends StatefulWidget {
  const LiveAlertsScreen({super.key});

  @override
  State<LiveAlertsScreen> createState() => _LiveAlertsScreenState();
}

class _LiveAlertsScreenState extends State<LiveAlertsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody: true,
      appBar: MyBahayaAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(title: 'Live Alerts'),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildAlertCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Filter by location...',
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.3),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.4),
            size: 20,
          ),
          suffixIcon: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 18,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCards() {
    final alerts = [
      _AlertData(
        title: 'Suspicious Activity',
        time: '2 minutes ago',
        description: 'An individual was seen loitering around the vicinity of Block C. Authorities have been notified.',
        borderColor: const Color(0xFFFF3B30),
        icon: Icons.cancel_outlined,
        iconColor: const Color(0xFFFF3B30),
        bgColor: const Color(0xFFFF3B30).withOpacity(0.06),
      ),
      _AlertData(
        title: 'Clearance Report',
        time: '40 minutes ago',
        description: 'All danger zones have been cleared by emergency response units. Area is now safe for public access.',
        borderColor: const Color(0xFF34C759),
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF34C759),
        bgColor: const Color(0xFF34C759).withOpacity(0.06),
      ),
      _AlertData(
        title: 'Car Accident',
        time: '12 minutes ago',
        description: 'Two-vehicle collision reported on Jalan Utama. Traffic is delayed in both directions.',
        borderColor: const Color(0xFFFFCC00),
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFFCC00),
        bgColor: const Color(0xFFFFCC00).withOpacity(0.06),
      ),
    ];

    return Column(
      children: [
        // First set
        ...alerts.map((alert) => _alertCard(alert: alert)),
        const SizedBox(height: 12),
        // Second set (duplicated)
        ...alerts.map((alert) => _alertCard(alert: alert)),
      ],
    );
  }

  Widget _alertCard({required _AlertData alert}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: alert.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: alert.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: alert.iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: alert.iconColor.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      alert.icon,
                      color: alert.iconColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    alert.time,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                alert.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertData {
  final String title;
  final String time;
  final String description;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  _AlertData({
    required this.title,
    required this.time,
    required this.description,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}