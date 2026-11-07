import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:riverpod_clean_architecture/core/connectivity/connectivity_notifier.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception_l10n.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/core/messages/app_message.dart';
import 'package:riverpod_clean_architecture/core/messages/app_messenger.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_loading.dart';
import 'package:riverpod_clean_architecture/core/widgets/offline_banner.dart';

/// Global key so snackbars can be shown without a Scaffold's context.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Wraps the whole app (via `MaterialApp.builder`) and owns the app-wide UI that
/// must appear exactly once: offline banner, blocking loader, snackbars.
class AppOverlayHost extends ConsumerWidget {
  const AppOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appMessengerProvider, (_, message) {
      if (message != null) _showSnackBar(context, message);
    });

    final online = ref.watch(connectivityProvider);
    final loading = ref.watch(globalLoadingProvider) > 0;

    return Stack(
      children: [
        Column(
          children: [
            if (!online)
              OfflineBanner(onRetry: () => ref.read(connectivityProvider.notifier).recheck()),
            Expanded(
              child: online
                  ? child
                  : MediaQuery.removePadding(context: context, removeTop: true, child: child),
            ),
          ],
        ),
        if (loading) const Positioned.fill(child: AppLoadingOverlay()),
      ],
    );
  }

  void _showSnackBar(BuildContext context, AppMessage message) {
    final colors = context.colors;
    final (text, color) = switch (message) {
      ErrorMessage(:final exception) => (exception.localizedMessage(context.l10n), colors.error),
      SuccessMessage(:final text) => (text, colors.success),
      InfoMessage(:final text) => (text, colors.textPrimary),
    };
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }
}
