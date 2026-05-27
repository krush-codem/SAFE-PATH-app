import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/dynamic_ui.dart';
import '../routing/app_router.dart';
import '../models/profile.dart';
import '../models/guardian.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(profileProvider);
    final guardiansAsync = ref.watch(guardiansProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, profileAsync),
                  const SizedBox(height: 40),
                  _buildSectionTitle(context, 'ACCOUNT'),
                  _buildSettingsCard(context, [
                    _buildSettingsTile(
                      context,
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal info',
                      onTap: () => context.push(AppRoutes.editProfile),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.history,
                      title: 'History',
                      subtitle: 'View past journeys',
                      onTap: () => context.push(AppRoutes.history),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Security',
                      subtitle: 'Password and biometric access',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'SAFETY'),
                  _buildSettingsCard(context, [
                    _buildSettingsTile(
                      context,
                      icon: Icons.safety_check,
                      title: 'Safe Circle',
                      subtitle: '${guardiansAsync.value?.length ?? 0} active contacts',
                      onTap: () => context.push(AppRoutes.manageGuardians),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.touch_app_outlined,
                      title: 'SOS Settings',
                      subtitle: 'Sensitivity and triggers',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'PREFERENCES'),
                  _buildSettingsCard(context, [
                    _buildSettingsTile(
                      context,
                      icon: Icons.notifications_none,
                      title: 'Alerts',
                      subtitle: 'Notifications and sound',
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Theme and visual style',
                      onTap: () => context.push(AppRoutes.appearance),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy',
                      subtitle: 'Location and data sharing',
                      onTap: () => context.push(AppRoutes.privacy),
                    ),
                  ]),
                  const SizedBox(height: 48),
                  _buildLogoutButton(context, ref),
                  const SizedBox(height: 16),
                  _buildDeleteAccountButton(context, ref),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text(
        'SETTINGS',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AsyncValue<Profile?> profileAsync) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return profileAsync.when(
      data: (profile) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.onSurface, width: 2),
                image: profile?.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(profile!.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: profile?.avatarUrl == null
                  ? Icon(Icons.person, size: 40, color: colorScheme.onSurface)
                  : null,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (profile?.fullName?.isNotEmpty == true) ? profile!.fullName : 'User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (profile?.email?.isNotEmpty == true) ? profile!.email : 'Unverified Account',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ACTIVE PROTECTION',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.surface,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator(color: colorScheme.onSurface, strokeWidth: 2)),
      error: (_, __) => Text('CRITICAL: Profiling Error', style: TextStyle(color: colorScheme.error)),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Icon(icon, color: colorScheme.onSurface, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      trailing: Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurface.withValues(alpha: 0.2), size: 14),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        onPressed: () => _showLogoutConfirmation(context, ref),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.2), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.power_settings_new_rounded, color: colorScheme.onSurface.withValues(alpha: 0.5), size: 20),
            const SizedBox(width: 12),
            Text(
              'LOG OUT',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: TextButton(
        onPressed: () => _showDeleteConfirmation(context, ref),
        style: TextButton.styleFrom(
          backgroundColor: colorScheme.error.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'DELETE ACCOUNT',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: colorScheme.error,
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Log Out?',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.onSurface, foregroundColor: colorScheme.surface),
            child: const Text('LOG OUT'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account?',
          style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.error, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'This action is permanent. All your data and contacts will be erased.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
