import 'dart:math' as math;
import 'package:flutter/material.dart';

/// RefreshIndicator'ın pençe (paw) ikonlu, animasyonlu özel sürümü.
/// Standart [RefreshIndicator] yerine bunu sarmala:
///
/// ```dart
/// PawRefreshIndicator(
///   onRefresh: () async { ... },
///   child: ListView(...),
/// )
/// ```
class PawRefreshIndicator extends StatefulWidget {
  const PawRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.triggerOffset = 80,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final double triggerOffset;

  @override
  State<PawRefreshIndicator> createState() => _PawRefreshIndicatorState();
}

class _PawRefreshIndicatorState extends State<PawRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;
  bool _isRefreshing = false;
  double _pullDistance = 0;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _spinCtrl.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinCtrl.stop();
        _spinCtrl.reset();
        setState(() {
          _isRefreshing = false;
          _pullDistance = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    // Wrapping with RefreshIndicator but adding custom overlay
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _triggerRefresh,
          color: Colors.transparent,
          backgroundColor: Colors.transparent,
          displacement: 60,
          strokeWidth: 0,
          child: widget.child,
        ),
        // Custom paw indicator overlay
        if (_isRefreshing || _pullDistance > 20)
          Positioned(
            top: _isRefreshing ? 20 : (_pullDistance - 40).clamp(0, 20).toDouble(),
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: AnimatedBuilder(
                  animation: _spinCtrl,
                  builder: (_, child) => Transform.rotate(
                    angle: _isRefreshing
                        ? _spinCtrl.value * 2 * math.pi
                        : (_pullDistance / widget.triggerOffset) * math.pi,
                    child: child,
                  ),
                  child: Icon(
                    Icons.pets,
                    color: color,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
