import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
            title: Row(
              children: [
                Icon(Icons.sms_failed_rounded, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'SMS Verification',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A secure 6-digit code has been sent to:',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ENTER SECURITY CODE',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Attempts: $attempts/3',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: attempts >= 2 ? colorScheme.error : Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: dialogError != null 
                          ? colorScheme.error.withValues(alpha: 0.5) 
                          : theme.dividerColor,
                    ),
                  ),
                  child: TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    autofocus: true,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.15),
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
                    style: TextStyle(color: colorScheme.error, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: dialogLoading ? null : () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: dialogLoading || attempts >= 3 ? null : verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.onSurface,
                  foregroundColor: colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: dialogLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: colorScheme.surface, strokeWidth: 2),
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
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? colorScheme.error : AppColors.successEmerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
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
                            Row(
                              children: [
                                Icon(Icons.shield, color: colorScheme.primary, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'Safe Path',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'Complete Security Profile',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Safe Path requires your identity details to authenticate you and activate real-time SOS security transmissions.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 36),

                            _FieldLabel('REGISTERED EMAIL (READ-ONLY)'),
                            const SizedBox(height: 8),
                            _buildReadOnlyField(
                              text: currentUser?.email ?? 'Unavailable',
                              context: context,
                            ),

                            const SizedBox(height: 24),

                            _FieldLabel('FULL NAME'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nameCtrl,
                              hint: 'Johnathan Doe',
                              context: context,
                            ),

                            const SizedBox(height: 24),

                            _FieldLabel('PHONE NUMBER (SMS VERIFICATION)'),
                            const SizedBox(height: 8),
                            _buildPhoneField(context),

                            const SizedBox(height: 36),

                            // Continue button
                            GestureDetector(
                              onTap: isLoading ? null : _handleContinue,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isLoading)
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: colorScheme.surface,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        'REQUEST SMS OTP',
                                        style: TextStyle(
                                          color: colorScheme.surface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.send_rounded,
                                          color: colorScheme.surface, size: 16),
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
                                  style: theme.textTheme.bodySmall?.copyWith(
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
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: TextField(
        controller: controller,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String text, required BuildContext context}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.lock_outline_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: IntlPhoneField(
        initialCountryCode: 'IN',
        style: theme.textTheme.bodyLarge,
        dropdownTextStyle: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Phone Number',
          hintStyle: theme.textTheme.bodyMedium,
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
