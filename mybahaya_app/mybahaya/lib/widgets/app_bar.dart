import 'package:flutter/material.dart';
import '../screens/profile/profile_screen.dart';

class MyBahayaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyBahayaAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF4D0A18), // Your custom header maroon
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logos/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1A0A0A),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 2. Consistent Title Typography
            Text(
              'MyBahaya',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(
                  0xFFACA494,
                ), // Your exact requested text color
              ),
            ),
            const Spacer(),

            // 3. User Avatar Action
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This tells the Scaffold exactly how much vertical space to reserve at the top
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
