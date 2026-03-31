import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/core/theme/theme_extensions.dart';
import 'interactive_scale.dart';

/// Premium kart widget — InteractiveScale + accent bar + modern shadow.
///
/// ```dart
/// PremiumCard(
///   onTap: () {},
///   accentColor: Color(0xFF52B788),
///   child: Text('Hello'),
/// )
/// ```
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.accentColor,
    this.enableScale = true,
    this.padding,
    this.borderRadius = 20,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Sol dikey şerit rengi. null → şerit yok.
  final Color? accentColor;

  /// InteractiveScale efekti açık/kapalı.
  final bool enableScale;

  final EdgeInsets? padding;
  final double borderRadius;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: context.subtleBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(context.isDark ? 0.12 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Row(
          children: [
            if (accentColor != null)
              Container(
                width: 4,
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    if (enableScale && onTap != null) {
      return InteractiveScale(onTap: onTap, child: card);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}
