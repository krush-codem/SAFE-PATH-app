import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../routing/app_router.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _locationSharing = true;

  @override
  Widget build(BuildContext context) {
    final guardiansAsync = ref.watch(guardiansProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final mutedTextColor = AppTheme.getTextColor(context, muted: true);
    final surfaceColor = AppTheme.getSurfaceColor(context);
    final backgroundColor = AppTheme.getBackgroundColor(context);
    
    final guardianCount = guardiansAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: textColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Title and Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage location sharing, app permissions, and data settings.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: mutedTextColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Location Sharing Section
              _buildSectionTitle('Location Sharing', textColor),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Location Sharing Toggle
                      _buildToggleTile(
                        icon: Icons.location_on,
                        iconColor: const Color(0xFF4A90E2),
                        title: 'Location Sharing',
                        subtitle: 'Allow SafePath to share your location with emergency contacts and trusted circles.',
                        value: _locationSharing,
                        onChanged: (value) => setState(() => _locationSharing = value),
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                        surfaceColor: surfaceColor,
                      ),
                      
                      Divider(
                        color: isDark ? const Color(0xFF2D3A5C) : const Color(0xFFE8ECF4),
                        height: 1,
                        indent: 70,
                      ),

                      // Manage Location Sharing
                      _buildNavigationTile(
                        icon: Icons.shield,
                        iconColor: const Color(0xFF7BB8F0),
                        title: 'Manage Location Sharing',
                        subtitle: 'Control who sees your live location and when.\nActive Circles: 1 | Emergency Contacts: $guardianCount',
                        onTap: () => context.push(AppRoutes.manageLocationSharing),
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App Permissions Section
              _buildSectionTitle('App Permissions', textColor),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Location Permissions
                      _buildNavigationTile(
                        icon: Icons.shield,
                        iconColor: const Color(0xFF7BB8F0),
                        title: 'Location Permissions',
                        subtitle: 'Precise Location Access (Always Allow)\nSafePath uses location to enhance safety features.',
                        onTap: () => context.push(AppRoutes.locationPermissions),
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),

                      Divider(
                        color: isDark ? const Color(0xFF2D3A5C) : const Color(0xFFE8ECF4),
                        height: 1,
                        indent: 70,
                      ),

                      // Microphone Access
                      _buildNavigationTile(
                        icon: Icons.mic,
                        iconColor: const Color(0xFF8B92A8),
                        title: 'Microphone Access',
                        subtitle: 'Allow while using',
                        onTap: () => context.push(AppRoutes.microphoneAccess),
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),

                      Divider(
                        color: isDark ? const Color(0xFF2D3A5C) : const Color(0xFFE8ECF4),
                        height: 1,
                        indent: 70,
                      ),

                      // Contacts Access
                      _buildNavigationTile(
                        icon: Icons.contacts,
                        iconColor: const Color(0xFF8B92A8),
                        title: 'Contacts Access',
                        subtitle: 'Allow while using',
                        onTap: () => context.push(AppRoutes.contactsAccess),
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Recent Location Activity Section
              _buildSectionTitle('Recent Location Activity', textColor),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildActivityTile(
                    icon: Icons.map,
                    iconBackgroundColor: const Color(0xFF4CAF50),
                    title: 'SafePath accessed your location',
                    subtitle: '2 minutes ago',
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
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

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color mutedTextColor,
    required Color surfaceColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: mutedTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4CAF50),
            activeTrackColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF8B92A8).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: mutedTextColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: mutedTextColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required Color iconBackgroundColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackgroundColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconBackgroundColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
