import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';
import 'package:riverpod_clean_architecture/core/session/session_user.dart';
import 'package:riverpod_clean_architecture/features/auth/data/models/login_request_model.dart';
import 'package:riverpod_clean_architecture/features/auth/data/models/login_response_model.dart';
import 'package:riverpod_clean_architecture/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:riverpod_clean_architecture/features/auth/data/sources/auth_remote_source.dart';

class _MockRemote extends Mock implements AuthRemoteSource {}

class _MockSession extends Mock implements SessionNotifier {}

void main() {
  late _MockRemote remote;
  late _MockSession session;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const LoginRequestModel(username: '', password: ''));
    registerFallbackValue(const SessionUser(id: 0, username: '', fullName: '', email: ''));
    registerFallbackValue((accessToken: '', refreshToken: ''));
  });

  setUp(() {
    remote = _MockRemote();
    session = _MockSession();
    repository = AuthRepositoryImpl(remote, session);
    when(
      () => session.start(
        tokens: any(named: 'tokens'),
        user: any(named: 'user'),
      ),
    ).thenAnswer((_) async {});
  });

  const response = LoginResponseModel(
    id: 1,
    username: 'emilys',
    email: 'emily@x.com',
    firstName: 'Emily',
    lastName: 'Johnson',
    accessToken: 'a',
    refreshToken: 'r',
  );

  test('login maps the response to a User and starts the session', () async {
    when(() => remote.login(any())).thenAnswer((_) async => response);

    final user = await repository.login(username: 'emilys', password: 'pw');

    expect(user.fullName, 'Emily Johnson');
    verify(
      () => session.start(
        tokens: (accessToken: 'a', refreshToken: 'r'),
        user: any(named: 'user', that: isA<SessionUser>().having((u) => u.id, 'id', 1)),
      ),
    ).called(1);
  });

  test('login failure does not start a session', () async {
    when(() => remote.login(any())).thenThrow(const ApiException('Invalid credentials'));

    expect(() => repository.login(username: 'x', password: 'y'), throwsA(isA<ApiException>()));
    verifyNever(
      () => session.start(
        tokens: any(named: 'tokens'),
        user: any(named: 'user'),
      ),
    );
  });
}
