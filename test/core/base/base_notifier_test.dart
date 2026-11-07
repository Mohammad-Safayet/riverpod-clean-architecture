import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/core/base/base_notifier.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/messages/app_message.dart';
import 'package:riverpod_clean_architecture/core/messages/app_messenger.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';
import 'package:riverpod_clean_architecture/core/session/sign_in_prompt_notifier.dart';
import 'package:riverpod_clean_architecture/core/utils/provider_retry.dart';

import '../../helpers/test_app.dart';

class _ActionNotifier extends Notifier<String> with BaseNotifier {
  @override
  String build() => 'idle';

  Future<int?> run(Future<int> future) =>
      callDataService(future, onSuccess: (_) => state = 'done', onError: (_) => state = 'failed');
}

final _provider = NotifierProvider<_ActionNotifier, String>(_ActionNotifier.new);

void main() {
  setUpAll(setUpTestConfig);

  late ProviderContainer container;
  setUp(() => container = ProviderContainer(retry: noProviderRetry));
  tearDown(() => container.dispose());

  test('success: returns the result, calls onSuccess, loader shown then hidden', () async {
    final loadingValues = <int>[];
    container.listen(globalLoadingProvider, (_, next) => loadingValues.add(next));

    final result = await container.read(_provider.notifier).run(Future.value(42));

    expect(result, 42);
    expect(container.read(_provider), 'done');
    expect(loadingValues, [1, 0]);
    expect(container.read(appMessengerProvider), isNull);
  });

  test('failure: returns null, calls onError, posts the error message', () async {
    final result = await container
        .read(_provider.notifier)
        .run(Future.error(const NotFoundException()));

    expect(result, isNull);
    expect(container.read(_provider), 'failed');
    expect(container.read(globalLoadingProvider), 0);
    final message = container.read(appMessengerProvider);
    expect(message, isA<ErrorMessage>());
    expect((message! as ErrorMessage).exception, isA<NotFoundException>());
  });

  test('non-AppException errors are wrapped in UnknownException', () async {
    await container.read(_provider.notifier).run(Future.error(StateError('boom')));
    final message = container.read(appMessengerProvider)! as ErrorMessage;
    expect(message.exception, isA<UnknownException>());
  });

  group('requireSignIn', () {
    ProviderContainer withSession(SessionStatus status) {
      final c = ProviderContainer(
        retry: noProviderRetry,
        overrides: [sessionProvider.overrideWith(() => _FakeSession(status))],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('signed in: allows the action and prompts nothing', () {
      final c = withSession(SessionStatus.authenticated);
      expect(c.read(_provider.notifier).requireSignIn(), isTrue);
      expect(c.read(signInPromptProvider), 0);
    });

    test('guest: blocks the action and asks the app to open login', () {
      final c = withSession(SessionStatus.unauthenticated);
      expect(c.read(_provider.notifier).requireSignIn(), isFalse);
      expect(c.read(signInPromptProvider), 1);
    });
  });
}

class _FakeSession extends SessionNotifier {
  _FakeSession(this.status);

  final SessionStatus status;

  @override
  SessionState build() => SessionState(status: status);
}
