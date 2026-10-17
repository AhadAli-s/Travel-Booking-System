import 'package:flutter/material.dart';

import '../core/booking_timeline.dart';
import '../core/theme.dart';

/// Vertical progress list: done steps are pink with a tick, the next step is highlighted in yellow.
class TimelineView extends StatelessWidget {
  const TimelineView({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final nextIndex = steps.indexWhere((step) => !step.done);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            step: steps[i],
            isNext: i == nextIndex,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isNext,
    required this.isLast,
  });

  final TimelineStep step;
  final bool isNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color circleColor = step.done ? AppColors.pink : Colors.white;
    final Color circleBorder = step.done
        ? AppColors.pink
        : (isNext ? AppColors.yellow : AppColors.border);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: circleBorder,
                    width: isNext ? 3 : 2,
                  ),
                ),
                child: step.done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 22,
                  color: step.done ? AppColors.pink : AppColors.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: (step.done || isNext)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: (step.done || isNext)
                          ? AppColors.ink
                          : AppColors.muted,
                    ),
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'NEXT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
