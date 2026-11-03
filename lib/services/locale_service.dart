import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing and persisting the application locale.
/// Defaults to Arabic ('ar') as required by system specifications.
class LocaleService {
  LocaleService._();

  static const String _localeStorageKey = 'app_language_code';

  /// Reactive notifier for the active application locale
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier<Locale>(const Locale('ar'));

  /// Initializes the saved locale from local storage, defaulting to Arabic ('ar')
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_localeStorageKey);
      if (savedCode != null && (savedCode == 'en' || savedCode == 'ar')) {
        localeNotifier.value = Locale(savedCode);
      } else {
        localeNotifier.value = const Locale('ar');
      }
    } catch (_) {
      localeNotifier.value = const Locale('ar');
    }
  }

  /// Sets and persists a new locale
  static Future<void> setLocale(Locale newLocale) async {
    if (newLocale.languageCode != 'ar' && newLocale.languageCode != 'en') {
      return;
    }
    localeNotifier.value = newLocale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeStorageKey, newLocale.languageCode);
    } catch (_) {}
  }

  /// Toggles between Arabic and English
  static Future<void> toggleLocale() async {
    final newCode = isArabic ? 'en' : 'ar';
    await setLocale(Locale(newCode));
  }

  /// Convenience getter checking if current language is Arabic
  static bool get isArabic => localeNotifier.value.languageCode == 'ar';

  /// Text direction associated with current locale
  static TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;
}

