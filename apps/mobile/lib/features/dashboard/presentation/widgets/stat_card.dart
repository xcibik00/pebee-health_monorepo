import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable stat card showing a label and a large highlighted value.
/// Used for "Overall progress" (purple) and "Completed exercises" (orange).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  /// Descriptive label above the value (e.g. "Overall progress").
  final String label;

  /// The stat value to display prominently (e.g. "85%").
  final String value;

  /// Color for the value text.
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
