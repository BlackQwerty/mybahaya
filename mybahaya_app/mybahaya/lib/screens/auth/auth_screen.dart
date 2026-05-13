import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const AuthScreen({super.key, required this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = true;
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
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

  Future<void> _handleAuth() async {
    if (!_agreed) {
      setState(() => _errorMessage = 'Please agree to Terms & Conditions');
      return;
    }

    if (_isSignUp && _passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        widget.onSuccess();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getAuthErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAuthErrorMessage(String code) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        color: AppTheme.solidBg,
        child: Stack(
          children: [
            Positioned(
              top: -80, right: -60,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.maroonPrimary.withOpacity(0.4), Colors.transparent,
                  ]),
                ),
              ),
            ),
            Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _miniLogo(),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MyBahaya',
                                style: GoogleFonts.playfairDisplay(
                                    fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text('Let us keep our community safe',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.white.withOpacity(0.5))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.04)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(36), topRight: Radius.circular(36)),
                        border: const Border(
                          top: BorderSide(color: Colors.white24),
                          left: BorderSide(color: Colors.white24),
                          right: BorderSide(color: Colors.white24),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _tabs(),
                            const SizedBox(height: 28),
                            if (_isSignUp) ..._signUpFields(),
                            if (!_isSignUp) ..._signInFields(),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(_errorMessage!,
                                  style: GoogleFonts.inter(
                                      color: AppTheme.alertRed, fontSize: 13)),
                            ],
                            const SizedBox(height: 20),
                            _termsRow(),
                            const SizedBox(height: 24),
                            _submitBtn(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniLogo() => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.1),
      border: Border.all(color: Colors.white24),
    ),
    child: Stack(alignment: Alignment.center, children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [AppTheme.maroonGlow, AppTheme.maroonPrimary]),
        ),
      ),
      Positioned(top: 12, left: 16,
        child: Container(width: 6, height: 6,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white))),
    ]),
  );

  Widget _tabs() => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: Row(children: [
      _tab('Sign Up', _isSignUp, () => setState(() => _isSignUp = true)),
      _tab('Sign In', !_isSignUp, () => setState(() => _isSignUp = false)),
    ]),
  );

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: active ? const LinearGradient(
              colors: [Color(0xFFB22222), Color(0xFF8B1A1A)]) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: active ? Colors.white : Colors.white.withOpacity(0.4))),
        ),
      ),
    ),
  );

  List<Widget> _signUpFields() => [
    TextField(
      controller: _usernameController,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: _inputDecoration('Username (Do not use real name)', Icons.person_outline_rounded),
    ),
    const SizedBox(height: 14),
    TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: _inputDecoration('Email', Icons.email_outlined),
    ),
    const SizedBox(height: 14),
    _passField('Password', _obscurePass, () => setState(() => _obscurePass = !_obscurePass)),
    const SizedBox(height: 14),
    _passField('Confirm Password', _obscureConfirm,
        () => setState(() => _obscureConfirm = !_obscureConfirm)),
    const SizedBox(height: 14),
    TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
    ),
  ];

  List<Widget> _signInFields() => [
    TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: _inputDecoration('Email or Username', Icons.person_outline_rounded),
    ),
    const SizedBox(height: 14),
    _passField('Password', _obscurePass, () => setState(() => _obscurePass = !_obscurePass)),
    const SizedBox(height: 12),
    Align(
      alignment: Alignment.centerRight,
      child: Text('Forgot Password?',
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.maroonGlow, fontWeight: FontWeight.w500)),
    ),
  ];

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.35), fontSize: 14),
    prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
    border: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  Widget _passField(String hint, bool obscure, VoidCallback onToggle) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: hint == 'Password' ? _passwordController : _confirmPasswordController,
        obscureText: obscure,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.35), fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.white.withOpacity(0.4), size: 20),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.white.withOpacity(0.4), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    ),
  );

  Widget _termsRow() => Row(
    children: [
      GestureDetector(
        onTap: () => setState(() => _agreed = !_agreed),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: _agreed ? AppTheme.maroonLight : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _agreed ? AppTheme.maroonLight : Colors.white24),
          ),
          child: _agreed ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.5)),
            children: [
              const TextSpan(text: 'By continuing, you agree to our '),
              TextSpan(text: 'Terms & Conditions',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.maroonGlow, fontWeight: FontWeight.w600)),
              const TextSpan(text: ' and '),
              TextSpan(text: 'Privacy Policy',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.maroonGlow, fontWeight: FontWeight.w600)),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _submitBtn() => GestureDetector(
    onTap: _isLoading ? null : _handleAuth,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFB22222), Color(0xFF8B1A1A)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFFB22222).withOpacity(0.5), blurRadius: 20, spreadRadius: -4)],
      ),
      child: Center(
        child: _isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(_isSignUp ? 'Sign Up' : 'Sign In',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5)),
      ),
    ),
  );
}