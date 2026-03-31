import 'package:flutter/material.dart';

/// Randevu/booking durumu için dikey timeline.
///
/// ```dart
/// StatusTimeline(steps: [
///   StatusStep(title: 'Oluşturuldu', subtitle: '25 Mar 2026', isCompleted: true),
///   StatusStep(title: 'Onaylandı', isActive: true),
///   StatusStep(title: 'Tamamlandı'),
/// ])
/// ```
class StatusStep {
  const StatusStep({
    required this.title,
    this.subtitle,
    this.icon,
    this.isCompleted = false,
    this.isActive = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isCompleted;
  final bool isActive;
}

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.steps});

  final List<StatusStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        return _TimelineRow(
          step: step,
          isLast: isLast,
          theme: theme,
        );
      }),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isLast,
    required this.theme,
  });

  final StatusStep step;
  final bool isLast;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2D6A4F);
    const light = Color(0xFF52B788);
    const pale = Color(0xFFD8F3DC);

    final dotColor = step.isCompleted
        ? green
        : step.isActive
            ? light
            : Colors.grey.shade300;

    final lineColor = step.isCompleted ? green : Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column (dot + line)
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  width: step.isActive ? 28 : 24,
                  height: step.isActive ? 28 : 24,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: step.isActive
                        ? Border.all(color: pale, width: 3)
                        : null,
                    boxShadow: step.isActive
                        ? [BoxShadow(color: light.withOpacity(0.4), blurRadius: 8)]
                        : null,
                  ),
                  child: Center(
                    child: step.isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : step.isActive
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : step.icon != null
                                ? Icon(step.icon, color: Colors.grey.shade500, size: 12)
                                : null,
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: step.isActive || step.isCompleted
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: step.isCompleted || step.isActive
                          ? green
                          : Colors.grey.shade500,
                    ),
                  ),
                  if (step.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
