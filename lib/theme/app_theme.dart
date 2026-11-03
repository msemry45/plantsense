import 'package:flutter/material.dart';

/// Authoritative brand colors from SVPG Brand Guidelines (`assets/branding/SVPG/SVPG.pdf`)
class AppColors {
  AppColors._();

  /// الأخضر الأساسي - Primary Green
  static const Color primary = Color(0xFF1F5A43);

  /// الأخضر الفاتح - Light Green (Container / Tint / Subtle border)
  static const Color lightGreen = Color(0xFFDDE9DD);

  /// الأخضر الليموني - Lime Green (Accent / Highlights / Badges)
  static const Color lime = Color(0xFFB7D368);

  /// الداكن - Dark Green / Charcoal (Text / Headings / Dark Surface)
  static const Color dark = Color(0xFF1D2D25);

  /// الخلفية الفاتحة - Light Background (Natural Ivory / Clean Canvas)
  static const Color lightBackground = Color(0xFFF7F8F3);

  /// بطاقات العمليات والمحتوى - Surface Card White
  static const Color surfaceCard = Colors.white;

  /// ألوان دلالية - Semantic Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color warning = Color(0xFFB86200);
  static const Color warningContainer = Color(0xFFFFDCBE);
  static const Color success = Color(0xFF1E6838);
  static const Color successContainer = Color(0xFFA6F5B2);

  /// Aliases for consistent multi-screen references
  static const Color primaryGreen = primary;
  static const Color limeGreen = lime;
  static const Color semanticError = error;
}

/// Centralized ThemeData enforcing the SVPG Design System
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Manrope';

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightGreen,
      onPrimaryContainer: AppColors.dark,
      secondary: AppColors.lime,
      onSecondary: AppColors.dark,
      secondaryContainer: AppColors.lightGreen,
      onSecondaryContainer: AppColors.dark,
      tertiary: AppColors.lime,
      onTertiary: AppColors.dark,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.error,
      background: AppColors.lightBackground,
      onBackground: AppColors.dark,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.dark,
      surfaceVariant: AppColors.lightGreen,
      onSurfaceVariant: AppColors.dark,
      outline: AppColors.lightGreen,
      outlineVariant: Color(0xFFC7D7C7),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.dark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.dark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.dark.withOpacity(0.4),
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.dark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.dark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGreen, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGreen, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.lightGreen.withOpacity(0.8), width: 1.2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightGreen,
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.dark,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Official SVPG Brand Logo Component
class SVPGLogo extends StatelessWidget {
  final double height;
  final bool isDarkBackground;

  const SVPGLogo({
    super.key,
    this.height = 72,
    this.isDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = isDarkBackground
        ? 'assets/branding/svpg-logo-white-lower-leaves.png'
        : 'assets/branding/svpg_official_logo.png';

    return Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        // Safe graceful fallback keeping exact brand colors
        return Container(
          height: height,
          width: height,
          decoration: BoxDecoration(
            color: isDarkBackground ? AppColors.dark : AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'SVPG',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }
}
