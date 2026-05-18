import 'package:flutter/material.dart';
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

  final List<Widget> _screens = [
    const HomeDashboard(),
    const MapScreen(),
    const ReportScreen(),
    const LiveAlertsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF341515),
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: MyBahayaNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
