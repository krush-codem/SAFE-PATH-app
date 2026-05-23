import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../models/guardian.dart';

class ManageLocationSharingScreen extends ConsumerWidget {
  const ManageLocationSharingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardiansAsync = ref.watch(guardiansProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final mutedTextColor = AppTheme.getTextColor(context, muted: true);
    final surfaceColor = AppTheme.getSurfaceColor(context);
    final backgroundColor = AppTheme.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Manage Location Sharing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Active Circles',
                      '1',
                      Icons.people,
                      const Color(0xFF4A90E2),
                      surfaceColor,
                      textColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Emergency Contacts',
                      '${guardiansAsync.value?.length ?? 0}',
                      Icons.shield,
                      const Color(0xFF4CAF50),
                      surfaceColor,
                      textColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Active Circle Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Active Safe Circle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Color(0xFF4A90E2),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Safe Circle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Always sharing location',
                            style: TextStyle(
                              fontSize: 13,
                              color: mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: true,
                      onChanged: (value) {},
                      activeColor: const Color(0xFF4CAF50),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Emergency Contacts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/settings/manage_guardians'),
                    child: Text(
                      'Manage',
                      style: TextStyle(
                        color: const Color(0xFF4A90E2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Guardians List
            Expanded(
              child: guardiansAsync.when(
                data: (guardians) {
                  if (guardians.isEmpty) {
                    return Center(
                      child: Text(
                        'No emergency contacts added',
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: guardians.length,
                    itemBuilder: (context, index) {
                      final guardian = guardians[index];
                      return _buildGuardianTile(
                        guardian,
                        surfaceColor,
                        textColor,
                        mutedTextColor,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    'Failed to load contacts',
                    style: TextStyle(color: mutedTextColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color surfaceColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianTile(
    Guardian guardian,
    Color surfaceColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF4CAF50),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guardian.fullName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  guardian.phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Can see your location • SOS alerts enabled',
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedTextColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: true,
            onChanged: (value) {},
            activeColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }
}
