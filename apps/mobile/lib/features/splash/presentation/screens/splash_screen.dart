import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Branded splash screen displayed while the auth state initialises.
///
/// Shows the Pebee Health logo on the cream background, visually identical
/// to the native splash. The GoRouter redirect handles navigation — once
/// [authStateProvider] resolves, the router moves to `/login` or `/home`.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Image.asset(
          'assets/logo/splash_logo.png',
          width: 240,
        ),
      ),
    );
  }
}
