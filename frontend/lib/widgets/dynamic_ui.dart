import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;

/// A widget that safely applies blur on Mobile but remains a simple transparent
/// layer on Web to prevent CanvasKit engine crashes.
class SafeBackdrop extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? fallbackColor;

  const SafeBackdrop({
    super.key,
    required this.child,
    this.blur = 10,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        color: fallbackColor ?? Colors.black.withValues(alpha: 0.5),
        child: child,
      );
    }
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: child,
    );
  }
}

/// A premium, dynamic avatar that shows a profile image or initials.
class UserAvatar extends StatelessWidget {
  final String? url;
  final String? name;
  final double size;
  final bool showStatus;
  final bool isOnline;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.url,
    this.name,
    this.size = 40,
    this.showStatus = false,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String initials = '';
    if (name != null && name!.isNotEmpty) {
      final parts = name!.trim().split(' ');
      if (parts.length > 1) {
        initials = (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
      } else if (parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF5C79FF).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: url != null && url!.isNotEmpty
                  ? Image.network(
                      url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitials(initials),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SkeletonBox(shape: BoxShape.circle);
                      },
                    )
                  : _buildInitials(initials),
            ),
          ),
          if (showStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFF4CAF50) : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitials(String initials) {
    return Container(
      color: const Color(0xFF111111),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// A "Frosted Glass" card optimized for all platforms.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.05,
    this.borderRadius,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);
    
    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: SafeBackdrop(
        blur: blur,
        fallbackColor: const Color(0xFF111111).withValues(alpha: 0.8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: kIsWeb 
              ? Colors.transparent // Backdrop handled by SafeBackdrop fallback on Web
              : Colors.white.withValues(alpha: opacity),
            borderRadius: effectiveBorderRadius,
            border: border ?? Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Shimmering placeholder that gracefully degrades on Web.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFF111111);
    final highlightColor = const Color(0xFF222222);

    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: kIsWeb ? highlightColor : Colors.white,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle 
          ? (borderRadius ?? BorderRadius.circular(8)) 
          : null,
      ),
    );

    if (kIsWeb) return box; // Disable animation on web to prevent CanvasKit crashes

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: box,
    );
  }
}
