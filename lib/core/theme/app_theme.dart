import 'package:flutter/material.dart';

import 'package:riverpod_clean_architecture/core/theme/app_colors.dart';
import 'package:riverpod_clean_architecture/core/theme/app_text_styles.dart';
import 'package:riverpod_clean_architecture/core/theme/app_values.dart';

/// Light only for now. For dark mode: add `AppColors.dark`, a `dark()` here built
/// the same way, and pass it as `MaterialApp.darkTheme`.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final textStyles = AppTextStyles.from(colors);
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      surface: colors.surface,
      error: colors.error,
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppValues.radius));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.pageBackground,
      dividerColor: colors.divider,
      extensions: [colors, textStyles],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textStyles.title,
      ),
      cardTheme: CardThemeData(color: colors.surface, elevation: 0, shape: shape),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size.fromHeight(AppValues.buttonHeight),
          textStyle: textStyles.button,
          shape: shape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius),
          borderSide: BorderSide(color: colors.divider),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
