import 'package:flutter/material.dart';
import 'dart:async';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(const MyBahayaApp(), adaptiveQuality: true));
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
  bool _authIsSignUp = true;
  bool _initialized = false;
  bool _isOnboarded = false;
  StreamSubscription<User?>? _authSubscription;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'There was a fire ?',
      'subtitle':
          'Instant alerts for fire incidents near you. Stay informed, stay safe.',
      'image': 'assets/images/onboarding/onb_fire.jpeg',
    },
    {
      'title': 'Someone had an accident ?',
      'subtitle':
          'Report accidents instantly. Help reach those in need faster.',
      'image': 'assets/images/onboarding/onb_accident.jpeg',
    },
    {
      'title': 'Someone in danger ?',
      'subtitle':
          'Your report could save lives. Be the eyes of your community.',
      'image': 'assets/images/onboarding/onb_danger.jpeg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboarded = prefs.getBool('onboarding_completed') ?? false;
    } catch (_) {
      _isOnboarded = false;
    }

    // Set up auth changes listener to dynamically handle auto-login and sign-out globally
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      bool hasProfile = false;
      if (user != null) {
        try {
          final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          hasProfile = snap.exists;
        } catch (_) {
          // If firestore read fails (e.g. permission or network), default to false/sign out
          hasProfile = false;
        }
        if (!hasProfile) {
          await FirebaseAuth.instance.signOut();
          user = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _initialized = true;
        if (!_isOnboarded) {
          _currentScreen = 0; // Force Onboarding Screen 1
        } else {
          if (user != null) {
            _currentScreen = 5; // Welcome/Main Dashboard
          } else {
            _currentScreen = 3; // WelcomeScreen
          }
        }
      });
    }, onError: (err) {
      if (mounted) {
        setState(() {
          _initialized = true;
          _currentScreen = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _navigate(int index) {
    if (index == _currentScreen) return;
    setState(() => _currentScreen = index);
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isOnboarded = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentScreen = 5; // Main Layout
      } else {
        _currentScreen = 3; // WelcomeScreen
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Premium loading screen while verifying persistent local state and auto-login credentials
      return Scaffold(
        backgroundColor: AppTheme.solidBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo silhouette placeholder
              SizedBox(
                width: 70,
                height: 70,
                child: Image.asset(
                  'assets/images/logos/logo.png',
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFACA494),
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFFB22222),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // All screens in order:
    // 0=Onboard1, 1=Onboard2, 2=Onboard3, 3=Welcome, 4=Auth, 5=HomeDashboard/MainLayout
    final screens = [
      // Page 1 – Onboarding: Fire
      OnboardingScreen(
        title: _onboardingData[0]['title']!,
        subtitle: _onboardingData[0]['subtitle']!,
        buttonText: 'NEXT',
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
      // Page 3 – Onboarding: People in Danger
      OnboardingScreen(
        title: _onboardingData[2]['title']!,
        subtitle: _onboardingData[2]['subtitle']!,
        buttonText: 'GET STARTED',
        imageAsset: _onboardingData[2]['image']!,
        onPressed: _completeOnboarding,
        pageIndex: 2,
      ),
      // Page 4 – Welcome Screen
      WelcomeScreen(
        onSignIn: () {
          setState(() {
            _authIsSignUp = false;
            _currentScreen = 4;
          });
        },
        onSignUp: () {
          setState(() {
            _authIsSignUp = true;
            _currentScreen = 4;
          });
        },
      ),
      // Page 5 – Auth Screen (Sign In / Sign Up)
      AuthScreen(
        initialIsSignUp: _authIsSignUp,
        onSuccess: () {
          // Handled via stream listener automatically, but fallback navigate just in case
          _navigate(5);
        },
      ),
      // Page 6 – Main App Dashboard Layout
      const MainLayout(),
    ];

    return GlassBackdropScope(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder:
            (child, animation) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
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
