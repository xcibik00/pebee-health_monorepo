import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Displays the dashboard greeting: "Hello, {firstName}!" with a circular
/// avatar placeholder on the right.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key, required this.firstName});

  /// The user's first name shown in the greeting.
  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'dashboard.greeting'.tr(namedArgs: {'firstName': firstName}),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        const SizedBox(width: 16),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
