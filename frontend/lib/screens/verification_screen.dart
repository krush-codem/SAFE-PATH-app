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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor:
            isSuccess ? const Color(0xFF1A7A4A) : const Color(0xFF8B0000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
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

    return Scaffold(
      backgroundColor: const Color(0xFF080F1E),
      body: Stack(
        children: [
          _buildGlowOrb(
              top: -80, left: -80, color: const Color(0xFF1A3A6E), size: 250),
          _buildGlowOrb(
              bottom: -60,
              right: -60,
              color: const Color(0xFF0E2A50),
              size: 220),
          _buildGlowOrb(
              top: 160, right: 40, color: const Color(0xFF112244), size: 140),
          SafeArea(
            child: Column(
              children: [
                // Top navigation / Back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3F7A), Color(0xFF102040)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                              color: const Color(0xFF3A6FD8).withValues(alpha: 0.5),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3A6FD8).withValues(alpha: 0.35),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.verified_user,
                            color: Color(0xFF7EB3FF), size: 30),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Secure OTP Verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A 6-digit transmission code has been sent to your phone number.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12.5,
                          height: 1.5,
                        ),
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
                                  color: const Color(0xFF1E3F7A).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.phone_android_outlined, color: Color(0xFF7EB3FF), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PHONE NUMBER',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        fontSize: 9,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      phone.isEmpty ? 'Not provided' : maskedPhone,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_otpSent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A7A4A).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                                  ),
                                  child: const Text(
                                    'SENT',
                                    style: TextStyle(
                                      color: Color(0xFF4CAF50),
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
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 9,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
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
                            icon: const Icon(Icons.edit_note, color: Colors.blueAccent, size: 18),
                            label: const Text(
                              'Change phone number',
                              style: TextStyle(
                                color: Colors.blueAccent,
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
                                  color: Colors.white.withValues(alpha: 0.3), size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Your OTP expires in 10 minutes. After 3 failed attempts you will be redirected to login to maintain network integrity.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11.5,
                                    height: 1.5,
                                  ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ATTEMPTS:  ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
            letterSpacing: 2,
          ),
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
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF3A3A3A),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.6),
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
                ? const Color(0xFF3A6FD8).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.1),
          ),
          color: canResend
              ? const Color(0xFF1E3F7A).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.03),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading && !_otpSent)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF7EB3FF),
                ),
              )
            else
              Icon(
                Icons.send_outlined,
                size: 16,
                color: canResend ? const Color(0xFF7EB3FF) : Colors.white24,
              ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: canResend ? const Color(0xFF7EB3FF) : Colors.white24,
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: _otpSent
                    ? const Color(0xFF111D35)
                    : const Color(0xFF0D1525),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF3A6FD8), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.04)),
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
    final isReady =
        _otpToken.length == 6 && _otpSent && !_isLoading && _attemptsLeft > 0;

    return GestureDetector(
      onTap: isReady ? _handleVerify : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isReady
              ? const LinearGradient(
                  colors: [Color(0xFF1E3F7A), Color(0xFF3A6FD8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isReady ? null : const Color(0xFF111D35),
          boxShadow: isReady
              ? [
                  BoxShadow(
                    color: const Color(0xFF3A6FD8).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
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
              const Icon(
                Icons.verified_user,
                size: 18,
                color: Colors.white,
              ),
            const SizedBox(width: 10),
            Text(
              _isLoading ? 'VERIFYING...' : 'VERIFY IDENTITY',
              style: TextStyle(
                color: isReady ? Colors.white : Colors.white24,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SafeBackdrop(
        blur: 12,
        fallbackColor: const Color(0xFF111D35).withValues(alpha: 0.7),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kIsWeb ? Colors.transparent : const Color(0xFF111D35).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: child,
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
          color: color.withValues(alpha: 0.45),
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
