import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Compact language selector that opens a popup menu with all supported
/// locales. Shows the current language as a flag + ISO code chip.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  static const _languages = [
    _Language(locale: Locale('sk'), flag: '🇸🇰', code: 'SK', name: 'Slovenčina'),
    _Language(locale: Locale('en'), flag: '🇬🇧', code: 'EN', name: 'English'),
    _Language(locale: Locale('uk'), flag: '🇺🇦', code: 'UA', name: 'Українська'),
    _Language(locale: Locale('de'), flag: '🇩🇪', code: 'DE', name: 'Deutsch'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;
    final current = _languages.firstWhere(
      (l) => l.locale.languageCode == currentLocale.languageCode,
      orElse: () => _languages.first,
    );

    return PopupMenuButton<Locale>(
      onSelected: (locale) => context.setLocale(locale),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => _languages.map((lang) {
        final isActive =
            lang.locale.languageCode == currentLocale.languageCode;
        return PopupMenuItem<Locale>(
          value: lang.locale,
          child: Row(
            children: [
              Text(lang.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lang.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isActive)
                const Icon(Icons.check, size: 18, color: AppColors.primary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              current.code,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down,
                size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Internal data model ──────────────────────────────────────────────────────

class _Language {
  const _Language({
    required this.locale,
    required this.flag,
    required this.code,
    required this.name,
  });

  final Locale locale;
  final String flag;
  final String code;
  final String name;
}
