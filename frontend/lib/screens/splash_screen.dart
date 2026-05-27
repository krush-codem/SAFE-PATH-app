import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _textController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;

  final List<String> _statusMessages = [
    'Initializing secure connection...',
    'Verifying encryption keys...',
    'Loading safety protocols...',
    'Activating guardian network...',
  ];

  int _currentMessage = 0;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();
    _progressController.forward();

    // Cycle through status messages
    for (int i = 1; i < _statusMessages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() => _currentMessage = i);
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;
    final mutedTextColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    if (kIsWeb) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, color: primaryColor, size: 80),
              const SizedBox(height: 32),
              Text(
                'Safe Path',
                style: TextStyle(
                  fontFamily: kIsWeb ? null : 'Manrope',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'THE INVISIBLE BODYGUARD',
                style: TextStyle(
                  fontFamily: kIsWeb ? null : 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _statusMessages[_currentMessage],
                style: TextStyle(color: mutedTextColor, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        color: backgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Top spacer
              const Spacer(flex: 2),

              // Logo + branding
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Column(
                    children: [
                      // Shield logo container
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.1),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2D4A) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.security,
                              color: primaryColor,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // App name
                      Text(
                        'Safe Path',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tagline
                      Text(
                        'THE INVISIBLE BODYGUARD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                          letterSpacing: 3.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Progress section
              FadeTransition(
                opacity: _textFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      // Progress bar
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (_, __) {
                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Stack(
                                  children: [
                                    // Background
                                    Container(
                                      height: 3,
                                      width: double.infinity,
                                      color: primaryColor.withValues(alpha: 0.1),
                                    ),
                                    // Progress fill
                                    Container(
                                      height: 3,
                                      width: MediaQuery.of(context).size.width *
                                          0.75 *
                                          _progressController.value,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        gradient: LinearGradient(
                                          colors: [
                                            primaryColor,
                                            primaryColor.withValues(alpha: 0.7),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Status message
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Row(
                          key: ValueKey(_currentMessage),
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _statusMessages[_currentMessage],
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'VERIFYING LOCAL SAFETY PROTOCOLS',
                        style: TextStyle(
                          fontSize: 10,
                          color: mutedTextColor,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Bottom badges
              FadeTransition(
                opacity: _textFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(Icons.shield_outlined, 'ENCRYPTION 256-BIT', mutedTextColor),
                      const SizedBox(width: 32),
                      _buildBadge(Icons.privacy_tip_outlined, 'PRIVACY FIRST', mutedTextColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
