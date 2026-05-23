import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../routing/app_router.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;

  const SignUpScreen({super.key, this.initialData});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  int _selectedTab = 1;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    
    if (widget.initialData != null) {
      _emailCtrl.text = widget.initialData!['email'] ?? '';
      _nameCtrl.text = widget.initialData!['name'] ?? '';
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _showVerificationDialog(String email) {
    final otpCtrl = TextEditingController();
    bool dialogLoading = false;
    String? dialogError;
    bool otpSent = false;
    int attempts = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> verifyCode() async {
            final code = otpCtrl.text.trim();
            if (code.length != 6) {
              setDialogState(() {
                dialogError = 'Verification code must be 6 digits';
              });
              return;
            }

            setDialogState(() {
              dialogLoading = true;
              dialogError = null;
            });

            try {
              final success = await ref.read(authNotifierProvider.notifier).verifyOtp(
                    identifier: email,
                    token: code,
                    isEmail: true,
                  );

              if (success) {
                // Clear the signup pending lock
                ref.read(signupVerificationPendingProvider.notifier).set(false);

                // Sign out to force the user to log in manually as per workflow
                try {
                  await ref.read(authNotifierProvider.notifier).signOut();
                } catch (_) {}

                if (context.mounted) {
                  Navigator.pop(context);
                  _showSnack('Email verified! Please sign in to complete your profile.', isError: false);
                  
                  // Go to login page
                  context.go(AppRoutes.login);
                }
              } else {
                setDialogState(() {
                  attempts++;
                  dialogLoading = false;
                  if (attempts >= 3) {
                    dialogError = 'Too many failed attempts. Access denied.';
                  } else {
                    dialogError = 'Invalid code. ${3 - attempts} attempts remaining.';
                  }
                });

                if (attempts >= 3) {
                  await Future.delayed(const Duration(seconds: 2));
                  try {
                    await ref.read(authNotifierProvider.notifier).signOut();
                  } catch (_) {}
                  ref.read(signupVerificationPendingProvider.notifier).set(false);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnack('Verification failed. Maximum attempts exceeded.', isError: true);
                  }
                }
              }
            } catch (e) {
              setDialogState(() {
                attempts++;
                dialogLoading = false;
                if (attempts >= 3) {
                  dialogError = 'Too many failed attempts. Access denied.';
                } else {
                  dialogError = e.toString().replaceAll('Exception:', '').trim();
                }
              });

              if (attempts >= 3) {
                await Future.delayed(const Duration(seconds: 2));
                try {
                  await ref.read(authNotifierProvider.notifier).signOut();
                } catch (_) {}
                ref.read(signupVerificationPendingProvider.notifier).set(false);
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSnack('Verification failed. Maximum attempts exceeded.', isError: true);
                }
              }
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF131C30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: const Color(0xFF4A90D9).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            title: const Row(
              children: [
                Icon(Icons.mark_email_unread_rounded, color: Colors.blueAccent, size: 28),
                SizedBox(width: 12),
                Text(
                  'Verify Your Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!otpSent) ...[
                    const Text(
                      'To receive your 6-digit verification code, click "SENT-OTP" below:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: dialogLoading
                              ? null
                              : () async {
                                  setDialogState(() {
                                    dialogLoading = true;
                                    dialogError = null;
                                  });
                                  try {
                                    await ref
                                        .read(authNotifierProvider.notifier)
                                        .resendSignupOtp(email: email);
                                    setDialogState(() {
                                      otpSent = true;
                                      dialogLoading = false;
                                    });
                                  } catch (e) {
                                    setDialogState(() {
                                      dialogError = e
                                          .toString()
                                          .replaceAll('Exception:', '')
                                          .trim();
                                      dialogLoading = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90D9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: dialogLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'SENT-OTP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'An OTP verification transmission has been sent to:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ENTER 6-DIGIT SECURITY CODE',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Attempts: $attempts/3',
                          style: TextStyle(
                            color: attempts >= 2
                                ? Colors.redAccent
                                : Colors.amberAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1527),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: dialogError != null 
                              ? Colors.redAccent.withValues(alpha: 0.5) 
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: TextField(
                        controller: otpCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => dialogLoading ? null : verifyCode(),
                      ),
                    ),
                  ],
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: dialogLoading ? null : () async {
                  setDialogState(() {
                    dialogLoading = true;
                  });
                  try {
                    await ref.read(authNotifierProvider.notifier).signOut();
                  } catch (_) {}
                  ref.read(signupVerificationPendingProvider.notifier).set(false);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (otpSent)
                ElevatedButton(
                  onPressed: dialogLoading || attempts >= 3 ? null : verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: const Color(0xFF0D1527),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: dialogLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Color(0xFF0D1527),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'VERIFY & CONTINUE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    if (pass.length < 12) {
      _showSnack('Password must be at least 12 characters');
      return;
    }

    // Set signup pending lock to true before triggering signup, preventing early redirect
    ref.read(signupVerificationPendingProvider.notifier).set(true);

    await ref.read(authNotifierProvider.notifier).signUp(
          email: email,
          password: pass,
          fullName: name,
        );

    // Check current state after signup attempt
    final authState = ref.read(authNotifierProvider);
    final user = Supabase.instance.client.auth.currentUser;

    // 1. SUCCESS CASE (or silent success due to enumeration protection)
    if (!authState.hasError) {
      if (user != null && user.emailConfirmedAt != null) {
        // User is already verified (e.g. they were logged in or signed up again)
        ref.read(signupVerificationPendingProvider.notifier).set(false);
        if (mounted) {
          final targetRoute = await ref.read(authRepositoryProvider).determineInitialRoute();
          context.go(targetRoute);
        }
        return;
      }
      
      // Standard flow: show OTP dialog for new unverified user
      if (mounted) {
        _showVerificationDialog(email);
      }
      return;
    }

    // 2. ERROR CASE
    final errorMsg = authState.error.toString();
    
    // If user exists, try to log them in silently to check verification status
    if (errorMsg.contains('already registered') || 
        errorMsg.contains('already exists') || 
        errorMsg.contains('400')) {
      
      await ref.read(authNotifierProvider.notifier).signIn(
        email: email,
        password: pass,
      );
      
      final loginState = ref.read(authNotifierProvider);
      if (!loginState.hasError) {
        final loggedInUser = Supabase.instance.client.auth.currentUser;
        if (loggedInUser != null && loggedInUser.emailConfirmedAt != null) {
          // User is already verified! Release the lock and navigate.
          ref.read(signupVerificationPendingProvider.notifier).set(false);
          if (mounted) {
            final targetRoute = await ref.read(authRepositoryProvider).determineInitialRoute();
            context.go(targetRoute);
          }
          return;
        }
      }
    }

    // 3. ACTUAL FAILURE (invalid password, etc.)
    ref.read(signupVerificationPendingProvider.notifier).set(false);
    if (mounted) _showSnack(_friendlyError(errorMsg));
  }

  Future<void> _handleGoogleSignUp() async {
    // Check for existing session
    final existingSession = Supabase.instance.client.auth.currentSession;
    if (existingSession != null) {
      if (mounted) _showSnack('Existing session detected. Processing...', isError: false);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connecting to Google...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final success = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    
    if (success && mounted) {
      // The AppRouter will handle redirection automatically based on the profile state
      _showSnack('Authenticating with Google...', isError: false);
      // Tiny delay to allow router evaluation
      await Future.delayed(const Duration(milliseconds: 300));
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).error;
      if (error != null) {
        _showSnack(_friendlyError(error.toString()));
      }
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? const Color(0xFF8B0000) : Colors.green.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('already registered') || raw.contains('already exists')) {
      return 'This email is already registered. Try logging in.';
    }
    if (raw.contains('Password should be')) return 'Password is too weak.';
    if (raw.contains('network')) return 'Network error. Check your connection.';
    return raw; // Fallback to raw error for debugging
  }



  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1527),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Safe Path',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4A90D9).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.person,
                        color: Colors.white54, size: 20),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        const Text(
                          'Create Identity Card',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Initialize your secure profile on the Safe Path network.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        _FieldLabel('FULL NAME'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameCtrl,
                          hint: 'Johnathan Doe',
                        ),

                        const SizedBox(height: 20),

                        _FieldLabel('SECURE EMAIL'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailCtrl,
                          hint: 'name@security.com',
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        _FieldLabel('MASTER KEY (PASSWORD)'),
                        const SizedBox(height: 8),
                        _buildPasswordField(),
                        const SizedBox(height: 6),
                        Text(
                          'Requirement: 12+ characters',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Initialize Identity button
                        GestureDetector(
                          onTap: isLoading ? null : _handleSignUp,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLoading)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF0D1527),
                                      strokeWidth: 2,
                                    ),
                                  )
                                else ...[
                                  const Text(
                                    'INITIALIZE IDENTITY',
                                    style: TextStyle(
                                      color: Color(0xFF0D1527),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward,
                                      color: Color(0xFF0D1527), size: 18),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // OR divider
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white10)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(child: Divider(color: Colors.white10)),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Google button
                        _buildGoogleButton(isLoading),


                        const SizedBox(height: 20),

                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an identity? ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 13,
                              ),
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () =>
                                        context.go(AppRoutes.login),
                                    child: const Text(
                                      'Authenticate here.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom nav
            _buildBottomNav(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111D35),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111D35),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _passCtrl,
        obscureText: _obscurePass,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: '• • • • • • • • • • •',
          hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePass = !_obscurePass),
            child: Icon(
              _obscurePass
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white.withValues(alpha: 0.35),
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _handleGoogleSignUp,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2540),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'SIGN UP WITH GOOGLE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Phone field has been deprecated in SignUpScreen in favor of CompleteProfileScreen

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.book_outlined, 'JOURNEY'),
          _navItem(1, Icons.verified_user_outlined, 'GUARD'),
          _navItem(2, Icons.person_outline, 'PROFILE'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 10,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
