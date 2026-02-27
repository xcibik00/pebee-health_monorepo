import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Horizontal scrollable row of day indicators with mood/completion status.
/// Shows the training plan for the current week with mocked data.
class TrainingPlanSection extends StatelessWidget {
  const TrainingPlanSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Mocked data: day number, status (completed, missed, skipped, pending)
    const days = [
      _DayData(day: 16, status: _DayStatus.missed),
      _DayData(day: 17, status: _DayStatus.skipped),
      _DayData(day: 18, status: _DayStatus.completed),
      _DayData(day: 19, status: _DayStatus.skipped),
      _DayData(day: 20, status: _DayStatus.completed),
      _DayData(day: 21, status: _DayStatus.missed),
      _DayData(day: 22, status: _DayStatus.pending),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'dashboard.trainingPlan'.tr(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: navigate to full training plan
              },
              child: Text('dashboard.more'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: days.map((d) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _DayIndicator(data: d, isToday: d.day == 20),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Day data model ──────────────────────────────────────────────────────────

enum _DayStatus { completed, missed, skipped, pending }

class _DayData {
  const _DayData({required this.day, required this.status});

  final int day;
  final _DayStatus status;
}

// ── Day indicator widget ────────────────────────────────────────────────────

class _DayIndicator extends StatelessWidget {
  const _DayIndicator({required this.data, required this.isToday});

  final _DayData data;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: isToday
            ? Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${data.day}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _buildStatusIcon(),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (data.status) {
      case _DayStatus.completed:
        return const Icon(Icons.check_circle, size: 20, color: AppColors.positive);
      case _DayStatus.missed:
        return const Icon(Icons.cancel, size: 20, color: AppColors.negative);
      case _DayStatus.skipped:
        return Icon(Icons.remove_circle_outline,
            size: 20, color: AppColors.textSecondary.withValues(alpha: 0.5));
      case _DayStatus.pending:
        return Icon(Icons.radio_button_unchecked,
            size: 20, color: AppColors.textSecondary.withValues(alpha: 0.3));
    }
  }
}
