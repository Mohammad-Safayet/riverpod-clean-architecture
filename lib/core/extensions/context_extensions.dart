import 'package:flutter/material.dart';
import 'package:riverpod_clean_architecture/core/theme/app_colors.dart';
import 'package:riverpod_clean_architecture/core/theme/app_text_styles.dart';
import 'package:riverpod_clean_architecture/l10n/generated/app_localizations.dart';

/// Shortcuts available in every widget, not just screens.
extension ContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTextStyles get textStyles => Theme.of(this).extension<AppTextStyles>()!;
  ThemeData get theme => Theme.of(this);
}
