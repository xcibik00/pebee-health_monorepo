import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Card showing today's recommended exercise with a placeholder image area,
/// exercise info, and a "Start exercise" button.
/// All data is currently mocked.
class TodaysExerciseCard extends StatelessWidget {
  const TodaysExerciseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.inputFill,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image placeholder ──────────────────────────────────────
          Container(
            height: 180,
            width: double.infinity,
            color: AppColors.textSecondary.withValues(alpha: 0.15),
            child: const Center(
              child: Icon(
                Icons.fitness_center_rounded,
                size: 48,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // ── Exercise info ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dashboard.exerciseTitle'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.signal_cellular_alt,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'dashboard.exerciseLevel'.tr(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'dashboard.exerciseDuration'.tr(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    onPressed: () {
                      // TODO: navigate to exercise detail
                    },
                    child: Text('dashboard.startExercise'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
