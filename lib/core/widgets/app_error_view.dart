import 'package:flutter/material.dart';

import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception_l10n.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/core/theme/app_values.dart';

/// Full-area error with an optional retry button. Used by `BaseScreen.asyncBody`.
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.exception, this.onRetry});

  final AppException exception;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final icon = switch (exception) {
      NoInternetException() || NetworkException() => Icons.wifi_off_rounded,
      NotFoundException() => Icons.search_off_rounded,
      _ => Icons.error_outline_rounded,
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: context.colors.textSecondary),
            const SizedBox(height: AppValues.padding),
            Text(
              exception.localizedMessage(context.l10n),
              style: context.textStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppValues.padding),
              OutlinedButton(onPressed: onRetry, child: Text(context.l10n.actionRetry)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown when a list loads successfully but has no items.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppValues.paddingLarge),
      child: Text(message ?? context.l10n.emptyList, style: context.textStyles.bodySecondary),
    ),
  );
}
