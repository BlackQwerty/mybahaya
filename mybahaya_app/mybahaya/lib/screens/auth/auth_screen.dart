import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────
// Custom painter to draw the stylized logo at the top of the design
// ─────────────────────────────────────────────
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Draw outer circle
    canvas.drawCircle(center, radius, paint);

    // Draw stylized inner geometric shapes/flower
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * 0.5, center.dy + radius * 0.5);
    path.lineTo(center.dx + radius * 0.5, center.dy + radius * 0.5);
    path.close();
    canvas.drawPath(path, paint);

    // Draw center dot
    canvas.drawCircle(center, 4, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// Auth Screen
// ─────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final bool initialIsSignUp;

  const AuthScreen({
    super.key,
    required this.onSuccess,
    this.initialIsSignUp = true,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late bool _isSignUp;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreed = false;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedUsername = prefs.getString('saved_username');
      if (savedEmail != null && mounted) {
        setState(() {
          _emailController.text = savedEmail;
          if (savedUsername != null && _isSignUp) {
            _usernameController.text = savedUsername;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Auth Logic ──────────────────────────────
  Future<void> _handleAuth() async {
    if (_isSignUp && !_agreed) {
      setState(() => _errorMessage = 'Please agree to Terms & Conditions');
      return;
    }
    if (_isSignUp &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_isSignUp) {
        final cred =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_email', _emailController.text.trim());
          await prefs.setString('saved_username', _usernameController.text.trim());
        } catch (_) {}
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_email', _emailController.text.trim());
        } catch (_) {}
      }
      if (mounted) widget.onSuccess();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _errorMsg(e.code));
    } catch (_) {
      setState(() => _errorMessage = 'An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _errorMsg(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // ── Build ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.solidBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background subtle glow in top-right corner
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.maroonPrimary.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Area
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // ── Header Section ──
                  Center(
                    child: Column(
                      children: [
                         // logo icon
                         SizedBox(
                           width: 50,
                           height: 50,
                           child: Image.asset(
                             'assets/images/logos/logo.png',
                             errorBuilder: (context, error, stackTrace) {
                               return CustomPaint(
                                 painter: _LogoPainter(),
                               );
                             },
                           ),
                         ),
                        const SizedBox(height: 12),
                        Text(
                          'MyBahaya',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Let us keep our community safe',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Main Content Card (The Form Container) ──
                  SlideTransition(
                    position: _slideAnim,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Navigation Tabs ──
                          Row(
                            children: [
                              _TabItem(
                                label: 'Sign Up',
                                isActive: _isSignUp,
                                onTap: () => setState(() {
                                  _isSignUp = true;
                                  _errorMessage = null;
                                }),
                              ),
                              const SizedBox(width: 16),
                              _TabItem(
                                label: 'Sign In',
                                isActive: !_isSignUp,
                                onTap: () => setState(() {
                                  _isSignUp = false;
                                  _errorMessage = null;
                                }),
                              ),
                            ],
                          ),

                          // Custom Underline Divider Row
                          Stack(
                            children: [
                              Container(
                                height: 1.5,
                                color: Colors.white.withOpacity(0.15),
                                margin: const EdgeInsets.only(top: 8),
                              ),
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                left: _isSignUp ? 0 : 76,
                                width: _isSignUp ? 60 : 54,
                                child: Container(
                                  height: 2.5,
                                  color: const Color(0xFFB22222),
                                  margin: const EdgeInsets.only(top: 7.5),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ── Input Fields ──
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _isSignUp
                                ? _buildSignUpFields()
                                : _buildSignInFields(),
                          ),

                          // ── Error Message ──
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppTheme.alertRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // ── Custom Checkbox (only on Sign Up) ──
                          if (_isSignUp) ...[
                            _buildTermsCheckbox(),
                            const SizedBox(height: 24),
                          ],

                          // ── Submit Button ──
                          Center(
                            child: _buildSubmitButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SignUp Fields Widget ──
  Widget _buildSignUpFields() {
    return Column(
      key: const ValueKey('signup_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('Username'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _usernameController,
          placeholder: 'Do not use real name',
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('Email'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _emailController,
          placeholder: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('Password'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _passwordController,
          placeholder: 'Type password',
          obscureText: _obscurePass,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePass = !_obscurePass),
            child: Icon(
              _obscurePass
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('Confirm password'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _confirmPasswordController,
          placeholder: 'Re-type password',
          obscureText: _obscureConfirm,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
            child: Icon(
              _obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('Phone number'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _phoneController,
          placeholder: '01123456789',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _isSignUp = false),
            child: Text(
              'Already have an account? Sign in',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── SignIn Fields Widget ──
  Widget _buildSignInFields() {
    return Column(
      key: const ValueKey('signin_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('Email or Username'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _emailController,
          placeholder: 'Enter email or username',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('Password'),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _passwordController,
          placeholder: 'Type password',
          obscureText: _obscurePass,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePass = !_obscurePass),
            child: Icon(
              _obscurePass
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              // Add forgot password functionality if needed
            },
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFB22222),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _isSignUp = true),
            child: Text(
              "Don't have an account? Sign up",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Common label text above fields ──
  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  // ── Styled premium input field ──
  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.35),
            fontSize: 14,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ── Custom Checklist checkbox row ──
  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _agreed = !_agreed),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _agreed ? const Color(0xFFB22222) : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreed ? const Color(0xFFB22222) : Colors.white.withOpacity(0.2),
                width: 1.2,
              ),
            ),
            child: _agreed
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'By continuing, you agree to our '),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB22222),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB22222),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Custom filled submit button ──
  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleAuth,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 160,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF4C0E0E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isSignUp ? 'Sign up' : 'Sign in',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Simple Tab Item
// ─────────────────────────────────────────────
class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }
}