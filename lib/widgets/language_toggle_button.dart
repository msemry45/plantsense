import 'package:flutter/material.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

/// Reusable Language Toggle Button styled according to the SVPG design system.
/// Allows the user to switch seamlessly between Arabic and English from any screen.
class LanguageToggleButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? foregroundColor;

  const LanguageToggleButton({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        final targetText = isAr ? 'English' : 'العربية';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => LocaleService.toggleLocale(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppColors.lightGreen.withAlpha(160),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(60),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language,
                      size: 16,
                      color: foregroundColor ?? AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      targetText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: foregroundColor ?? AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

