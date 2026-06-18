import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/main_layout.dart';

class MyBahayaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyBahayaAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF4D0A18),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // Logo + title — tap goes to home tab
            GestureDetector(
              onTap: () =>
                  context.findAncestorStateOfType<MainLayoutState>()?.goToHome(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logos/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1A0A0A),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            CupertinoIcons.shield,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'MyBahaya',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFACA494),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // User avatar → profile screen
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: const Icon(
                  CupertinoIcons.person_fill,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
