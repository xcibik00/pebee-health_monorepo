import 'package:flutter/material.dart';

/// Design tokens extracted from wireframes.
/// All colours used across the app must reference this file — never use
/// raw hex values in widget code.
abstract final class AppColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF2EDE7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFE8E3DF);

  // ── Brand / primary ────────────────────────────────────────────────────────
  /// Blue-purple used for primary CTA buttons ("Prihlásiť sa", "Ďalej", etc.)
  static const Color primary = Color(0xFF6B68E6);
  static const Color primaryLight = Color(0xFF9B99F0);

  // ── Accent ─────────────────────────────────────────────────────────────────
  /// Orange — selected/highlighted states
  static const Color accent = Color(0xFFF4AF4B);
  /// Pink — negative emotion, some progress indicators
  static const Color negative = Color(0xFFFF6B9D);
  /// Green — positive / completion states
  static const Color positive = Color(0xFF4CAF50);
  /// Teal — card overlay buttons
  static const Color teal = Color(0xFF5BB5A5);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Feedback ───────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFD32F2F);
  static const Color errorBackground = Color(0xFFFFEBEE);
}
