import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/utils/app_logger.dart';

/// Where unexpected errors go in production. The template ships [LogCrashReporter]
/// (logs only); a project plugs in Sentry/Crashlytics by implementing this and
/// passing it to `bootstrap(crashReporter: ...)`. See docs/architecture/errors.md.
///
/// Already wired: uncaught zone/platform errors, Flutter framework errors, failed
/// providers ([CrashReportingObserver]) and `callDataService`. Everything goes
/// through [CrashReporter.instance].
abstract interface class CrashReporter {
  /// The active reporter. Set once by `bootstrap()`.
  static CrashReporter instance = const LogCrashReporter();

  /// Start the SDK. Called by `bootstrap()` before `runApp`.
  Future<void> init();

  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false, String? reason});

  /// Tag reports with the signed-in user (an ID only, never personal data). `null` on sign-out.
  Future<void> setUserId(String? id);

  /// Breadcrumb attached to the next report.
  void log(String message);
}

/// Expected failures (no internet, 404, validation...) are handled by the UI and
/// aren't crashes. Unknown errors and API-contract breaks are.
bool shouldReport(Object error) =>
    error is! AppException || error is UnknownException || error is JsonFormatException;

/// Default: logs instead of sending anywhere.
class LogCrashReporter implements CrashReporter {
  const LogCrashReporter();

  @override
  Future<void> init() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async => appLogger.e(
    '${fatal ? 'FATAL' : 'Non-fatal'}${reason == null ? '' : ' ($reason)'}',
    error: error,
    stackTrace: stack,
  );

  @override
  Future<void> setUserId(String? id) async {}

  @override
  void log(String message) => appLogger.t(message);
}
