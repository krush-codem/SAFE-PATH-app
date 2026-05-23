import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';
import '../widgets/dynamic_ui.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  bool _isPasswordSecure(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    // You could add special char checks here if desired
    return true;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Blur layer
          SafeBackdrop(
            blur: 100,
            child: Container(color: Colors.transparent),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                 padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: const Icon(Icons.security, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to Safe-Path',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isLogin ? 'Enter your credentials to continue securely' : 'Create a new secure identity',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Glass Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SafeBackdrop(
                      blur: 24,
                      fallbackColor: const Color(0xFF1E2023).withValues(alpha: 0.7),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: kIsWeb ? Colors.transparent : const Color(0xFF1E2023).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('IDENTITY IDENTIFIER', style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            _buildTextField(Icons.lock_open, 'Email address', false, _emailCtrl),
                            
                            const SizedBox(height: 24),
                            const Text('ACCESS TOKEN', style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            _buildTextField(Icons.lock_outline, 'Security password', true, _passCtrl),
                            
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() => _isLogin = !_isLogin);
                                },
                                child: Text(_isLogin ? 'Create an Account' : 'I already have an account', style: TextStyle(color: AppColors.primary.withValues(alpha: 0.7))),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [AppColors.primaryContainer, AppColors.primary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: _isLoading ? null : () async {
                                  if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;

                                  if (!_isLogin && !_isPasswordSecure(_passCtrl.text)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password must be 8+ chars and contain at least 1 uppercase and 1 number.', style: TextStyle(color: AppColors.onSurface)),
                                        backgroundColor: AppColors.errorContainer,
                                      )
                                    );
                                    return;
                                  }

                                  setState(() => _isLoading = true);
                                  try {
                                    if (_isLogin) {
                                      await Supabase.instance.client.auth.signInWithPassword(
                                        email: _emailCtrl.text,
                                        password: _passCtrl.text,
                                      );
                                    } else {
                                      await Supabase.instance.client.auth.signUp(
                                        email: _emailCtrl.text,
                                        password: _passCtrl.text,
                                      );
                                    }
                                    if (mounted) context.go('/home');
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: const TextStyle(color: AppColors.onSurface)), backgroundColor: AppColors.errorContainer));
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isLoading = false);
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _isLoading 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.onPrimaryContainer, strokeWidth: 2))
                                        : const Icon(Icons.verified_user, color: AppColors.onPrimaryContainer),
                                    const SizedBox(width: 8),
                                    Text(_isLoading ? 'Authenticating...' : (_isLogin ? 'Secure Login' : 'Create Account'), style: const TextStyle(color: AppColors.onPrimaryContainer, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Row(
                              children: [
                                Expanded(child: Divider(color: AppColors.outlineVariant)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('OR', style: TextStyle(color: AppColors.outlineVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                Expanded(child: Divider(color: AppColors.outlineVariant)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                                          SizedBox(width: 4),
                                          Text('Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.github);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.code, color: Colors.white, size: 24),
                                          SizedBox(width: 8),
                                          Text('GitHub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  Widget _buildTextField(IconData icon, String hint, bool obscure, TextEditingController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.outline),
          prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
