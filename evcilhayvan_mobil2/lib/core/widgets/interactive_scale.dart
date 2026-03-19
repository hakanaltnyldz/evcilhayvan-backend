import 'package:flutter/material.dart';

/// Herhangi bir widget'a dokunma anında hafif scale-down geri bildirimi ekler.
/// Tek satırda kullan:
///
/// ```dart
/// InteractiveScale(onTap: () {}, child: MyCard())
/// ```
///
/// Devre dışı bırakmak için [enabled: false] kullan.
class InteractiveScale extends StatefulWidget {
  const InteractiveScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.duration = const Duration(milliseconds: 100),
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Basılıyken uygulanacak ölçek (varsayılan 0.96 = %4 küçülme)
  final double scale;

  /// Animasyon süresi
  final Duration duration;

  /// false yapınca animasyon olmadan normal GestureDetector gibi davranır
  final bool enabled;

  @override
  State<InteractiveScale> createState() => _InteractiveScaleState();
}

class _InteractiveScaleState extends State<InteractiveScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.enabled) _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.enabled) _ctrl.reverse();
  }

  void _onTapCancel() {
    if (widget.enabled) _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
