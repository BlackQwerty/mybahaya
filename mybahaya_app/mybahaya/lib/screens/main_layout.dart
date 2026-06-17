import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home/home_dashboard.dart';
import 'map/map_screen.dart';
import 'report/report_screen.dart';
import 'alerts/live_alerts_screen.dart';
import 'settings/settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _goToHome() => setState(() => _currentIndex = 0);

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeDashboard(),
      const MapScreen(),
      ReportScreen(onReportSuccess: _goToHome),
      const LiveAlertsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: MyBahayaNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
