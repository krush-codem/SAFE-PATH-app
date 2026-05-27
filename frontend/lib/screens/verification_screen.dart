import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/dynamic_ui.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String name;
  final String email;
  final String phone;

  const VerificationScreen({
    super.key,
    this.name = '',
    required this.email,
    required this.phone,
  });

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  // ── OTP boxes ─────────────────────────────────────────────────────────────
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // ── State ─────────────────────────────────────────────────────────────────
  int _attemptsLeft = 3;
  bool _otpSent = true; // Set to true by default since we request OTP on the previous page
  bool _isLoading = false;

  // ── Resend cooldown ───────────────────────────────────────────────────────
  Timer? _resendTimer;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _phoneNumber {
    if (widget.phone.isNotEmpty) return widget.phone;
    return ref.read(currentUserProvider)?.userMetadata?['phone_number'] ?? '';
  }

  String _masked(String value) {
    if (value.isEmpty) return '—';
    final clean = value.replaceAll(' ', '');
    if (clean.length <= 4) return clean;
    return '${'*' * (clean.length - 4)}${clean.substring(clean.length - 4)}';
  }

  String get _otpToken =>
      _otpControllers.map((c) => c.text.trim()).join();

  void _clearOtp() {
    for (final c in _otpControllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) _focusNodes[0].requestFocus();
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds == 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneNumber;
    if (phone.isEmpty) {
      _showSnack('No phone number found. Please return to the profile setup screen.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).sendOtp(
            identifier: phone,
            isEmail: false,
          );
      if (!mounted) return;
      final authState = ref.read(authNotifierProvider);
      if (authState.hasError) {
        _showSnack('Failed to send OTP: ${authState.error}');
      } else {
        setState(() => _otpSent = true);
        _startResendTimer();
        _showSnack('OTP sent to ${_masked(phone)}', isSuccess: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerify() async {
    final token = _otpToken;
    final phone = _phoneNumber;
    if (token.length < 6) {
      _showSnack('Enter the complete 6-digit OTP code');
      return;
    }
    if (_attemptsLeft <= 0) return;

    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authNotifierProvider.notifier).verifyOtp(
            identifier: phone,
            token: token,
            isEmail: false,
          );

      if (!mounted) return;

      if (success) {
        _showSnack('Identity verified! Welcome to Safe Path.', isSuccess: true);
        await Future.delayed(const Duration(milliseconds: 600));
        
        if (!mounted) return;
        // Invalidate the profile provider so the router reacts immediately
        ref.invalidate(profileProvider);
      } else {
        setState(() => _attemptsLeft--);
        _clearOtp();
        if (_attemptsLeft <= 0) {
          _showSnack('Too many failed attempts. Redirecting to login…');
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!mounted) return;
          await ref.read(authNotifierProvider.notifier).signOut();
          if (!mounted) return;
          context.go(AppRoutes.login);
        } else {
          _showSnack(
              'Incorrect OTP. $_attemptsLeft attempt${_attemptsLeft == 1 ? '' : 's'} remaining.');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: isSuccess ? AppColors.successEmerald : colorScheme.error,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).cardTheme.color,
      ),
    );
  }

  void _handleChangePhoneNumber() {
    context.go(AppRoutes.completeProfile);
  }

  @override
  Widget build(BuildContext context) {
    final phone = _phoneNumber;
    final maskedPhone = _masked(phone);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          _buildGlowOrb(
              top: -80, left: -80, color: colorScheme.primary.withValues(alpha: 0.15), size: 250),
          _buildGlowOrb(
              bottom: -60,
              right: -60,
              color: colorScheme.secondary.withValues(alpha: 0.1),
              size: 220),
          _buildGlowOrb(
              top: 160, right: 40, color: colorScheme.primary.withValues(alpha: 0.08), size: 140),
          SafeArea(
            child: Column(
              children: [
                // Top navigation / Back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 20),
                      onPressed: () => _handleChangePhoneNumber(),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surface,
                          border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.15),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(Icons.verified_user,
                            color: colorScheme.primary, size: 30),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Secure OTP Verification',
                        style: theme.textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A 6-digit transmission code has been sent to your phone number.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      _buildAttemptsRow(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Center panel
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Phone display card
                        _buildGlassCard(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.phone_android_outlined, color: colorScheme.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PHONE NUMBER',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      phone.isEmpty ? 'Not provided' : maskedPhone,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                              if (_otpSent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.successEmerald.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppColors.successEmerald.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    'SENT',
                                    style: TextStyle(
                                      color: AppColors.successEmerald,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSendOtpButton(),
                        const SizedBox(height: 28),
                        Text(
                          'ENTER VERIFICATION CODE',
                          style: theme.textTheme.bodySmall?.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildOtpBoxes(),
                        const SizedBox(height: 28),
                        _buildVerifyButton(),
                        const SizedBox(height: 20),
                        // Back to profile modifier option
                        Center(
                          child: TextButton.icon(
                            onPressed: _handleChangePhoneNumber,
                            icon: Icon(Icons.edit_note, color: colorScheme.primary, size: 18),
                            label: Text(
                              'Change phone number',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildGlassCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  color: colorScheme.onSurface.withValues(alpha: 0.3), size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Your OTP expires in 10 minutes. After 3 failed attempts you will be redirected to login to maintain network integrity.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsRow() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ATTEMPTS:  ',
          style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 2),
        ),
        ...List.generate(3, (i) {
          final active = i < _attemptsLeft;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppColors.successEmerald
                    : theme.dividerColor,
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: AppColors.successEmerald.withValues(alpha: 0.4),
                            blurRadius: 6)
                      ]
                    : [],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSendOtpButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canResend = _resendSeconds == 0;
    final label = !_otpSent
        ? 'SEND VERIFICATION CODE'
        : canResend
            ? 'RESEND CODE'
            : 'RESEND IN  $_resendSeconds s';

    return GestureDetector(
      onTap: (_isLoading || !canResend) ? null : _handleSendOtp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: canResend
                ? colorScheme.primary.withValues(alpha: 0.5)
                : theme.dividerColor,
          ),
          color: canResend
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading && !_otpSent)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            else
              Icon(
                Icons.send_outlined,
                size: 16,
                color: canResend ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: canResend ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBoxes() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 46,
          height: 56,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _otpControllers[i].text.isEmpty &&
                  i > 0) {
                _focusNodes[i - 1].requestFocus();
              }
            },
            child: TextField(
              controller: _otpControllers[i],
              focusNode: _focusNodes[i],
              enabled: _otpSent,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: theme.textTheme.displayMedium?.copyWith(fontSize: 22),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                ),
              ),
              onChanged: (val) {
                if (val.isNotEmpty && i < 5) {
                  _focusNodes[i + 1].requestFocus();
                }
                setState(() {});
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isReady =
        _otpToken.length == 6 && _otpSent && !_isLoading && _attemptsLeft > 0;

    return GestureDetector(
      onTap: isReady ? _handleVerify : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isReady ? colorScheme.primary : colorScheme.surface,
          border: isReady ? null : Border.all(color: theme.dividerColor),
          boxShadow: isReady
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(
                Icons.verified_user,
                size: 18,
                color: isReady ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            const SizedBox(width: 10),
            Text(
              _isLoading ? 'VERIFYING...' : 'VERIFY IDENTITY',
              style: TextStyle(
                color: isReady ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.3),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SafeBackdrop(
          blur: 10,
          fallbackColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildGlowOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: SafeBackdrop(
          blur: 60,
          fallbackColor: Colors.transparent,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
