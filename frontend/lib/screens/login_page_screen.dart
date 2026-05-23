import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../providers/auth_provider.dart';
import '../routing/app_router.dart';

class LoginPageScreen extends ConsumerStatefulWidget {
  const LoginPageScreen({super.key});

  @override
  ConsumerState<LoginPageScreen> createState() => _LoginPageScreenState();
}

class _LoginPageScreenState extends ConsumerState<LoginPageScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Email, 1 = Phone
  bool get _isEmailTab => _selectedTab == 0;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _fullPhoneNumber;
  bool _obscurePass = true;
  bool _trustDevice = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final pass = _passCtrl.text;

    if (_isEmailTab) {
      final email = _emailCtrl.text.trim();
      if (email.isEmpty || pass.isEmpty) {
        _showSnack('Please fill all fields');
        return;
      }
      await ref.read(authNotifierProvider.notifier).signIn(
            email: email,
            password: pass,
          );
    } else {
      final phone = _fullPhoneNumber;
      if (phone == null || phone.isEmpty || pass.isEmpty) {
        _showSnack('Please enter your phone number and password');
        return;
      }
      await ref.read(authNotifierProvider.notifier).signInWithPhone(
            phone: phone,
            password: pass,
          );
    }

    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      if (mounted) _showSnack(_friendlyError(authState.error.toString()));
    } else {
      // Login succeeded, determine the initial route dynamically
      if (mounted) {
        try {
          // Invalidate profile to ensure we have the freshest state
          ref.invalidate(profileProvider);
          final nextRoute = await ref.read(authNotifierProvider.notifier).determineInitialRoute();
          if (mounted) {
            context.go(nextRoute);
          }
        } catch (e) {
          if (mounted) _showSnack('Error loading profile routing details.');
        }
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    final existingSession = Supabase.instance.client.auth.currentSession;
    if (existingSession != null) {
      if (mounted) _showSnack('Existing session detected. Resuming...');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirecting to Google...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final success = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    
    if (success && mounted) {
      _showSnack('Authenticating with Google...', isError: false);
      try {
        final nextRoute = await ref.read(authNotifierProvider.notifier).determineInitialRoute();
        if (mounted) {
          context.go(nextRoute);
        }
      } catch (e) {
        if (mounted) _showSnack('Google auth succeeded, but could not determine route.');
      }
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
    if (raw.contains('Invalid login credentials')) {
      return 'Incorrect email/phone or password.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Account unverified. Please check your email or try signing up again to resend the code.';
    }
    if (raw.contains('network')) return 'Network error. Check your connection.';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1527),
      body: SafeArea(
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
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        // Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111D35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              const Text(
                                'Identity\nAuthentication',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Verification protocol required to access the Safe Path safety network.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Email / Phone toggle selector
                              _buildToggleSelector(),

                              const SizedBox(height: 24),

                              if (_isEmailTab) ...[
                                _FieldLabel('SECURE EMAIL'),
                                const SizedBox(height: 8),
                                _buildEmailField(),
                              ] else ...[
                                _FieldLabel('PHONE NUMBER'),
                                const SizedBox(height: 8),
                                _buildPhoneField(),
                              ],

                              const SizedBox(height: 20),

                              // Password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const _FieldLabel('MASTER KEY (PASSWORD)'),
                                  GestureDetector(
                                    onTap: () async {
                                      if (_isEmailTab) {
                                        if (_emailCtrl.text.isEmpty) {
                                          _showSnack('Enter your email first');
                                          return;
                                        }
                                        await ref
                                            .read(authRepositoryProvider)
                                            .sendPasswordResetEmail(
                                                _emailCtrl.text.trim());
                                        if (mounted) {
                                          _showSnack(
                                              'Reset email sent! Check your inbox.');
                                        }
                                      } else {
                                        _showSnack('Password resets are only available via Email.');
                                      }
                                    },
                                    child: const Text(
                                      'RECOVER KEY',
                                      style: TextStyle(
                                        color: Color(0xFF7BB8F0),
                                        fontSize: 10,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildPasswordField(),

                              const SizedBox(height: 18),

                              // Trust device checkbox
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _trustDevice = !_trustDevice),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: _trustDevice
                                            ? const Color(0xFF4A90D9)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.35),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: _trustDevice
                                          ? const Icon(Icons.check,
                                              size: 12, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Trust this encrypted device',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // LOGIN button
                              _buildLoginButton(isLoading),

                              const SizedBox(height: 14),

                              // Google login
                              _buildGoogleButton(isLoading),

                              const SizedBox(height: 20),

                              // Create account link
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'New operative?  ',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 13,
                                    ),
                                    children: [
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () =>
                                              context.go(AppRoutes.signup),
                                          child: const Text(
                                            'Create a new Account',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bottom encryption label
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: Colors.white.withValues(alpha: 0.3),
                                  size: 12,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'END-TO-END ENCRYPTED TUNNEL',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 10,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _encryptBadge(Icons.lock),
                                const SizedBox(width: 8),
                                _encryptBadge(Icons.verified_user_outlined),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSelector() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2540),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'EMAIL',
                  style: TextStyle(
                    color: _selectedTab == 0 ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PHONE',
                  style: TextStyle(
                    color: _selectedTab == 1 ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'name@security.core',
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          prefixIcon: Icon(Icons.alternate_email,
              color: Colors.white.withValues(alpha: 0.35), size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: IntlPhoneField(
        initialCountryCode: 'IN',
        style: const TextStyle(color: Colors.white, fontSize: 14),
        dropdownTextStyle: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Phone Number',
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (phone) {
          _fullPhoneNumber = phone.completeNumber;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _passCtrl,
        obscureText: _obscurePass,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: '• • • • • • • • • • • •',
          hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Icon(Icons.lock_outline,
              color: Colors.white.withValues(alpha: 0.35), size: 18),
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
              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _handleLogin,
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
                'LOGIN',
                style: TextStyle(
                  color: Color(0xFF0D1527),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.shield, color: Color(0xFF0D1527), size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _handleGoogleLogin,
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
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Login with Google',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _encryptBadge(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child:
          Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 16),
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
