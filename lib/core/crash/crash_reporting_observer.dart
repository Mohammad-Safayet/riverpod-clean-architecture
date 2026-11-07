import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_clean_architecture/core/crash/crash_reporter.dart';

/// Reports providers that fail with an unexpected error (page data loading in
/// `build()`), which never pass through `callDataService`.
final class CrashReportingObserver extends ProviderObserver {
  const CrashReportingObserver();

  @override
  void providerDidFail(ProviderObserverContext context, Object error, StackTrace stackTrace) {
    if (!shouldReport(error)) return;
    final name = context.provider.name ?? context.provider.runtimeType.toString();
    CrashReporter.instance.recordError(error, stackTrace, reason: 'provider $name');
  }
}
