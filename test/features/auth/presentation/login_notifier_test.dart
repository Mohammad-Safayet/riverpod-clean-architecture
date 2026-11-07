import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/messages/app_message.dart';
import 'package:riverpod_clean_architecture/core/messages/app_messenger.dart';
import 'package:riverpod_clean_architecture/core/utils/provider_retry.dart';
import 'package:riverpod_clean_architecture/features/auth/auth_providers.dart';
import 'package:riverpod_clean_architecture/features/auth/domain/entities/user.dart';
import 'package:riverpod_clean_architecture/features/auth/domain/usecases/login_usecase.dart';
import 'package:riverpod_clean_architecture/features/auth/presentation/notifiers/login_notifier.dart';

import '../../../helpers/test_app.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  setUpAll(setUpTestConfig);

  late _MockLoginUseCase useCase;
  late ProviderContainer container;

  setUp(() {
    useCase = _MockLoginUseCase();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [loginUseCaseProvider.overrideWithValue(useCase)],
    );
    // Keep the auto-dispose notifier alive like a mounted screen would.
    container.listen(loginProvider, (_, _) {});
  });
  tearDown(() => container.dispose());

  test('toggles password visibility', () {
    expect(container.read(loginProvider).obscurePassword, isTrue);
    container.read(loginProvider.notifier).togglePasswordVisibility();
    expect(container.read(loginProvider).obscurePassword, isFalse);
  });

  test('successful login posts no error', () async {
    when(() => useCase(username: 'emilys', password: 'pw'))
        .thenAnswer((_) async => const User(id: 1, username: 'emilys', email: 'e', fullName: 'E'));

    await container.read(loginProvider.notifier).login(username: 'emilys', password: 'pw');

    expect(container.read(appMessengerProvider), isNull);
  });

  test('failed login posts the error to the app messenger', () async {
    when(
      () => useCase(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => throw const ApiException('Invalid credentials'));

    await container.read(loginProvider.notifier).login(username: 'x', password: 'y');

    final message = container.read(appMessengerProvider);
    expect(message, isA<ErrorMessage>());
    expect((message! as ErrorMessage).exception.message, 'Invalid credentials');
  });
}
