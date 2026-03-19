import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Tüm ekranlarda CircularProgressIndicator yerine kullanılabilecek
/// pençe animasyonlu özel yükleme göstergesi.
///
/// ```dart
/// // Küçük (inline)
/// PawLoading()
///
/// // Tam ekran merkezde
/// PawLoading.fullScreen()
/// ```
class PawLoading extends StatefulWidget {
  const PawLoading({super.key, this.size = 48, this.color});

  final double size;
  final Color? color;

  /// Tam ekran ortalanmış versiyon.
  static Widget fullScreen({Color? color}) => Center(child: PawLoading(color: color));

  @override
  State<PawLoading> createState() => _PawLoadingState();
}

class _PawLoadingState extends State<PawLoading> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotate;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: false);

    _rotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Transform.rotate(
            angle: _rotate.value,
            child: Icon(
              Icons.pets,
              size: widget.size,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Üç pençe nokta ile "yükleniyor" efekti — chat / inline kullanım için.
class PawDotLoading extends StatefulWidget {
  const PawDotLoading({super.key, this.dotSize = 8, this.color});

  final double dotSize;
  final Color? color;

  @override
  State<PawDotLoading> createState() => _PawDotLoadingState();
}

class _PawDotLoadingState extends State<PawDotLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppPalette.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
            final bounce = math.sin(phase * math.pi).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, -bounce * widget.dotSize),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.4 + bounce * 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
