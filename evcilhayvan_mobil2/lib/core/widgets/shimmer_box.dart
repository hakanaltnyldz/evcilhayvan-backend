import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// CachedNetworkImage placeholder — Plant Shop yeşil shimmer dalgası.
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
    final baseColor =
        isDark ? const Color(0xFF1A2E24) : const Color(0xFFD8F3DC);
    final highlightColor =
        isDark ? const Color(0xFF2D4A3E) : const Color(0xFFEDF7F0);

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
    final bgColor =
        isDark ? const Color(0xFF1E2E28) : const Color(0xFFEDF7F0);

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
