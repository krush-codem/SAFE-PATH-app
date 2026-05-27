import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/journey_provider.dart';
import '../theme/app_theme.dart';

class SafetyCheckScreen extends ConsumerStatefulWidget {
  const SafetyCheckScreen({super.key});

  @override
  ConsumerState<SafetyCheckScreen> createState() => _SafetyCheckScreenState();
}

class _SafetyCheckScreenState extends ConsumerState<SafetyCheckScreen> {
  String _pin = '';

  void _onKeyTap(String key) {
    if (_pin.length < 6) {
      setState(() {
        _pin += key;
      });
      if (_pin.length == 6) {
        _verifyCurrentOtp();
      }
    }
  }

  Future<void> _verifyCurrentOtp() async {
    final journeyNotifier = ref.read(journeyProvider.notifier);
    final journeyState = ref.read(journeyProvider);
    
    final ok = await journeyNotifier.verifySafetyOtp(_pin);

    if (ok) {
      // Success
      final message = journeyState.isArrivalOtp 
        ? "You arrived safely, thank you for using our service."
        : "OTP is correct";
      
      _showResultPopup(message, isSuccess: true);
    } else {
      // Check if SOS was triggered or just incorrect
      final newState = ref.read(journeyProvider);
      if (newState.status == JourneyStatus.sosTriggered) {
         context.pop();
         return;
      }

      final tries = newState.otpTriesLeft;
      _showResultPopup("$tries tries left, please put the OTP correctly.", isSuccess: false);
      setState(() {
        _pin = '';
      });
    }
  }

  void _showResultPopup(String message, {required bool isSuccess}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? AppColors.successEmerald : colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (isSuccess) {
                   context.pop();
                }
              },
              child: Text('OK', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journeyState = ref.watch(journeyProvider);
    final secondsRemaining = journeyState.timeRemainingSeconds ?? 300;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.shield, color: colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  'Safe Path',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 48),
            
            // Surface Card Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  border: Border.all(color: theme.dividerColor, width: 1),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        journeyState.isArrivalOtp 
                          ? 'Safety Check: Arrival\nConfirmation'
                          : 'Safety Check: Are You\nOkay?',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          journeyState.isArrivalOtp
                            ? 'You have arrived at your destination. For safety, please enter the arrival OTP sent to your SYSTEM-CHAT.'
                            : 'We noticed an unusual deviation from your planned stay. Please verify your safety.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Countdown Circle
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: secondsRemaining / 300,
                              strokeWidth: 8,
                              color: colorScheme.primary,
                              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                          ),
                          Text(
                            '$secondsRemaining',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Positioned(
                            bottom: 25,
                            child: Text(
                              'SEC',
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // OTP dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index < _pin.length ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                          );
                        }),
                      ),
                      
                      const SizedBox(height: 12),
                      if (journeyState.isArrivalOtp)
                         Text(
                           'ARRIVAL VERIFICATION MODE',
                           style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                         )
                      else 
                         Text(
                           '${journeyState.otpTriesLeft} TRIES REMAINING',
                           style: theme.textTheme.bodySmall?.copyWith(
                             color: journeyState.otpTriesLeft == 1 ? colorScheme.error : Colors.orange,
                             fontWeight: FontWeight.bold, 
                           ),
                         ),
                      
                      const SizedBox(height: 32), 
                      
                      // Keypad
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Column(
                          children: [
                            _buildKeypadRow(['1', '2', '3'], context),
                            _buildKeypadRow(['4', '5', '6'], context),
                            _buildKeypadRow(['7', '8', '9'], context),
                            Row(
                              children: [
                                Expanded(child: _buildKeypadButton(Icons.backspace_outlined, context, onPressed: _onBackspace)),
                                Expanded(child: _buildKeypadButton('0', context, onPressed: () => _onKeyTap('0'))),
                                Expanded(child: _buildKeypadButton(Icons.check_circle, context, color: colorScheme.primary, onPressed: () {})),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              journeyState.isArrivalOtp 
                                ? 'CONFIRM ARRIVAL TO END TRACKING' 
                                : 'FAILING TO ENTER OTP WILL TRIGGER A SILENT EMERGENCY',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold, letterSpacing: 1),
                              textAlign: TextAlign.center,
                            ),
                            if (!journeyState.isArrivalOtp)
                              TextButton(
                                onPressed: () {
                                  ref.read(journeyProvider.notifier).stopJourney();
                                  _showArrivalAlert();
                                },
                                child: Text(
                                  'SIMULATE ARRIVAL (TEST)', 
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showArrivalAlert() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Arrived!', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        content: const Text(
          'As you have arrived in your JOURNEY, just for the safety we are sending another OTP please check it',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CHECK OTP', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys, BuildContext context) {
    return Row(
      children: keys.map((key) => Expanded(
        child: _buildKeypadButton(key, context, onPressed: () => _onKeyTap(key)),
      )).toList(),
    );
  }

  Widget _buildKeypadButton(dynamic content, BuildContext context, {VoidCallback? onPressed, Color? color}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 64,
        alignment: Alignment.center,
        child: content is String 
          ? Text(content, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold))
          : Icon(content as IconData, color: color ?? colorScheme.onSurface),
      ),
    );
  }
}
