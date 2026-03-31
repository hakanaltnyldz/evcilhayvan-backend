import 'package:flutter/material.dart';

/// Randevu / rezervasyon wizard adım göstergesi.
///
/// ```dart
/// StepProgress(totalSteps: 4, currentStep: 2, stepLabels: ['Pet', 'Tarih', 'Saat', 'Onay'])
/// ```
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.stepLabels,
  });

  final int totalSteps;
  final int currentStep; // 0-indexed
  final List<String>? stepLabels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepBefore = i ~/ 2;
            final completed = stepBefore < currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                height: 3,
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFF2D6A4F)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          // Step circle
          final step = i ~/ 2;
          final isCompleted = step < currentStep;
          final isActive = step == currentStep;
          final label = stepLabels != null && step < stepLabels!.length
              ? stepLabels![step]
              : null;

          return _StepDot(
            step: step + 1,
            label: label,
            isCompleted: isCompleted,
            isActive: isActive,
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.step,
    this.label,
    required this.isCompleted,
    required this.isActive,
  });

  final int step;
  final String? label;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2D6A4F);
    const light = Color(0xFF52B788);
    const pale = Color(0xFFD8F3DC);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: isActive ? 36 : 30,
          height: isActive ? 36 : 30,
          decoration: BoxDecoration(
            color: isCompleted
                ? green
                : isActive
                    ? pale
                    : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: light, width: 2.5)
                : null,
            boxShadow: isActive
                ? [BoxShadow(color: light.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? green : Colors.grey.shade500,
                    ),
                  ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isCompleted || isActive ? green : Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}
