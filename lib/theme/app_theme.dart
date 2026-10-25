import 'package:flutter/material.dart';

/// RideLine visual style - owned by Samira (Design).
///
/// Change colors / shapes here and every screen follows. Keep the screens
/// free of hardcoded colors so the style stays consistent.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1F4E79); // deep blue (brand)
  static const Color accent = Color(0xFF14A38B); // teal (positive / live)
  static const Color warning = Color(0xFFE8A317); // amber
  static const Color danger = Color(0xFFD64545); // red
  static const Color background = Color(0xFFF4F7FB);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE1E7EF);
  static const Color textMuted = Color(0xFF6B7A90);
  static const Color warningBg = Color(0xFFFFF4DB);
  static const Color dangerBg = Color(0xFFFDEAEA);
  static const Color successBg = Color(0xFFE3F6F2);
}

class AppTheme {
  AppTheme._();

  static const double radius = 14;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.danger,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerColor: AppColors.border,
    );
  }
}
