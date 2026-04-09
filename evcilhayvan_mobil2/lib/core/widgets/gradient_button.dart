import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';

/// Gradient fill, glow shadow ve haptic feedback'li birincil aksiyon butonu.
///
/// Kullanım:
/// ```dart
/// GradientButton(
///   label: 'Randevu Al',
///   icon: Icons.calendar_today,
///   onPressed: () {},
/// )
/// ```
class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final double? width;
  final double borderRadius;
  final List<Color>? gradientColors;
  final bool isLoading;
  final bool haptic;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 52,
    this.width,
    this.borderRadius = 16,
    this.gradientColors,
    this.isLoading = false,
    this.haptic = true,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onPressed == null) return;
    _ctrl.forward();
  }

  void _onTapUp(_) {
    _ctrl.reverse();
  }

  void _onTap() {
    if (widget.onPressed == null || widget.isLoading) return;
    if (widget.haptic) HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final colors = widget.gradientColors ??
        [AppPalette.primary, AppPalette.secondary];

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _ctrl.reverse(),
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.55,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: widget.height,
            width: widget.width ?? double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: enabled ? colors : [Colors.grey.shade400, Colors.grey.shade500],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: colors.first.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined varyantı — secondary actions için.
class OutlineGradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final double? width;
  final double borderRadius;
  final Color? color;

  const OutlineGradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 48,
    this.width,
    this.borderRadius = 14,
    this.color,
  });

  @override
  State<OutlineGradientButton> createState() => _OutlineGradientButtonState();
}

class _OutlineGradientButtonState extends State<OutlineGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() => _ctrl.dispose();

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppPalette.primary;
    return GestureDetector(
      onTapDown: (_) { if (widget.onPressed != null) _ctrl.forward(); },
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPressed?.call();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: color, width: 1.8),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: color, size: 18),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
