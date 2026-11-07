import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/core/base/base_notifier.dart';
import 'package:riverpod_clean_architecture/core/crash/crash_reporter.dart';
import 'package:riverpod_clean_architecture/core/crash/crash_reporting_observer.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/utils/provider_retry.dart';

import '../../helpers/test_app.dart';

/// Records what would be sent to Sentry/Crashlytics.
class _FakeReporter implements CrashReporter {
  final errors = <(Object, String?)>[];

  @override
  Future<void> init() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async => errors.add((error, reason));

  @override
  Future<void> setUserId(String? id) async {}

  @override
  void log(String message) {}
}

class _ActionNotifier extends Notifier<void> with BaseNotifier {
  @override
  void build() {}

  Future<void> run(Future<int> future) => callDataService(future);
}

final _action = NotifierProvider<_ActionNotifier, void>(_ActionNotifier.new);

final _failingPage = FutureProvider<int>((ref) async => throw StateError('bug'));
final _offlinePage = FutureProvider<int>((ref) async => throw const NoInternetException());

void main() {
  setUpAll(setUpTestConfig);

  late _FakeReporter reporter;
  late ProviderContainer container;

  setUp(() {
    reporter = _FakeReporter();
    CrashReporter.instance = reporter;
    container = ProviderContainer(
      retry: noProviderRetry,
      observers: const [CrashReportingObserver()],
    );
  });
  tearDown(() {
    container.dispose();
    CrashReporter.instance = const LogCrashReporter();
  });

  test('shouldReport: unexpected errors yes, handled AppExceptions no', () {
    expect(shouldReport(StateError('x')), isTrue);
    expect(shouldReport(const UnknownException()), isTrue);
    expect(shouldReport(const JsonFormatException()), isTrue);
    expect(shouldReport(const NoInternetException()), isFalse);
    expect(shouldReport(const NotFoundException()), isFalse);
  });

  test('callDataService reports unexpected errors only', () async {
    final notifier = container.read(_action.notifier);
    await notifier.run(Future.error(StateError('bug')));
    await notifier.run(Future.error(const NoInternetException()));

    expect(reporter.errors, hasLength(1));
    expect(reporter.errors.single.$1, isA<StateError>());
    expect(reporter.errors.single.$2, 'callDataService');
  });

  test('failing page-data providers are reported by the observer', () async {
    await expectLater(container.read(_failingPage.future), throwsA(isA<StateError>()));
    await expectLater(container.read(_offlinePage.future), throwsA(isA<NoInternetException>()));

    expect(reporter.errors, hasLength(1));
    expect(reporter.errors.single.$1, isA<StateError>());
  });
}
