import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  bool _isCustom = false;
  bool _showHexSpectrum = true;
  Color _hoveredColor = Colors.transparent;

  final List<Color> _accentColors = [
    const Color(0xFF1A3A5C),
    const Color(0xFF4A90E2),
    const Color(0xFF7BB8F0),
    const Color(0xFFF25C05),
    const Color(0xFF8B4513),
  ];

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _applyTheme(ThemeMode mode, Color primary, Color secondary) {
    ref.read(themeProvider.notifier).setTheme(mode, primary, secondary);
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeProvider);
    final isDark = themeSettings.mode == ThemeMode.dark;
    final textColor = AppTheme.getTextColor(context);
    final mutedTextColor = AppTheme.getTextColor(context, muted: true);
    final surfaceColor = AppTheme.getSurfaceColor(context);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isDark, textColor, mutedTextColor, surfaceColor),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Display Theme', textColor),
                    const SizedBox(height: 8),
                    _buildSectionDesc(
                      'Optimize your visual experience for day or night operations. The system adjusts contrast for maximum legibility.',
                      mutedTextColor,
                    ),
                    const SizedBox(height: 20),
                    
                    // Theme Cards - Apply immediately on tap
                    _buildThemeCard(
                      context,
                      title: 'Sentinel Light',
                      subtitle: 'DEFAULT / HIGH TRUST',
                      isLight: true,
                      isSelected: !isDark,
                      onTap: () => _applyTheme(ThemeMode.light, themeSettings.primaryColor, themeSettings.secondaryColor),
                    ),
                    const SizedBox(height: 12),
                    _buildThemeCard(
                      context,
                      title: 'Sentinel Dark',
                      subtitle: 'LOW LIGHT PROTECTION',
                      isLight: false,
                      isSelected: isDark,
                      onTap: () => _applyTheme(ThemeMode.dark, themeSettings.primaryColor, themeSettings.secondaryColor),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Custom Accent Section
                    _buildSectionTitle('Custom Accent', textColor),
                    const SizedBox(height: 8),
                    _buildSectionDesc(
                      'Personalize your tactical interface. This color will be applied to critical highlights and actionable alerts.',
                      mutedTextColor,
                    ),
                    const SizedBox(height: 20),
                    
                    // Color Circles with Hover
                    Row(
                      children: [
                        ..._accentColors.map((color) => _buildColorCircle(
                          context,
                          color,
                          themeSettings.primaryColor,
                        )),
                        const SizedBox(width: 8),
                        _buildCustomPill(context, themeSettings.primaryColor),
                      ],
                    ),
                    
                    // Show hex of hovered color
                    if (_hoveredColor != Colors.transparent)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Hovered: ${_colorToHex(_hoveredColor)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // HEX SPECTRUM / PALLET Tabs
                    _buildHexSpectrum(context, themeSettings.primaryColor),
                    
                    const SizedBox(height: 32),
                    
                    // Apply Changes Button
                    _buildApplyButton(context, themeSettings),
                    
                    const SizedBox(height: 12),
                    
                    // Reset to Default
                    Center(
                      child: GestureDetector(
                        onTap: () => _resetToDefault(),
                        child: Text(
                          'Reset to Default',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    _buildFooter(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color textColor, Color mutedTextColor, Color surfaceColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield,
                      color: textColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SAFE PATH',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings,
                  color: textColor,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'SECURITY HUB',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: mutedTextColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'System Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Appearance',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }

  Widget _buildSectionDesc(String desc, Color mutedTextColor) {
    return Text(
      desc,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: mutedTextColor,
        height: 1.5,
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isLight,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cardColor = isLight ? AppColors.lightBackground : AppColors.surfaceDark;
    final onCardColor = isLight ? AppColors.textHighLight : AppColors.textHighDark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isLight ? Colors.white : AppColors.darkBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.all(6),
                    width: 20,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 6, right: 6, bottom: 6),
                    width: 30,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.all(6),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                ],
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
                      fontWeight: FontWeight.w700,
                      color: onCardColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCircle(BuildContext context, Color color, Color selectedColor) {
    final isSelected = selectedColor.value == color.value;
    final textColor = AppTheme.getTextColor(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredColor = color),
      onExit: (_) => setState(() => _hoveredColor = Colors.transparent),
      child: GestureDetector(
        onTap: () {
          final themeSettings = ref.read(themeProvider);
          _applyTheme(themeSettings.mode, color, themeSettings.secondaryColor);
          setState(() => _isCustom = false);
        },
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? textColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check, 
                  color: Colors.white, 
                  size: 18,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCustomPill(BuildContext context, Color selectedColor) {
    final surfaceColor = AppTheme.getSurfaceColor(context);
    final textColor = AppTheme.getTextColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredColor = selectedColor),
      onExit: (_) => setState(() => _hoveredColor = Colors.transparent),
      child: GestureDetector(
        onTap: () => _showAdvancedColorPicker(isDark, selectedColor),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isCustom 
                ? Theme.of(context).colorScheme.primary
                : surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Custom',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isCustom 
                ? Colors.white 
                : textColor,
            ),
          ),
        ),
      ),
    );
  }

  void _showAdvancedColorPicker(bool isDark, Color currentColor) {
    showDialog(
      context: context,
      builder: (context) => _AdvancedColorPickerDialog(
        initialColor: currentColor,
        isDark: isDark,
        onColorSelected: (color) {
          final themeSettings = ref.read(themeProvider);
          _applyTheme(themeSettings.mode, color, themeSettings.secondaryColor);
          setState(() => _isCustom = true);
        },
      ),
    );
  }

  Widget _buildHexSpectrum(BuildContext context, Color primaryColor) {
    final surfaceColor = AppTheme.getSurfaceColor(context);
    final textColor = AppTheme.getTextColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3A5C) : const Color(0xFFE8ECF4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showHexSpectrum = true),
                child: Text(
                  'HEX SPECTRUM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: _showHexSpectrum ? FontWeight.w700 : FontWeight.w600,
                    color: _showHexSpectrum 
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFF8B92A8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showAdvancedColorPicker(isDark, primaryColor),
                child: Text(
                  'PALLET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: !_showHexSpectrum ? FontWeight.w700 : FontWeight.w600,
                    color: !_showHexSpectrum 
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFF8B92A8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Gradient selector with current color indicator
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1A3A5C),
                  Color(0xFF4A90E2),
                  Color(0xFF7BB8F0),
                  Color(0xFFF25C05),
                  Color(0xFF8B4513),
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Current color indicator
                Positioned(
                  left: _getColorPosition(primaryColor),
                  top: 40,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Current hex display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.getBackgroundColor(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _colorToHex(primaryColor),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getColorPosition(Color color) {
    // Approximate position based on hue
    final hue = HSVColor.fromColor(color).hue;
    return (hue / 360) * 200 + 20;
  }

  Widget _buildApplyButton(BuildContext context, ThemeSettings settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () {
        _applyTheme(settings.mode, settings.primaryColor, settings.secondaryColor);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Theme applied successfully'),
            backgroundColor: AppTheme.getSurfaceColor(context),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? primaryColor : const Color(0xFF0D1527),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'Apply Changes',
            style: TextStyle(
              color: isDark ? const Color(0xFF0D1527) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  void _resetToDefault() {
    _applyTheme(ThemeMode.light, const Color(0xFF4A90E2), const Color(0xFF1E2633));
    setState(() => _isCustom = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset to default theme')),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final mutedTextColor = AppTheme.getTextColor(context, muted: true);
    return Column(
      children: [
        Text(
          '© 2024 VIGILANT SECURITY. ALL RIGHTS RESERVED.',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: mutedTextColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterLink('PRIVACY POLICY', mutedTextColor),
            const SizedBox(width: 24),
            _buildFooterLink('TERMS OF SERVICE', mutedTextColor),
            const SizedBox(width: 24),
            _buildFooterLink('SUPPORT', mutedTextColor),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text, Color mutedTextColor) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: mutedTextColor,
        letterSpacing: 0.5,
      ),
    );
  }
}

// Advanced Color Picker Dialog like the image
class _AdvancedColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final bool isDark;
  final Function(Color) onColorSelected;

  const _AdvancedColorPickerDialog({
    required this.initialColor,
    required this.isDark,
    required this.onColorSelected,
  });

  @override
  State<_AdvancedColorPickerDialog> createState() => _AdvancedColorPickerDialogState();
}

class _AdvancedColorPickerDialogState extends State<_AdvancedColorPickerDialog> {
  late Color _selectedColor;
  late double _hue;
  late double _saturation;
  late double _value;

  final List<Color> _paletteColors = [
    const Color(0xFF0D99FF),
    const Color(0xFF22D3EE),
    const Color(0xFFF97316),
    const Color(0xFFF1F5F9),
    const Color(0xFF1F2937),
    const Color(0xFF1F2934),
    const Color(0xFFF97316),
    const Color(0xFFFF5F5F),
    const Color(0xFFFBF5EC),
    const Color(0xFFFF5FFF),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  void _updateColor() {
    setState(() {
      _selectedColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    });
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.isDark ? const Color(0xFF1E2633) : const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Theme Color Editor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Main content - Two columns
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Color Wheel
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Color Wheel Label
                      Row(
                        children: [
                          const Text(
                            'Color Wheel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Color Wheel
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              const Color(0xFFFF0000),
                              const Color(0xFFFFFF00),
                              const Color(0xFF00FF00),
                              const Color(0xFF00FFFF),
                              const Color(0xFF0000FF),
                              const Color(0xFFFF00FF),
                              const Color(0xFFFF0000),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white,
                                  HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor(),
                                ],
                              ),
                            ),
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                final center = const Offset(60, 60);
                                final position = details.localPosition;
                                final dx = position.dx - center.dx;
                                final dy = position.dy - center.dy;
                                final distance = sqrt(dx * dx + dy * dy);
                                
                                if (distance <= 60) {
                                  final angle = atan2(dy, dx);
                                  final hue = ((angle * 180 / pi) + 360) % 360;
                                  final saturation = (distance / 60).clamp(0.0, 1.0);
                                  
                                  setState(() {
                                    _hue = hue;
                                    _saturation = saturation;
                                  });
                                  _updateColor();
                                }
                              },
                              child: Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _selectedColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Brightness slider
                      const Text(
                        'Brightness',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black,
                              HSVColor.fromAHSV(1.0, _hue, _saturation, 1.0).toColor(),
                            ],
                          ),
                        ),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 0,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10,
                              elevation: 0,
                            ),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: _value,
                            min: 0,
                            max: 1,
                            activeColor: Colors.transparent,
                            inactiveColor: Colors.transparent,
                            thumbColor: Colors.white,
                            onChanged: (value) {
                              setState(() => _value = value);
                              _updateColor();
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Named Swatches
                      const Text(
                        'Named Swatches',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNamedSwatch('Primary', _selectedColor),
                      const SizedBox(height: 8),
                      _buildNamedSwatch('Accent Light', HSVColor.fromColor(_selectedColor).withValue(0.8).toColor()),
                      const SizedBox(height: 8),
                      _buildNamedSwatch('Background', HSVColor.fromColor(_selectedColor).withValue(0.1).toColor()),
                    ],
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // Right column - Current Selection & Core Palette
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Selection',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Color preview with values
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildColorValueRow('Hex:', _colorToHex(_selectedColor)),
                                const SizedBox(height: 4),
                                _buildColorValueRow('R:', '${_selectedColor.red}'),
                                const SizedBox(height: 4),
                                _buildColorValueRow('G:', '${_selectedColor.green}'),
                                const SizedBox(height: 4),
                                _buildColorValueRow('B:', '${_selectedColor.blue}'),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildColorValueRow('H:', '${_hue.toInt()}'),
                              const SizedBox(height: 4),
                              _buildColorValueRow('S:', '${(_saturation * 100).toInt()}'),
                              const SizedBox(height: 4),
                              _buildColorValueRow('V:', '${(_value * 100).toInt()}'),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Core Palette
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Core Palette',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.add, color: Colors.white70, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.add, color: Colors.white70, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Palette grid
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _paletteColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                                final hsv = HSVColor.fromColor(color);
                                _hue = hsv.hue;
                                _saturation = hsv.saturation;
                                _value = hsv.value;
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  color: Colors.black.withValues(alpha: 0.5),
                                  child: Text(
                                    _colorToHex(color),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Named Swatches (right side)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Named Swatches',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.add, color: Colors.white70, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildNamedSwatch('Primary', _selectedColor),
                      const SizedBox(height: 8),
                      _buildNamedSwatch('Accent Light', HSVColor.fromColor(_selectedColor).withValue(0.8).toColor()),
                      const SizedBox(height: 8),
                      _buildNamedSwatch('Background', HSVColor.fromColor(_selectedColor).withValue(0.1).toColor()),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onColorSelected(_selectedColor);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D99FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Color'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorValueRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNamedSwatch(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _colorToHex(color),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.add,
            color: Colors.white.withValues(alpha: 0.5),
            size: 16,
          ),
        ],
      ),
    );
  }
}
