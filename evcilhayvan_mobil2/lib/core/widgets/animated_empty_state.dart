import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_palette.dart';

/// Sonuç bulunamadığında gösterilen animasyonlu boş durum widget'ı.
///
/// ```dart
/// AnimatedEmptyState(
///   icon: Icons.pets,
///   title: 'Henüz ilan yok',
///   subtitle: 'Yakında burada ilanlar görünecek.',
///   action: ElevatedButton(onPressed: ..., child: Text('İlan Oluştur')),
/// )
/// ```
class AnimatedEmptyState extends StatelessWidget {
  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
    this.iconSize = 72,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? AppPalette.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with float + pulse animation
            Icon(icon, size: iconSize, color: color.withOpacity(0.3))
                .animate(
                  onPlay: (ctrl) => ctrl.repeat(reverse: true, period: const Duration(seconds: 2)),
                )
                .moveY(begin: 0, end: -10, duration: 900.ms, curve: Curves.easeInOut)
                .then()
                .animate(
                  onPlay: (ctrl) => ctrl.repeat(reverse: true, period: const Duration(milliseconds: 1600)),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  duration: 800.ms,
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 24),

            // Title fades in
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, end: 0),

            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppPalette.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(delay: 350.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),
            ],

            if (action != null) ...[
              const SizedBox(height: 24),
              action!
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1)),
            ],
          ],
        ),
      ),
    );
  }
}
