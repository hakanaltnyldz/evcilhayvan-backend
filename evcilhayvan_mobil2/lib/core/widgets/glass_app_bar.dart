import 'dart:ui';
import 'package:flutter/material.dart';

/// Scroll edilebilen ekranlarda kullanılan glassmorphism AppBar.
/// [SliverAppBar] olarak çalışır: içerik scroll edilince yarı şeffaf cam efekti.
///
/// Kullanım:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     GlassSliverAppBar(title: 'Başlık', expandedHeight: 280, flexibleContent: myHeroImage),
///     SliverToBoxAdapter(child: myContent),
///   ],
/// )
/// ```
class GlassSliverAppBar extends StatelessWidget {
  const GlassSliverAppBar({
    super.key,
    required this.title,
    this.expandedHeight = 260,
    this.flexibleContent,
    this.actions,
    this.leading,
    this.backgroundColor,
  });

  final String title;
  final double expandedHeight;
  final Widget? flexibleContent;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      snap: false,
      elevation: 0,
      leading: leading,
      actions: actions,
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.onSurface,
      // Glass effect on collapsed AppBar
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        background: flexibleContent,
        collapseMode: CollapseMode.parallax,
      ),
      // Frosted glass effect via BackdropFilter
      bottom: PreferredSize(
        preferredSize: Size.zero,
        child: const SizedBox.shrink(),
      ),
      // Override system bar color
      systemOverlayStyle: null,
    );
  }
}

/// Basit bir glassmorphism container — kart veya AppBar arka planı olarak kullanılabilir.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 12,
    this.opacity = 0.12,
    this.padding,
    this.border = true,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark ? Colors.white.withOpacity(opacity) : Colors.white.withOpacity(opacity + 0.05);
    final borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.4);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border
                ? Border.all(color: borderColor, width: 1)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
