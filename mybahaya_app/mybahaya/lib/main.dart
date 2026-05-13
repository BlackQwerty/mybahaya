import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LiquidGlassWidgets.initialize();
  runApp(
    LiquidGlassWidgets.wrap(
      const MyBahayaApp(),
      adaptiveQuality: true,
    ),
  );
}

class MyBahayaApp extends StatelessWidget {
  const MyBahayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyBahaya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const AppNavigator(),
    );
  }
}

/// Main navigator that controls the flow between all app screens
class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _currentScreen = 0; // 0-based index of current screen

  void _navigate(int index) => setState(() => _currentScreen = index);

  @override
  Widget build(BuildContext context) {
    // All screens in order: 0=Onboard1, 1=Onboard2, 2=Welcome, 3=Onboard3,
    // 4=Auth, 5=Home, 6=Alerts, 7=Map, 8=Report, 9=Settings
    final screens = [
      // Page 1 – Onboarding (fire)
      OnboardingScreen(
        title: 'There was a fire ?',
        buttonText: 'GET STARTED',
        pageIndex: 0,
        onPressed: () => _navigate(1),
      ),
      // Page 2 – Onboarding (accident)
      OnboardingScreen(
        title: 'Someone had an accident & need help?',
        buttonText: 'NEXT',
        pageIndex: 1,
        onPressed: () => _navigate(2),
      ),
      // Page 3 – Welcome
      WelcomeScreen(
        onSignIn: () => _navigate(4),
        onSignUp: () => _navigate(4),
      ),
      // Page 4 – Onboarding (danger)
      OnboardingScreen(
        title: 'See someone in danger ?',
        buttonText: 'NEXT',
        pageIndex: 2,
        onPressed: () => _navigate(4),
      ),
      // Auth (Sign In / Sign Up)
      AuthScreen(
        onSuccess: () => _navigate(5), // Navigate to HomeDashboard (index 5)
      ),
      // Main App Dashboard (Handles Map, Report, Home, Alerts, Settings)
      const MainLayout(),
    ];

    return GlassBackdropScope(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentScreen),
          child: screens[_currentScreen],
        ),
      ),
    );
  }
}
