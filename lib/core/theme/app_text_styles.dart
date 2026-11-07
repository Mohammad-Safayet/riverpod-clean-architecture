import 'package:flutter/material.dart';

import 'package:riverpod_clean_architecture/core/theme/app_colors.dart';

/// Named text styles. Use `context.textStyles.title` instead of inline `TextStyle`s.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.headline,
    required this.title,
    required this.body,
    required this.bodySecondary,
    required this.caption,
    required this.button,
  });

  final TextStyle headline;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodySecondary;
  final TextStyle caption;
  final TextStyle button;

  factory AppTextStyles.from(AppColors colors) => AppTextStyles(
    headline: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.textPrimary),
    title: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
    body: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textPrimary),
    bodySecondary: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: colors.textSecondary,
    ),
    caption: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colors.textSecondary),
    button: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  @override
  AppTextStyles copyWith({
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? bodySecondary,
    TextStyle? caption,
    TextStyle? button,
  }) => AppTextStyles(
    headline: headline ?? this.headline,
    title: title ?? this.title,
    body: body ?? this.body,
    bodySecondary: bodySecondary ?? this.bodySecondary,
    caption: caption ?? this.caption,
    button: button ?? this.button,
  );

  @override
  AppTextStyles lerp(AppTextStyles? other, double t) {
    if (other == null) return this;
    return AppTextStyles(
      headline: TextStyle.lerp(headline, other.headline, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodySecondary: TextStyle.lerp(bodySecondary, other.bodySecondary, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
    );
  }
}
