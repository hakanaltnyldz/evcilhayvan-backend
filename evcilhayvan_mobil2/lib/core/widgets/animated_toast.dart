import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_palette.dart';

enum ToastType { success, error, info }

/// Ekranın üstünde kısa süre görünen animasyonlu toast bildirimi.
///
/// Kullanım:
/// ```dart
/// AnimatedToast.show(context, message: 'Kaydedildi!', type: ToastType.success);
/// ```
class AnimatedToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final entry = OverlayEntry(
      builder: (_) => _AnimatedToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );
    _currentEntry = entry;
    Overlay.of(context).insert(entry);
  }
}

class _AnimatedToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _AnimatedToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_AnimatedToastWidget> createState() => _AnimatedToastWidgetState();
}

class _AnimatedToastWidgetState extends State<_AnimatedToastWidget> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) setState(() => _visible = false);
      Future.delayed(const Duration(milliseconds: 350), widget.onDismiss);
    });
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (widget.type) {
      ToastType.success => (const Color(0xFF4CAF50), Icons.check_circle_outline_rounded),
      ToastType.error   => (const Color(0xFFEF5350), Icons.error_outline_rounded),
      ToastType.info    => (AppPalette.primary, Icons.info_outline_rounded),
    };

    final toast = Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: _visible
          ? toast
              .animate()
              .slideY(begin: -0.3, end: 0, duration: 300.ms, curve: Curves.easeOut)
              .fadeIn(duration: 250.ms)
          : toast,
    );
  }
}
