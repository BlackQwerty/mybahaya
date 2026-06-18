import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:glass_liquid_navbar/glass_liquid_navbar.dart';

class MyBahayaNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MyBahayaNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    //use padding instead of margin to ensure the glass effect doesnt clip akwardly against the screen edges
    // double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: LiquidGlassNavbar(
        currentIndex: currentIndex,
        onTap: onTap,
        isFullWidth: false,
        theme: LiquidGlassTheme(
          glassColor: const Color(0x80ACA494), // Main bar background
          indicatorColor: const Color(0xB3330000), // The "Liquid" bubble color
          glassBorderColor: const Color(0xFFB3AA9A), // The border color
          selectedColor: Colors.white, // Active icon color
          unselectedColor: Colors.white.withOpacity(0.5), // Inactive icon color
          horizontalPadding: 0.0,
          pillHeight: 64.0,
          borderRadius: 60.0,
        ),

        items: [
          LiquidNavItem(icon: CupertinoIcons.house_fill, label: 'HOME'),
          LiquidNavItem(icon: CupertinoIcons.map_fill, label: 'MAP'),
          LiquidNavItem(icon: CupertinoIcons.camera_fill, label: 'REPORT'),
          LiquidNavItem(icon: CupertinoIcons.bell_fill, label: 'ALERTS'),
          LiquidNavItem(icon: CupertinoIcons.gear, label: 'SETTINGS'),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}
