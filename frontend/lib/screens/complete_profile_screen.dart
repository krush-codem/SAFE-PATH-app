import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../routing/app_router.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  String? _fullPhoneNumber;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    
    // Prefill name from Supabase auth user metadata if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final metaName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '';
        if (metaName.isNotEmpty) {
          _nameCtrl.text = metaName;
        }
      }
    });

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
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final name = _nameCtrl.text.trim();
    final phone = _fullPhoneNumber;

    if (name.isEmpty || phone == null || phone.isEmpty) {
      _showSnack('Please enter your full name and a valid phone number');
      return;
    }

    await ref.read(authNotifierProvider.notifier).updateProfileAndAddPhone(
          fullName: name,
          phoneNumber: phone,
        );

    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      if (mounted) _showSnack(authState.error.toString());
    } else {
      if (mounted) {
        _showVerificationDialog(phone);
      }
    }
  }

  void _showVerificationDialog(String phone) {
    final otpCtrl = TextEditingController();
    bool dialogLoading = false;
    String? dialogError;
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
                    identifier: phone,
                    token: code,
                    isEmail: false,
                  );

              if (success) {
                // Invalidate profile/auth providers to trigger route recalculation
                ref.invalidate(currentUserProvider);
                ref.invalidate(profileProvider);

                if (context.mounted) {
                  Navigator.pop(context);
                  _showSnack('Identity verified! Setting up your lifeline...', isError: false);
                  
                  // Query initial route and navigate (likely to /lifeline)
                  final targetRoute = await ref.read(authRepositoryProvider).determineInitialRoute();
                  if (context.mounted) {
                    context.go(targetRoute);
                  }
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
                Icon(Icons.sms_failed_rounded, color: Colors.blueAccent, size: 28),
                SizedBox(width: 12),
                Text(
                  'SMS Verification',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A secure 6-digit code has been sent to:',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
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
                      'ENTER SECURITY CODE',
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
                        color: attempts >= 2 ? Colors.redAccent : Colors.amberAccent,
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
                    autofocus: true,
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
                if (dialogError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    dialogError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: dialogLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: dialogLoading || attempts >= 3 ? null : verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: const Color(0xFF0D1527),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: dialogLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Color(0xFF0D1527), strokeWidth: 2),
                      )
                    : const Text('VERIFY & CONTINUE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1527),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Icon(Icons.shield, color: Colors.blueAccent, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  'Safe Path',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            const Text(
                              'Complete Security Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Safe Path requires your identity details to authenticate you and activate real-time SOS security transmissions.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 36),

                            _FieldLabel('REGISTERED EMAIL (READ-ONLY)'),
                            const SizedBox(height: 8),
                            _buildReadOnlyField(
                              text: currentUser?.email ?? 'Unavailable',
                            ),

                            const SizedBox(height: 24),

                            _FieldLabel('FULL NAME'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nameCtrl,
                              hint: 'Johnathan Doe',
                            ),

                            const SizedBox(height: 24),

                            _FieldLabel('PHONE NUMBER (SMS VERIFICATION)'),
                            const SizedBox(height: 8),
                            _buildPhoneField(),

                            const SizedBox(height: 36),

                            // Continue button
                            GestureDetector(
                              onTap: isLoading ? null : _handleContinue,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
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
                                        'REQUEST SMS OTP',
                                        style: TextStyle(
                                          color: Color(0xFF0D1527),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.send_rounded,
                                          color: Color(0xFF0D1527), size: 16),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(),

                            Center(
                              child: TextButton(
                                onPressed: () async {
                                  await ref.read(authNotifierProvider.notifier).signOut();
                                  if (context.mounted) {
                                    context.go(AppRoutes.login);
                                  }
                                },
                                child: Text(
                                  'Use different account (Sign Out)',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111D35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
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

  Widget _buildReadOnlyField({required String text}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111D35).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.lock_outline_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111D35),
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
