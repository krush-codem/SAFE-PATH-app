import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/dynamic_ui.dart';

class PhysicalSafetyScreen extends StatefulWidget {
  const PhysicalSafetyScreen({super.key});

  @override
  State<PhysicalSafetyScreen> createState() => _PhysicalSafetyScreenState();
}

class _PhysicalSafetyScreenState extends State<PhysicalSafetyScreen> {
  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();
  
  bool _isTracking = false;
  double _progress = 0; // 0.0 to 1.0
  int _currentSegment = 1;
  final int _totalSegments = 3;
  Timer? _timer;

  void _startJourney() {
    if (_startCtrl.text.isEmpty || _destCtrl.text.isEmpty) return;
    setState(() {
      _isTracking = true;
      _progress = 0;
      _currentSegment = 1;
    });
    _simulateMovement();
  }

  void _simulateMovement() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += 0.05; // Simulate 5% progress per second
      });

      double segmentThreshold = _currentSegment / _totalSegments;
      if (_progress >= segmentThreshold) {
        timer.cancel(); // Pause journey for OTP
        _showOtpDialog();
      }
    });
  }

  void _showOtpDialog() {
    final TextEditingController otpCtrl = TextEditingController();
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SafeBackdrop(
          blur: 10,
          fallbackColor: theme.colorScheme.surface.withValues(alpha: 0.9),
          child: Dialog(
            backgroundColor: kIsWeb ? Colors.transparent : theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, color: theme.primaryColor, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _currentSegment == _totalSegments ? 'Final Destination Reached' : 'Checkpoint $_currentSegment Reached',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the OTP sent via SMS to verify your safety.', 
                    textAlign: TextAlign.center, 
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.colorScheme.onSurface, letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    decoration: InputDecoration(
                      hintText: '----',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.24)),
                      counterText: '',
                      filled: true,
                      fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (otpCtrl.text.length == 4) {
                          Navigator.pop(context);
                          if (_currentSegment == _totalSegments) {
                            setState(() {
                              _isTracking = false;
                              _progress = 0;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journey Completed Securely!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                          } else {
                            setState(() {
                              _currentSegment++;
                            });
                            _simulateMovement();
                          }
                        }
                      },
                      child: const Text('Verify Route & Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _startCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Physical Safety Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SafeBackdrop(
                blur: 16,
                fallbackColor: theme.colorScheme.surface.withValues(alpha: 0.6),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: kIsWeb ? Colors.transparent : theme.colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT LOCATION', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildTextField(Icons.my_location, 'E.g. Safehouse A', _startCtrl, !_isTracking),
                      
                      const SizedBox(height: 16),
                      Text('DESTINATION', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildTextField(Icons.location_on, 'E.g. Extraction Point B', _destCtrl, !_isTracking),
                      
                      const SizedBox(height: 24),
                      if (!_isTracking)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.route),
                            label: const Text('Initiate Secure Journey', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _startJourney,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tracking in Progress...', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                                Text('${(_progress * 100).toInt()}%', style: TextStyle(color: theme.colorScheme.onSurface)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 8,
                                backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('Segment $_currentSegment of $_totalSegments', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(IconData icon, String hint, TextEditingController ctrl, bool enabled) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: enabled ? 0.05 : 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        style: TextStyle(color: enabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
