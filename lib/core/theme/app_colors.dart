import 'package:flutter/material.dart';

/// Raw palette. Only [AppColors] and `app_theme.dart` should reference these;
/// widgets use `context.colors.<semantic name>`.
abstract final class Palette {
  static const brand = Color(0xFF3F51B5);
  static const brandDark = Color(0xFF283593);
  static const white = Color(0xFFFFFFFF);
  static const grey50 = Color(0xFFF7F8FA);
  static const grey200 = Color(0xFFE4E7EC);
  static const grey500 = Color(0xFF667085);
  static const grey900 = Color(0xFF101828);
  static const red = Color(0xFFD92D20);
  static const green = Color(0xFF079455);
  static const amber = Color(0xFFDC6803);
}

/// Semantic colors. Add a dark instance later and pass it to a dark `ThemeData`;
/// widgets don't change.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.pageBackground,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.error,
    required this.success,
    required this.warning,
  });

  final Color primary;
  final Color onPrimary;
  final Color pageBackground;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color error;
  final Color success;
  final Color warning;

  static const light = AppColors(
    primary: Palette.brand,
    onPrimary: Palette.white,
    pageBackground: Palette.grey50,
    surface: Palette.white,
    textPrimary: Palette.grey900,
    textSecondary: Palette.grey500,
    divider: Palette.grey200,
    error: Palette.red,
    success: Palette.green,
    warning: Palette.amber,
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? pageBackground,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? error,
    Color? success,
    Color? warning,
  }) => AppColors(
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    pageBackground: pageBackground ?? this.pageBackground,
    surface: surface ?? this.surface,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    divider: divider ?? this.divider,
    error: error ?? this.error,
    success: success ?? this.success,
    warning: warning ?? this.warning,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
