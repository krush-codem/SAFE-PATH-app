import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/journey_provider.dart';

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? Colors.greenAccent : Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
              child: const Text('OK', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
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
    final journeyState = ref.watch(journeyProvider);
    final secondsRemaining = journeyState.timeRemainingSeconds ?? 300;

    return Scaffold(
      backgroundColor: const Color(0xFF2D4039), // Dark greenish background from Image 4
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
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield, color: Colors.blueAccent, size: 28),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Safe Path',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 48),
            
            // White Card Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        journeyState.isArrivalOtp 
                          ? 'Safety Check: Arrival\nConfirmation'
                          : 'Safety Check: Are You\nOkay?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF131A26),
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
                          style: const TextStyle(color: Colors.black54, fontSize: 14),
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
                              color: Colors.orange,
                              backgroundColor: Colors.grey[200],
                            ),
                          ),
                          Text(
                            '$secondsRemaining',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF131A26),
                            ),
                          ),
                          const Positioned(
                            bottom: 25,
                            child: Text(
                              'SEC',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38),
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
                              color: index < _pin.length ? const Color(0xFF131A26) : Colors.grey[200],
                            ),
                          );
                        }),
                      ),
                      
                      const SizedBox(height: 12),
                      if (journeyState.isArrivalOtp)
                         const Text(
                           'ARRIVAL VERIFICATION MODE',
                           style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10),
                         )
                      else 
                         Text(
                           '${journeyState.otpTriesLeft} TRIES REMAINING',
                           style: TextStyle(
                             color: journeyState.otpTriesLeft == 1 ? Colors.redAccent : Colors.orange,
                             fontWeight: FontWeight.bold, 
                             fontSize: 10
                           ),
                         ),
                      
                      const SizedBox(height: 32), // Replaced Spacer with fixed size since it's in a scrollview
                      
                      // Keypad
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Column(
                          children: [
                            _buildKeypadRow(['1', '2', '3']),
                            _buildKeypadRow(['4', '5', '6']),
                            _buildKeypadRow(['7', '8', '9']),
                            Row(
                              children: [
                                Expanded(child: _buildKeypadButton(Icons.backspace_outlined, onPressed: _onBackspace)),
                                Expanded(child: _buildKeypadButton('0', onPressed: () => _onKeyTap('0'))),
                                Expanded(child: _buildKeypadButton(Icons.check_circle, color: Colors.orange, onPressed: () {})),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D1200), // Dark brown/orange
                          borderRadius: BorderRadius.only(
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
                              style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                              textAlign: TextAlign.center,
                            ),
                            if (!journeyState.isArrivalOtp)
                              TextButton(
                                onPressed: () {
                                  ref.read(journeyProvider.notifier).stopJourney();
                                  _showArrivalAlert();
                                },
                                child: const Text(
                                  'SIMULATE ARRIVAL (TEST)', 
                                  style: TextStyle(color: Colors.white24, fontSize: 8),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Arrived!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'As you have arrived in your JOURNEY, just for the safety we are sending another OTP please check it',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CHECK OTP', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) => Expanded(
        child: _buildKeypadButton(key, onPressed: () => _onKeyTap(key)),
      )).toList(),
    );
  }

  Widget _buildKeypadButton(dynamic content, {VoidCallback? onPressed, Color? color}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 64,
        alignment: Alignment.center,
        child: content is String 
          ? Text(content, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF131A26)))
          : Icon(content as IconData, color: color ?? const Color(0xFF131A26)),
      ),
    );
  }
}
