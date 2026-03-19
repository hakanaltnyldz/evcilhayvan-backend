import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Listedeki her elemanı ard arda fadeIn + slideY animasyonuyla gösterir.
/// Kullanım:
/// ```dart
/// StaggeredList(children: items.map((e) => MyCard(e)).toList())
/// ```
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 55),
    this.initialDelay = Duration.zero,
    this.slideBegin = 0.06,
    this.fadeDuration = const Duration(milliseconds: 260),
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Widget> children;
  final Duration itemDelay;
  final Duration initialDelay;
  final double slideBegin;
  final Duration fadeDuration;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (_, i) => children[i]
          .animate(delay: initialDelay + itemDelay * i)
          .fadeIn(duration: fadeDuration)
          .slideY(begin: slideBegin, duration: fadeDuration, curve: Curves.easeOut),
    );
  }
}

/// Column tabanlı (kaydırma yok) staggered wrapper.
/// ListView içinde zaten kaydırma varsa bunu kullan.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 55),
    this.initialDelay = Duration.zero,
    this.slideBegin = 0.06,
    this.fadeDuration = const Duration(milliseconds: 260),
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
  });

  final List<Widget> children;
  final Duration itemDelay;
  final Duration initialDelay;
  final double slideBegin;
  final Duration fadeDuration;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (int i = 0; i < children.length; i++)
          children[i]
              .animate(delay: initialDelay + itemDelay * i)
              .fadeIn(duration: fadeDuration)
              .slideY(begin: slideBegin, duration: fadeDuration, curve: Curves.easeOut),
      ],
    );
  }
}
