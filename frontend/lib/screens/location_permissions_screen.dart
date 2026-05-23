import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';

class LocationPermissionsScreen extends ConsumerStatefulWidget {
  const LocationPermissionsScreen({super.key});

  @override
  ConsumerState<LocationPermissionsScreen> createState() => _LocationPermissionsScreenState();
}

class _LocationPermissionsScreenState extends ConsumerState<LocationPermissionsScreen> {
  bool _preciseLocation = true;
  bool _backgroundLocation = true;
  bool _locationAlerts = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final mutedTextColor = AppTheme.getTextColor(context, muted: true);
    final surfaceColor = AppTheme.getSurfaceColor(context);
    final backgroundColor = AppTheme.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
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
                        'Location Permissions',
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

              // Permission Status Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Always Allow',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SafePath can access your location at all times for safety features',
                              style: TextStyle(
                                fontSize: 13,
                                color: mutedTextColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Permission Settings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Permission Settings',
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
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildToggleTile(
                        icon: Icons.gps_fixed,
                        title: 'Precise Location',
                        subtitle: 'Use GPS for accurate location tracking',
                        value: _preciseLocation,
                        onChanged: (value) => setState(() => _preciseLocation = value),
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                      Divider(
                        color: isDark ? const Color(0xFF2D3A5C) : const Color(0xFFE8ECF4),
                        height: 1,
                        indent: 70,
                      ),
                      _buildToggleTile(
                        icon: Icons.access_time_filled,
                        title: 'Background Location',
                        subtitle: 'Access location when app is closed',
                        value: _backgroundLocation,
                        onChanged: (value) => setState(() => _backgroundLocation = value),
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                      Divider(
                        color: isDark ? const Color(0xFF2D3A5C) : const Color(0xFFE8ECF4),
                        height: 1,
                        indent: 70,
                      ),
                      _buildToggleTile(
                        icon: Icons.notifications,
                        title: 'Location Alerts',
                        subtitle: 'Notify when location is being shared',
                        value: _locationAlerts,
                        onChanged: (value) => setState(() => _locationAlerts = value),
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // How We Use Location
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'How We Use Location',
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
                  child: Column(
                    children: [
                      _buildInfoTile(
                        icon: Icons.sos,
                        title: 'Emergency SOS',
                        description: 'Share your exact location during SOS alerts',
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        icon: Icons.people,
                        title: 'Safe Circle',
                        description: 'Share location with trusted contacts',
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        icon: Icons.map,
                        title: 'Journey Tracking',
                        description: 'Track your route and estimated arrival',
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Open System Settings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Geolocator.openAppSettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Open System Settings'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4A90E2), size: 22),
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
                    fontSize: 12,
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String description,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
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
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: mutedTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

