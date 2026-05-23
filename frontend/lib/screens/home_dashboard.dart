import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/journey_provider.dart';
import '../providers/auth_provider.dart';
import '../models/guardian.dart';
import '../routing/app_router.dart';
import '../widgets/dynamic_ui.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyState = ref.watch(journeyProvider);
    final guardiansAsync = ref.watch(guardiansProvider);
    final profileAsync = ref.watch(profileProvider);
    final bool isJourneyActive = journeyState.status != JourneyStatus.inactive;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Decor (Subtle) - Only on Mobile to avoid WebGL pressure
          if (!kIsWeb)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 400,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF5C79FF).withValues(alpha: 0.05),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
          
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5C79FF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shield, color: Color(0xFF5C79FF), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text('Safe Path', style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      profileAsync.when(
                        data: (profile) => UserAvatar(
                          url: profile?.avatarUrl,
                          name: profile?.fullName,
                          size: 36,
                          onTap: () => context.push('/edit_profile'),
                        ),
                        loading: () => const SkeletonBox(width: 36, height: 36, shape: BoxShape.circle),
                        error: (_, __) => const UserAvatar(size: 36),
                      ),
                    ],
                  ),
                ),
                
                // Location Picker Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _LocationField(
                          label: 'FROM',
                          value: journeyState.origin ?? 'Current Location',
                          icon: Icons.my_location,
                          onTap: isJourneyActive ? null : () => context.push('/location_picker?isOrigin=true'),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Divider(color: Colors.white10, indent: 40),
                        ),
                        _LocationField(
                          label: 'TO',
                          value: journeyState.destination ?? 'Where to?',
                          icon: Icons.location_on,
                          isDestination: true,
                          onTap: isJourneyActive ? null : () => context.push('/location_picker?isOrigin=false'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatusChip(
                              icon: Icons.circle, 
                              label: isJourneyActive ? 'LIVE TRACKING ACTIVE' : 'SYSTEM READY', 
                              color: isJourneyActive ? const Color(0xFF5C79FF) : const Color(0xFF4CAF50)
                            ),
                            const _StatusChip(icon: Icons.wifi, label: 'SIGNAL: STRONG', color: Colors.white38),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                // Stories / Status Feed (Only visible during Journey)
                if (isJourneyActive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LIVE UPDATES', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: guardiansAsync.when(
                            data: (guardians) {
                              final permittedGuardians = guardians.where(
                                (g) => journeyState.locationPermissionIds.contains(g.id)
                              ).toList();

                              return ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  const _StoryItem(label: 'Me', icon: Icons.person, color: Colors.blueAccent, isMe: true),
                                  ...permittedGuardians.map((g) => _StoryItem(
                                    label: g.fullName.split(' ')[0], 
                                    icon: Icons.verified_user, 
                                    color: Colors.greenAccent
                                  )),
                                  if (permittedGuardians.isEmpty)
                                    const _StoryItem(label: 'System', icon: Icons.security, color: Colors.orangeAccent),
                                  _StoryItem(
                                    label: 'Update', 
                                    icon: Icons.add, 
                                    color: Colors.white24, 
                                    isAdd: true,
                                    onTap: () => context.push('/safe_circle_chat'),
                                  ),
                                ],
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Main Map/CTA area
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (journeyState.status == JourneyStatus.inactive)
                           GestureDetector(
                             onTap: (journeyState.origin != null && journeyState.destination != null)
                               ? () => context.push('/timer_setup')
                               : null,
                             child: Opacity(
                               opacity: (journeyState.origin != null && journeyState.destination != null) ? 1.0 : 0.5,
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                 decoration: BoxDecoration(
                                   color: const Color(0xFF131A26),
                                   borderRadius: BorderRadius.circular(20),
                                   border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 2),
                                   boxShadow: [
                                     BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
                                   ],
                                 ),
                                 child: const Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Icon(Icons.play_circle_fill, color: Colors.blueAccent, size: 32),
                                     SizedBox(width: 12),
                                     Text('LET\'S START', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                   ],
                                 ),
                               ),
                             ),
                           )
                         else if (journeyState.status == JourneyStatus.pinging)
                           GestureDetector(
                             onTap: () => context.push('/safety_check'),
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                               decoration: BoxDecoration(
                                 color: const Color(0xFF2D1200),
                                 borderRadius: BorderRadius.circular(20),
                                 border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5), width: 2),
                                 boxShadow: [
                                   BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
                                 ],
                               ),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   const Icon(Icons.security, color: Colors.orangeAccent, size: 32),
                                   const SizedBox(width: 12),
                                   Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       const Text('OTP REQUIRED', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                       Text(
                                         '${(journeyState.timeRemainingSeconds ?? 0) ~/ 60}m ${(journeyState.timeRemainingSeconds ?? 0) % 60}s REMAINING',
                                         style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                       ),
                                     ],
                                   ),
                                 ],
                               ),
                             ),
                           )
                         else
                           // Show Animated Map Indicator or Progress if journey started
                           const Icon(Icons.near_me, color: Colors.blueAccent, size: 48),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Current Time & Next OTP Countdown
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2633),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CURRENT TIME', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                                    const SizedBox(height: 4),
                                    Text(
                                      journeyState.currentTime, 
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ),
                                if (isJourneyActive && journeyState.nextCheckCountdownSeconds != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                    child: Text(
                                      '${(journeyState.nextCheckCountdownSeconds! / 60).floor()}m ${journeyState.nextCheckCountdownSeconds! % 60}s LEFT', 
                                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10)
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.verified_user, color: Colors.blueAccent, size: 14),
                                const SizedBox(width: 8),
                                Text(
                                  isJourneyActive ? 'Safe Path: Optimized for High Lighting' : 'Select Destination to Begin', 
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFB3D7FF),
                                      foregroundColor: const Color(0xFF001B3A),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onPressed: () {
                                      context.push('/safe_circle_chat');
                                    },
                                    icon: const Icon(Icons.chat_bubble, size: 18),
                                    label: const Text('SAFE CHAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ),
                                 if (isJourneyActive && journeyState.lastOtpVerificationTime != null)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                                            foregroundColor: Colors.redAccent,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              side: const BorderSide(color: Colors.redAccent, width: 1),
                                            ),
                                          ),
                                          onPressed: () {
                                            ref.read(journeyProvider.notifier).cancelJourney();
                                          },
                                          icon: const Icon(Icons.cancel, size: 18),
                                          label: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Manual SOS Button
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D1200),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Container(
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(color: const Color(0xFFFFB38E), borderRadius: BorderRadius.circular(12)),
                               child: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2D1200), fontSize: 12)),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('MANUAL SOS', style: TextStyle(color: Color(0xFFFFB38E), fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('TAP TO ALERT CONTACTS', style: TextStyle(color: Color(0xFFFFB38E), fontSize: 10, letterSpacing: 1)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB38E),
                                foregroundColor: const Color(0xFF2D1200),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                _showSosWarningDialog(context, ref);
                              },
                              child: const Text('TRIGGER', style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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

  void _showSosWarningDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2633),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB38E), size: 28),
            SizedBox(width: 12),
            Text('Confirm SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Warning: Misuse of the SOS trigger is prohibited. This will immediately send your current location and an alert message to all SOS members in your Safe Circle and via SMS.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB38E),
              foregroundColor: const Color(0xFF2D1200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref.read(journeyProvider.notifier).triggerSOS();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SOS TRIGGERED: Alerts sent to contacts.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text('PROCEED', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDestination;
  final VoidCallback? onTap;

  const _LocationField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.isDestination = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (isDestination && onTap != null) const Icon(Icons.edit, color: Colors.white38, size: 16),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 8, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isMe;
  final bool isAdd;
  final VoidCallback? onTap;

  const _StoryItem({
    required this.label, 
    required this.icon, 
    required this.color, 
    this.isMe = false, 
    this.isAdd = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
