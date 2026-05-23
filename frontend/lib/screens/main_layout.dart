import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../routing/app_router.dart';
import '../widgets/dynamic_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MainLayout extends StatelessWidget {
  final Widget child;
  
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppTheme.getBackgroundColor(context);
    final surfaceColor = AppTheme.getSurfaceColor(context);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: child,
      extendBody: !kIsWeb, // Disable extendBody on web to avoid transparency issues
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor, // Completely opaque on Web
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: kIsWeb 
          ? _buildNavContent(context, currentPath, isDark)
          : ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SafeBackdrop(
                blur: 30,
                fallbackColor: surfaceColor.withValues(alpha: 0.95),
                child: Container(
                  color: surfaceColor.withValues(alpha: 0.9),
                  child: _buildNavContent(context, currentPath, isDark),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildNavContent(BuildContext context, String currentPath, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.explore_outlined, 
              label: 'JOURNEY', 
              route: AppRoutes.home, 
              currentPath: currentPath,
              isDark: isDark,
            ),
            _NavItem(
              icon: Icons.shield_outlined, 
              label: 'GUARD', 
              route: AppRoutes.cyber, 
              currentPath: currentPath,
              isDark: isDark,
            ),
            _NavItem(
              icon: Icons.person_outline, 
              label: 'PROFILE', 
              route: AppRoutes.settings, 
              currentPath: currentPath,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentPath;
  final bool isDark;

  const _NavItem({
    required this.icon, 
    required this.label, 
    required this.route, 
    required this.currentPath,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = currentPath.startsWith(route);
    
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = isDark ? Colors.white38 : const Color(0xFF8B92A8);
    
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive ? BoxDecoration(
          color: activeColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : inactiveColor),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                fontSize: 10, 
                color: isActive ? activeColor : inactiveColor, 
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
