import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeSettings {
  final ThemeMode mode;
  final Color primaryColor;
  final Color secondaryColor;

  const ThemeSettings({
    required this.mode,
    required this.primaryColor,
    required this.secondaryColor,
  });

  ThemeSettings copyWith({
    ThemeMode? mode,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    return const ThemeSettings(
      mode: ThemeMode.dark,
      primaryColor: Color(0xFF4A90E2),
      secondaryColor: Color(0xFF1E2633),
    );
  }

  void updateMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
  }

  void updateColors(Color primary, Color secondary) {
    state = state.copyWith(primaryColor: primary, secondaryColor: secondary);
  }

  void setTheme(ThemeMode mode, Color primary, Color secondary) {
    state = ThemeSettings(
      mode: mode,
      primaryColor: primary,
      secondaryColor: secondary,
    );
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeSettings>(() {
  return ThemeNotifier();
});
