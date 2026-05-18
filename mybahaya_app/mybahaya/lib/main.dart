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

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _currentScreen = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'There was a fire ?',
      'subtitle':
          'Instant alerts for fire incidents near you. Stay informed, stay safe.',
      'image': 'assets/images/onboarding/onb_fire.png',
    },
    {
      'title': 'Someone had an accident ?',
      'subtitle':
          'Report accidents instantly. Help reach those in need faster.',
      'image': 'assets/images/onboarding/onb_accident.png',
    },
    {
      'title': 'See someone in danger ?',
      'subtitle':
          'Your report could save lives. Be the eyes of your community.',
      'image': 'assets/images/onboarding/onb_danger.png',
    },
  ];

  void _navigate(int index) {
    if (index == _currentScreen) return;
    setState(() => _currentScreen = index);
  }

  @override
  Widget build(BuildContext context) {
    // All screens in order:
    // 0=Onboard1, 1=Onboard2, 2=Welcome, 3=Onboard3, 4=Auth, 5=HomeDashboard, 6=Alerts, 7=Map, 8=Report, 9=Settings
    final screens = [
      // Page 1 – Onboarding: Fire
      OnboardingScreen(
        title: _onboardingData[0]['title']!,
        subtitle: _onboardingData[0]['subtitle']!,
        buttonText: 'GET STARTED',
        imageAsset: _onboardingData[0]['image']!,
        onPressed: () => _navigate(1),
        pageIndex: 0,
      ),
      // Page 2 – Onboarding: Accident
      OnboardingScreen(
        title: _onboardingData[1]['title']!,
        subtitle: _onboardingData[1]['subtitle']!,
        buttonText: 'NEXT',
        imageAsset: _onboardingData[1]['image']!,
        onPressed: () => _navigate(2),
        pageIndex: 1,
      ),
      // Page 3 – Welcome
      WelcomeScreen(
        onSignIn: () => _navigate(4),
        onSignUp: () => _navigate(4),
      ),
      // Page 4 – Onboarding: Danger
      OnboardingScreen(
        title: _onboardingData[2]['title']!,
        subtitle: _onboardingData[2]['subtitle']!,
        buttonText: 'GET STARTED',
        imageAsset: _onboardingData[2]['image']!,
        onPressed: () => _navigate(4),
        pageIndex: 2,
      ),
      // Auth (Sign In / Sign Up)
      AuthScreen(
        onSuccess: () => _navigate(5),
      ),
      // Main App Dashboard
      const MainLayout(),
    ];

    return GlassBackdropScope(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentScreen),
          child: screens[_currentScreen],
        ),
      ),
    );
  }
}