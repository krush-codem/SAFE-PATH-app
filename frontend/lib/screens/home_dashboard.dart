import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/journey_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/dynamic_ui.dart';
import '../theme/app_theme.dart';
import '../routing/app_router.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journeyState = ref.watch(journeyProvider);
    final guardiansAsync = ref.watch(guardiansProvider);
    final profile = ref.watch(profileProvider).value;
    final bool isJourneyActive = journeyState.status == JourneyStatus.active;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.shield,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Safe Path',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        UserAvatar(
                          url: profile?.avatarUrl,
                          name: profile?.fullName,
                          size: 36,
                          showStatus: true,
                          isOnline: true,
                        ),
                      ],
                    ),
                  ),

                  // Location Picker Card
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor, width: 1),
                    ),
                    child: Column(
                      children: [
                        _LocationField(
                          label: 'FROM',
                          value: journeyState.origin ?? 'Current Location',
                          icon: Icons.my_location,
                          onTap: isJourneyActive
                              ? null
                              : () => context.push(
                                  '/location_picker?isOrigin=true',
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Divider(color: theme.dividerColor, indent: 40),
                        ),
                        _LocationField(
                          label: 'TO',
                          value: journeyState.destination ?? 'Where to?',
                          icon: Icons.location_on,
                          isDestination: true,
                          onTap: isJourneyActive
                              ? null
                              : () => context.push(
                                  '/location_picker?isOrigin=false',
                                ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatusChip(
                              icon: Icons.circle,
                              label: isJourneyActive
                                  ? 'LIVE TRACKING ACTIVE'
                                  : 'SYSTEM READY',
                              color: isJourneyActive
                                  ? colorScheme.primary
                                  : AppColors.successEmerald,
                            ),
                            _StatusChip(
                              icon: Icons.wifi,
                              label: 'SIGNAL: STRONG',
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Stories / Status Feed (Only visible during Journey)
                  if (isJourneyActive)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE UPDATES',
                            style: theme.textTheme.bodySmall?.copyWith(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: guardiansAsync.when(
                              data: (guardians) {
                                final permittedGuardians = guardians
                                    .where(
                                      (g) => journeyState.locationPermissionIds
                                          .contains(g.id),
                                    )
                                    .toList();

                                return ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _StoryItem(
                                      label: 'Me',
                                      icon: Icons.person,
                                      color: colorScheme.primary,
                                      isMe: true,
                                    ),
                                    ...permittedGuardians.map(
                                      (g) => _StoryItem(
                                        label: g.fullName.split(' ')[0],
                                        icon: Icons.verified_user,
                                        color: g.isOnline ? AppColors.successEmerald : colorScheme.onSurface.withValues(alpha: 0.2),
                                        isOnline: g.isOnline,
                                      ),
                                    ),
                                    if (permittedGuardians.isEmpty)
                                      const _StoryItem(
                                        label: 'System',
                                        icon: Icons.security,
                                        color: Colors.orangeAccent,
                                      ),
                                    _StoryItem(
                                      label: 'Update',
                                      icon: Icons.add,
                                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                                      isAdd: true,
                                      onTap: () =>
                                          context.go(AppRoutes.safeCircleChat),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              error: (_, _) => const SizedBox.shrink(),
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
                              onTap:
                                  (journeyState.origin != null &&
                                      journeyState.destination != null)
                                  ? () => context.push('/timer_setup')
                                  : null,
                              child: Opacity(
                                opacity:
                                    (journeyState.origin != null &&
                                        journeyState.destination != null)
                                    ? 1.0
                                    : 0.5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorScheme.onSurface,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.play_circle_fill,
                                        color: colorScheme.onSurface,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'LET\'S START',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else if (journeyState.status == JourneyStatus.pinging)
                            GestureDetector(
                              onTap: () => context.push('/safety_check'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orangeAccent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.security,
                                      color: Colors.orangeAccent,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'OTP REQUIRED',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        Text(
                                          '${(journeyState.timeRemainingSeconds ?? 0) ~/ 60}m ${(journeyState.timeRemainingSeconds ?? 0) % 60}s REMAINING',
                                          style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.near_me,
                              color: colorScheme.primary,
                              size: 48,
                            ),
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
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: theme.dividerColor, width: 1),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CURRENT TIME',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        journeyState.currentTime,
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (isJourneyActive &&
                                      journeyState.nextCheckCountdownSeconds !=
                                          null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        '${(journeyState.nextCheckCountdownSeconds! / 60).floor()}m ${journeyState.nextCheckCountdownSeconds! % 60}s LEFT',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    color: colorScheme.primary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isJourneyActive
                                        ? 'Safe Path: Optimized for High Lighting'
                                        : 'Select Destination to Begin',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.onSurface,
                                        foregroundColor: colorScheme.surface,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        context.go(AppRoutes.safeCircleChat);
                                      },
                                      icon: const Icon(
                                        Icons.chat_bubble,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'SAFE CHAT',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isJourneyActive &&
                                      journeyState.lastOtpVerificationTime !=
                                          null)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.error
                                                .withValues(alpha: 0.1),
                                            foregroundColor: colorScheme.error,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              side: BorderSide(
                                                color: colorScheme.error,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(journeyProvider.notifier)
                                                .cancelJourney();
                                          },
                                          icon: const Icon(
                                            Icons.cancel,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'CANCEL',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11,
                                            ),
                                          ),
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
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFFFB38E).withValues(alpha: 0.3), width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB38E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'SOS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MANUAL SOS',
                                      style: TextStyle(
                                        color: Color(0xFFFFB38E),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'TAP TO ALERT CONTACTS',
                                      style: TextStyle(
                                        color: Color(0xFFFFB38E),
                                        fontSize: 10,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFB38E),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  _showSosWarningDialog(context, ref);
                                },
                                child: const Text(
                                  'TRIGGER',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFFB38E),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Confirm SOS',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Warning: Misuse of the SOS trigger is prohibited. This will immediately send your current location and an alert message to all SOS members in your Safe Circle and via SMS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB38E),
              foregroundColor: Colors.black,
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              ref.read(journeyProvider.notifier).triggerSOS();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('SOS TRIGGERED: Alerts sent to contacts.'),
                  backgroundColor: colorScheme.error,
                ),
              );
            },
            child: const Text(
              'PROCEED',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isDestination && onTap != null)
            Icon(Icons.edit, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), size: 16),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 8, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
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
  final bool isOnline;
  final VoidCallback? onTap;

  const _StoryItem({
    required this.label,
    required this.icon,
    required this.color,
    this.isMe = false,
    this.isAdd = false,
    this.isOnline = false,
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
            Stack(
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
                if (isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0F1724), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
