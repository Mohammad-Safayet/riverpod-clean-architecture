import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_clean_architecture/core/crash/crash_reporter.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/messages/app_messenger.dart';
import 'package:riverpod_clean_architecture/core/utils/app_logger.dart';

/// Mix into any `@riverpod` notifier that runs user actions (login, submit, delete):
///
/// ```dart
/// @riverpod
/// class LoginNotifier extends _$LoginNotifier with BaseNotifier {
///   Future<void> login(String u, String p) => callDataService(
///     ref.read(loginUseCaseProvider)(username: u, password: p),
///     onSuccess: (_) => ...,
///   );
/// }
/// ```
///
/// Page data that loads on open belongs in `build()` and is shown through
/// `AsyncValue` by `BaseScreen.asyncBody` instead.
mixin BaseNotifier {
  Ref get ref;

  /// Runs [future] with the global loading overlay, catches every error, shows
  /// it as a snackbar and returns `null` on failure. Same contract as the GetX
  /// template's `callDataService`.
  Future<T?> callDataService<T>(
    Future<T> future, {
    void Function(T result)? onSuccess,
    void Function(AppException exception)? onError,
    bool showLoading = true,
    bool showErrorMessage = true,
  }) async {
    // Grab keep-alive notifiers up front: this notifier may be disposed by the
    // time the future completes.
    final loading = ref.read(globalLoadingProvider.notifier);
    final messenger = ref.read(appMessengerProvider.notifier);

    if (showLoading) loading.show();
    try {
      final result = await future;
      if (ref.mounted) onSuccess?.call(result);
      return result;
    } catch (error, stackTrace) {
      final exception = error is AppException ? error : UnknownException(error.toString(), error);
      if (shouldReport(error)) {
        unawaited(CrashReporter.instance.recordError(error, stackTrace, reason: 'callDataService'));
      } else {
        appLogger.w('callDataService failed: $exception');
      }
      if (showErrorMessage) messenger.showError(exception);
      if (ref.mounted) onError?.call(exception);
      return null;
    } finally {
      if (showLoading) loading.hide();
    }
  }
}
