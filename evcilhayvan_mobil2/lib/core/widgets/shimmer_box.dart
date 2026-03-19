import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// CachedNetworkImage placeholder olarak kullan — sola-sağa kayan shimmer dalgası.
///
/// ```dart
/// CachedNetworkImage(
///   placeholder: (_, __) => ShimmerBox(height: 200),
///   ...
/// )
/// ```
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.height,
    this.width,
    this.borderRadius = 0,
  });

  final double? height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2840) : const Color(0xFFE8E6FF);
    final highlightColor = isDark ? const Color(0xFF3D3A5C) : const Color(0xFFF5F4FF);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        color: baseColor,
        child: Container(color: baseColor)
            .animate(onPlay: (ctrl) => ctrl.repeat())
            .shimmer(
              duration: 1200.ms,
              color: highlightColor,
              angle: 0.3,
            ),
      ),
    );
  }
}

/// Birden fazla shimmer kutusu ile kart iskelet yükleme efekti.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.imageHeight = 180,
    this.borderRadius = 16,
    this.margin,
  });

  final double imageHeight;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1C30) : const Color(0xFFF0EFFF);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: imageHeight, borderRadius: borderRadius),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, width: 140, borderRadius: 4),
                const SizedBox(height: 8),
                ShimmerBox(height: 10, width: 100, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
