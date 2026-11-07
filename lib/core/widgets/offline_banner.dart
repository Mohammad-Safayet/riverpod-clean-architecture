import 'package:flutter/material.dart';

import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/core/theme/app_values.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.warning,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppValues.padding),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: AppValues.paddingSmall),
            Expanded(
              child: Text(
                context.l10n.offlineBanner,
                style: context.textStyles.caption.copyWith(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(context.l10n.actionRetry),
            ),
          ],
        ),
      ),
    ),
  );
}
