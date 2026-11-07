import 'package:flutter/material.dart';

import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';

/// THE loading indicator. Used by BaseScreen, PagingListView and the global
/// overlay, so changing it here changes it everywhere.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(strokeWidth: 3, color: context.colors.primary),
    ),
  );
}

/// Blocking overlay shown while `callDataService` runs.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0x66000000),
    child: AbsorbPointer(child: AppLoading()),
  );
}
