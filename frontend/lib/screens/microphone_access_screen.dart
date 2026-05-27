import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MicrophoneAccessScreen extends ConsumerStatefulWidget {
  const MicrophoneAccessScreen({super.key});

  @override
  ConsumerState<MicrophoneAccessScreen> createState() =>
      _MicrophoneAccessScreenState();
}

class _MicrophoneAccessScreenState
    extends ConsumerState<MicrophoneAccessScreen> {
  final bool _whileUsing = true;
  bool _sosRecording = true;
  bool _safetyCheck = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final mutedTextColor = AppTheme.getTextColor(context, muted: true);
    final surfaceColor = AppTheme.getSurfaceColor(context);

    return Scaffold(
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
                        'Microphone Access',
                        style: theme.textTheme.displaySmall,
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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic,
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
                              'Allowed While Using',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SafePath can access microphone when app is in use',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Feature Settings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Microphone Features',
                  style: theme.textTheme.titleLarge,
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
                        icon: Icons.sos,
                        title: 'SOS Audio Recording',
                        subtitle: 'Record audio during emergency SOS alerts',
                        value: _sosRecording,
                        onChanged: (value) =>
                            setState(() => _sosRecording = value),
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                        primaryColor: theme.colorScheme.primary,
                      ),
                      Divider(
                        color: theme.dividerColor,
                        height: 1,
                        indent: 70,
                      ),
                      _buildToggleTile(
                        icon: Icons.check_circle,
                        title: 'Safety Check Voice',
                        subtitle: 'Use voice commands for safety checks',
                        value: _safetyCheck,
                        onChanged: (value) =>
                            setState(() => _safetyCheck = value),
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                        primaryColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // How We Use Microphone
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'How We Use Microphone',
                  style: theme.textTheme.titleLarge,
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
                        icon: Icons.security,
                        title: 'Emergency Evidence',
                        description:
                            'Audio recordings during SOS are encrypted and stored securely',
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                        primaryColor: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        icon: Icons.privacy_tip,
                        title: 'Your Privacy',
                        description:
                            'We never record audio without your knowledge',
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                        primaryColor: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        icon: Icons.delete,
                        title: 'Data Control',
                        description:
                            'You can delete recorded audio anytime from settings',
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                        primaryColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recording History
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Recordings',
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(onPressed: () {}, child: const Text('View All')),
                  ],
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
                      _buildRecordingTile(
                        title: 'SOS Alert Recording',
                        duration: '2:34',
                        time: 'Yesterday, 8:45 PM',
                        icon: Icons.emergency,
                        iconColor: theme.colorScheme.secondary,
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                      Divider(
                        color: theme.dividerColor,
                        height: 1,
                      ),
                      _buildRecordingTile(
                        title: 'Safety Check Voice',
                        duration: '0:15',
                        time: 'Today, 10:30 AM',
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
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
                    onPressed: () {},
                    icon: const Icon(Icons.settings),
                    label: const Text('Open System Settings'),
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
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 22),
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
                  style: TextStyle(fontSize: 12, color: mutedTextColor),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
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
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
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
                style: TextStyle(fontSize: 13, color: mutedTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingTile({
    required String title,
    required String duration,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
                  time,
                  style: TextStyle(fontSize: 12, color: mutedTextColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              duration,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
