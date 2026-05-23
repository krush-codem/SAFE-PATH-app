import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/journey_provider.dart';

class TimerSetupScreen extends ConsumerStatefulWidget {
  const TimerSetupScreen({super.key});

  @override
  ConsumerState<TimerSetupScreen> createState() => _TimerSetupScreenState();
}

class _TimerSetupScreenState extends ConsumerState<TimerSetupScreen> {
  int _selectedMinutes = 15; 
  int _customHours = 0;
  int _customMinutes = 15;
  bool _isCustomActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131A26),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.security, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text('Sentinel Core', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        leadingWidth: 200,
        actions: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => context.pop())
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Security Timer\nSetup', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('Set your OTP duration for this journey.', style: TextStyle(fontSize: 14, color: Colors.white54), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              
              _OptionCard(title: '15 Minutes', subtitle: 'QUICK JOURNEY', isSelected: !_isCustomActive && _selectedMinutes == 15, onTap: () => setState(() { _selectedMinutes = 15; _isCustomActive = false; })),
              const SizedBox(height: 12),
              _OptionCard(title: '30 Minutes', subtitle: 'RECOMMENDED', isSelected: !_isCustomActive && _selectedMinutes == 30, onTap: () => setState(() { _selectedMinutes = 30; _isCustomActive = false; })),
              const SizedBox(height: 12),
              _OptionCard(title: '45 Minutes', subtitle: 'STANDARD', isSelected: !_isCustomActive && _selectedMinutes == 45, onTap: () => setState(() { _selectedMinutes = 45; _isCustomActive = false; })),
              const SizedBox(height: 12),
              _OptionCard(title: '1 Hour', subtitle: 'EXTENDED', isSelected: !_isCustomActive && _selectedMinutes == 60, onTap: () => setState(() { _selectedMinutes = 60; _isCustomActive = false; })),
              const SizedBox(height: 12),
              _OptionCard(title: 'Custom Duration', subtitle: 'FLEXIBLE', isSelected: _isCustomActive, onTap: () => setState(() { _isCustomActive = true; _selectedMinutes = (_customHours * 60) + _customMinutes; })),
              
              if (_isCustomActive)
                ...[
                   const SizedBox(height: 4),
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: const BoxDecoration(color: Color(0xFF1E2633), borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
                     child: Column(
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             _CounterColumn(
                               label: 'HOURS', 
                               value: _customHours.toString().padLeft(2, '0'), 
                               onIncrement: () => setState(() { _customHours++; _selectedMinutes = (_customHours * 60) + _customMinutes; }),
                               onDecrement: () => setState(() { if (_customHours > 0) _customHours--; _selectedMinutes = (_customHours * 60) + _customMinutes; }),
                             ),
                             const Padding(
                               padding: EdgeInsets.symmetric(horizontal: 16),
                               child: Text(':', style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)),
                             ),
                             _CounterColumn(
                               label: 'MINUTES', 
                               value: _customMinutes.toString().padLeft(2, '0'),
                               onIncrement: () => setState(() { _customMinutes = (_customMinutes + 5) % 60; _selectedMinutes = (_customHours * 60) + _customMinutes; }),
                               onDecrement: () => setState(() { _customMinutes = (_customMinutes - 5 + 60) % 60; _selectedMinutes = (_customHours * 60) + _customMinutes; }),
                             ),
                           ],
                         ),
                         const SizedBox(height: 16),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                           decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                           child: Text('Total: $_selectedMinutes minutes', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                         )
                       ],
                     ),
                   )
                ],

              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E2633), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Your safety circle will be prompted for an identity challenge if you stop moving for longer than this duration.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, height: 1.4))),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001B3A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: _selectedMinutes >= 15 ? () {
                  final notifier = ref.read(journeyProvider.notifier);
                  notifier.setTimerInterval(_selectedMinutes);
                  notifier.startJourney();
                  // REDIRECT TO HOME DASHBOARD (Image 1)
                  context.go('/home');
                } : null,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.bolt, color: Colors.white), const SizedBox(width: 8), Text(_selectedMinutes >= 15 ? 'Start Secure Journey' : 'Min 15m Required', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({required this.title, required this.subtitle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF002447) : const Color(0xFF1E2633), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? Colors.white : Colors.white30),
          ],
        ),
      ),
    );
  }
}

class _CounterColumn extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  
  const _CounterColumn({required this.label, required this.value, required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(icon: const Icon(Icons.add, color: Colors.white54, size: 20), onPressed: onIncrement),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 12),
        IconButton(icon: const Icon(Icons.remove, color: Colors.white54, size: 20), onPressed: onDecrement),
      ],
    );
  }
}
