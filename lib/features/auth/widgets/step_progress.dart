import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The 3-step onboarding progress indicator (Account · Health · Secure).
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.currentStep,
    this.labels = const ['Account', 'Health', 'Secure'],
  });

  /// 1-based index of the active step.
  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          _Dot(
            index: i + 1,
            currentStep: currentStep,
            label: labels[i],
          ),
          if (i < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: (i + 1) < currentStep
                    ? AppColors.lime
                    : AppColors.divider.withValues(alpha: 0.5),
              ),
            ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.index,
    required this.currentStep,
    required this.label,
  });

  final int index;
  final int currentStep;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = index < currentStep;
    final isActive = index == currentStep;
    final bg = isDone
        ? AppColors.olive
        : isActive
            ? AppColors.lime
            : AppColors.fill;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: isDone
              ? const Icon(Icons.check, size: 18, color: AppColors.white)
              : Text(
                  '$index',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isActive ? AppColors.ink : AppColors.textMuted,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isActive || isDone
                ? AppColors.textSecondary
                : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
