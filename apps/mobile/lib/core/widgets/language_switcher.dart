import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Horizontal row of flag + ISO-code buttons that switch the app locale.
/// Place this wherever language selection is needed (e.g. login screen).
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  static const _languages = [
    _Language(locale: Locale('sk'), flag: '🇸🇰', code: 'SK'),
    _Language(locale: Locale('en'), flag: '🇬🇧', code: 'EN'),
    _Language(locale: Locale('uk'), flag: '🇺🇦', code: 'UA'),
    _Language(locale: Locale('de'), flag: '🇩🇪', code: 'DE'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _languages.map((lang) {
        final isActive = currentLocale.languageCode == lang.locale.languageCode;
        return _LangButton(
          language: lang,
          isActive: isActive,
          onTap: () => context.setLocale(lang.locale),
        );
      }).toList(),
    );
  }
}

// ── Internal data + sub-widgets ────────────────────────────────────────────

class _Language {
  const _Language({
    required this.locale,
    required this.flag,
    required this.code,
  });

  final Locale locale;
  final String flag;
  final String code;
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.language,
    required this.isActive,
    required this.onTap,
  });

  final _Language language;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              language.code,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color:
                    isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
