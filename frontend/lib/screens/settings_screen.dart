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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final guardiansAsync = ref.watch(guardiansProvider);
    final theme = Theme.of(context);

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
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'ACCOUNT'),
                  _buildSettingsCard(context, [
                    _buildSettingsTile(
                      context,
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Change your name and personal details',
                      onTap: () => context.push(AppRoutes.editProfile),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.history,
                      title: 'History',
                      subtitle: 'View your past journeys',
                      onTap: () => context.push(AppRoutes.history),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Security',
                      subtitle: 'Password, Biometrics & 2FA',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'SAFETY & PROTECTION'),
                  _buildSettingsCard(context, [
                    _buildSettingsTile(
                      context,
                      icon: Icons.safety_check,
                      title: 'Emergency Contacts',
                      subtitle: '${guardiansAsync.value?.length ?? 0} active lifelines',
                      onTap: () => context.push(AppRoutes.manageGuardians),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.touch_app_outlined,
                      title: 'SOS Sensitivity',
                      subtitle: 'Vibration and tap triggers',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'SYSTEM'),
                  _buildSettingsCard(context, [
                    _buildSettingsTile(
                      context,
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Alerts, sound and vibration',
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Theme, colors and layout',
                      onTap: () => context.push(AppRoutes.appearance),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy',
                      subtitle: 'Location sharing & permissions',
                      onTap: () => context.push(AppRoutes.privacy),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context, ref),
                  const SizedBox(height: 12),
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
      backgroundColor: kIsWeb ? Colors.transparent : theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRRect(
        child: SafeBackdrop(
          blur: 10,
          fallbackColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Text(
        'SETTINGS',
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: theme.textTheme.displayLarge?.color,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AsyncValue<Profile?> profileAsync) {
    final theme = Theme.of(context);
    return profileAsync.when(
      data: (profile) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withValues(alpha: 0.1),
                image: profile?.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(profile!.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: profile?.avatarUrl == null
                  ? Icon(Icons.person, size: 40, color: theme.primaryColor)
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (profile?.fullName?.isNotEmpty == true) ? profile!.fullName : 'Safe User',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.displayLarge?.color,
                    ),
                  ),
                  Text(
                    (profile?.email?.isNotEmpty == true) ? profile!.email : ((profile?.phoneNumber?.isNotEmpty == true) ? profile!.phoneNumber! : 'user@safepath.com'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PREMIUM PROTECTION',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: theme.primaryColor,
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading profile'),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: theme.primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: theme.dividerColor.withValues(alpha: 0.2), size: 20),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: TextButton(
        onPressed: () => _showLogoutConfirmation(context, ref),
        style: TextButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7), size: 20),
            const SizedBox(width: 12),
            Text(
              'LOG OUT',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: TextButton(
        onPressed: () => _showDeleteConfirmation(context, ref),
        style: TextButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            const SizedBox(width: 12),
            Text(
              'DELETE ACCOUNT',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Log Out?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.manrope(color: theme.textTheme.bodySmall?.color)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text('LOG OUT', style: GoogleFonts.manrope(color: theme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Account?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.redAccent),
        ),
        content: const Text(
          'This action is permanent and will delete all your data. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('NO, KEEP IT', style: GoogleFonts.manrope(color: theme.textTheme.bodySmall?.color)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).deleteAccount();
            },
            child: const Text('YES, DELETE', style: Color(0xFFD32F2F) != null ? TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold) : null),
          ),
        ],
      ),
    );
  }
}
