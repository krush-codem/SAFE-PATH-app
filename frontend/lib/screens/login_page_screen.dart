import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../providers/auth_provider.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';

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
      if (mounted) {
        try {
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
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? theme.colorScheme.error : AppColors.successEmerald,
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
      return 'Account unverified. Please check your email or resend verification.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield, color: colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'SAFE PATH',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Icon(Icons.help_outline,
                        color: colorScheme.onSurface, size: 20),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Authentication Card
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.dividerColor,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              Text(
                                'Sign In',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displayMedium,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Login to access your safe circle and stay protected.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),

                              const SizedBox(height: 32),

                              // Email / Phone toggle selector
                              _buildToggleSelector(),

                              const SizedBox(height: 32),

                              if (_isEmailTab) ...[
                                const _FieldLabel('EMAIL ADDRESS'),
                                const SizedBox(height: 10),
                                _buildEmailField(),
                              ] else ...[
                                const _FieldLabel('PHONE NUMBER'),
                                const SizedBox(height: 10),
                                _buildPhoneField(),
                              ],

                              const SizedBox(height: 24),

                              // Password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const _FieldLabel('PASSWORD'),
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
                                    child: Text(
                                      'FORGOT PASSWORD?',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildPasswordField(),

                              const SizedBox(height: 24),

                              // Trust device checkbox
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _trustDevice = !_trustDevice),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _trustDevice
                                            ? colorScheme.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: _trustDevice ? colorScheme.primary : theme.dividerColor,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: _trustDevice
                                          ? const Icon(Icons.check,
                                              size: 14, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Trust this encrypted device',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // ACCESS NETWORK button
                              _buildLoginButton(isLoading),

                              const SizedBox(height: 16),

                              // Google login
                              _buildGoogleButton(isLoading),

                              const SizedBox(height: 24),

                              // Create account link
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'New operative?  ',
                                    style: theme.textTheme.bodyMedium,
                                    children: [
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () =>
                                              context.go(AppRoutes.signup),
                                          child: Text(
                                            'Create a new Account',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w900,
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

                        const SizedBox(height: 32),

                        // Bottom encryption label
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'END-TO-END ENCRYPTED TUNNEL',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1.5),
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
                  color: _selectedTab == 0 ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'EMAIL',
                  style: TextStyle(
                    color: _selectedTab == 0 ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.38),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
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
                  color: _selectedTab == 1 ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PHONE',
                  style: TextStyle(
                    color: _selectedTab == 1 ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.38),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
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
    return TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        hintText: 'name@security.core',
        prefixIcon: Icon(Icons.alternate_email, size: 18),
      ),
    );
  }

  Widget _buildPhoneField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return IntlPhoneField(
      initialCountryCode: 'IN',
      style: theme.textTheme.bodyLarge,
      dropdownTextStyle: theme.textTheme.bodyLarge,
      decoration: const InputDecoration(
        hintText: 'Phone Number',
      ),
      onChanged: (phone) {
        _fullPhoneNumber = phone.completeNumber;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passCtrl,
      obscureText: _obscurePass,
      decoration: InputDecoration(
        hintText: '• • • • • • • • • • • •',
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePass = !_obscurePass),
          child: Icon(
            _obscurePass
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _handleLogin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else ...[
            const Text(
              'LOGIN',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: isLoading ? null : _handleGoogleLogin,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'G',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Sign in with Google',
            style: TextStyle(
              fontWeight: FontWeight.w700,
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
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        letterSpacing: 2,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

