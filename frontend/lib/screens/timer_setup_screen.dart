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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.security, color: theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Text('PROTOCOL', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14)),
          ],
        ),
        leadingWidth: 200,
        actions: [
          IconButton(icon: Icon(Icons.close, color: theme.colorScheme.onSurface, size: 20), onPressed: () => context.pop())
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Security Timer\nSetup', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, height: 1.1, letterSpacing: 1), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text('SET IDENTITY CHALLENGE DURATION', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontWeight: FontWeight.w900, letterSpacing: 2), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              
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
                     padding: const EdgeInsets.all(28),
                     decoration: BoxDecoration(
                       color: theme.colorScheme.surface, 
                       borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                       border: Border(
                         left: BorderSide(color: theme.colorScheme.onSurface, width: 2),
                         right: BorderSide(color: theme.colorScheme.onSurface, width: 2),
                         bottom: BorderSide(color: theme.colorScheme.onSurface, width: 2),
                       )
                     ),
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
                             Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 24),
                               child: Text(':', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.w900)),
                             ),
                             _CounterColumn(
                               label: 'MINUTES', 
                               value: _customMinutes.toString().padLeft(2, '0'),
                               onIncrement: () => setState(() { _customMinutes = (_customMinutes + 5) % 60; _selectedMinutes = (_customHours * 60) + _customMinutes; }),
                               onDecrement: () => setState(() { _customMinutes = (_customMinutes - 5 + 60) % 60; _selectedMinutes = (_customHours * 60) + _customMinutes; }),
                             ),
                           ],
                         ),
                         const SizedBox(height: 24),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                           decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                           child: Text('TOTAL INTERVAL: $_selectedMinutes MINUTES', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                         )
                       ],
                     ),
                   )
                ],

              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, 
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor, width: 1.5)
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), size: 20),
                    const SizedBox(width: 16),
                    Expanded(child: Text('The system will prompt you for an identity challenge at every interval. Failure to verify triggers SOS broadcast.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12, height: 1.5, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.onSurface, 
                    foregroundColor: theme.colorScheme.surface, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: _selectedMinutes >= 15 ? () {
                    final notifier = ref.read(journeyProvider.notifier);
                    notifier.setTimerInterval(_selectedMinutes);
                    notifier.startJourney();
                    context.go('/home');
                  } : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Icon(Icons.bolt_rounded, color: theme.colorScheme.surface), 
                      const SizedBox(width: 12), 
                      Text(_selectedMinutes >= 15 ? 'INITIALIZE JOURNEY' : 'MIN 15M REQUIRED', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5))
                    ]
                  ),
                ),
              ),
              const SizedBox(height: 40),
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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: isSelected ? theme.colorScheme.onSurface : theme.dividerColor, width: isSelected ? 2.5 : 1.5)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(subtitle, style: TextStyle(color: isSelected ? theme.colorScheme.onSurface.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)), 
                const SizedBox(height: 8), 
                Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5))
              ]
            ),
            if (isSelected) 
              Icon(Icons.check_circle, color: theme.colorScheme.onSurface, size: 28)
            else
              Icon(Icons.radio_button_off, color: theme.colorScheme.onSurface.withValues(alpha: 0.12), size: 28),
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
    final theme = Theme.of(context);
    return Column(
      children: [
        IconButton(icon: Icon(Icons.keyboard_arrow_up_rounded, color: theme.colorScheme.onSurface, size: 32), onPressed: onIncrement),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 40, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        IconButton(icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurface, size: 32), onPressed: onDecrement),
      ],
    );
  }
}
