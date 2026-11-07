import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/network/error_mapper.dart';
import 'package:riverpod_clean_architecture/core/network/interceptors/auth_interceptor.dart';
import 'package:riverpod_clean_architecture/core/session/token_storage.dart';

import '../../helpers/test_app.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

/// Answers each request with [handler]'s status and JSON body, recording requests.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final (int, Object) Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _, Future<void>? _) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(setUpTestConfig);

  late _MockTokenStorage tokens;
  late bool sessionExpired;
  late int signInRequests;

  setUpAll(() => registerFallbackValue((accessToken: '', refreshToken: '')));

  setUp(() {
    tokens = _MockTokenStorage();
    sessionExpired = false;
    signInRequests = 0;
    when(() => tokens.read()).thenAnswer((_) async => (accessToken: 'old', refreshToken: 'r1'));
    when(() => tokens.save(any())).thenAnswer((_) async {});
  });

  /// [api] serves the intercepted Dio; [plain] serves the refresh call and the retry.
  Dio buildDio(_FakeAdapter api, _FakeAdapter plain) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))..httpClientAdapter = api;
    final plainDio = Dio(BaseOptions(baseUrl: 'https://test.local'))..httpClientAdapter = plain;
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokens,
        plainDio: plainDio,
        onSessionExpired: () async => sessionExpired = true,
        onSignInRequired: () => signInRequests++,
      ),
    );
    return dio;
  }

  (int, Object) refreshThen((int, Object) retry, RequestOptions o) =>
      o.path == '/auth/refresh' ? (200, {'accessToken': 'new', 'refreshToken': 'r2'}) : retry;

  test('attaches the bearer token', () async {
    final api = _FakeAdapter((_) => (200, {'ok': true}));
    await buildDio(api, _FakeAdapter((_) => (500, {}))).get<dynamic>('/data');
    expect(api.requests.single.headers['Authorization'], 'Bearer old');
  });

  test('on 401 refreshes the token, saves it and retries', () async {
    final api = _FakeAdapter((_) => (401, {}));
    final plain = _FakeAdapter((o) => refreshThen((200, {'ok': true}), o));

    final res = await buildDio(api, plain).get<dynamic>('/data');

    expect(res.statusCode, 200);
    expect(plain.requests.map((r) => r.path), ['/auth/refresh', '/data']);
    expect(plain.requests.last.headers['Authorization'], 'Bearer new');
    verify(() => tokens.save((accessToken: 'new', refreshToken: 'r2'))).called(1);
    expect(sessionExpired, isFalse);
  });

  test('a retry that fails again completes with its error (no deadlock)', () async {
    final api = _FakeAdapter((_) => (401, {}));
    final plain = _FakeAdapter((o) => refreshThen((500, {'message': 'down'}), o));

    await expectLater(
      buildDio(api, plain).get<dynamic>('/data'),
      throwsA(
        isA<DioException>().having(mapDioException, 'mapped', isA<ServiceUnavailableException>()),
      ),
    );
  });

  test('when refresh fails, ends the session and throws UnauthorizedException', () async {
    final api = _FakeAdapter((_) => (401, {}));
    final refresh = _FakeAdapter((_) => (401, {'message': 'expired'}));

    final call = buildDio(api, refresh).get<dynamic>('/data');

    await expectLater(
      call,
      throwsA(isA<DioException>().having(mapDioException, 'mapped', isA<UnauthorizedException>())),
    );
    expect(sessionExpired, isTrue);
  });

  test('a guest (no tokens) getting 401 is asked to sign in, without a refresh', () async {
    when(() => tokens.read()).thenAnswer((_) async => null);
    final api = _FakeAdapter((_) => (401, {}));
    final refresh = _FakeAdapter((_) => (200, {'accessToken': 'new', 'refreshToken': 'r2'}));

    await expectLater(
      buildDio(api, refresh).get<dynamic>('/cart'),
      throwsA(isA<DioException>().having(mapDioException, 'mapped', isA<UnauthorizedException>())),
    );
    expect(api.requests.single.headers['Authorization'], isNull);
    expect(refresh.requests, isEmpty);
    expect(signInRequests, 1);
    expect(sessionExpired, isFalse);
  });

  test('skipAuth requests get no token and no refresh', () async {
    final api = _FakeAdapter((_) => (401, {}));
    final refresh = _FakeAdapter((_) => (200, {'accessToken': 'new', 'refreshToken': 'r2'}));

    await expectLater(
      buildDio(
        api,
        refresh,
      ).post<dynamic>('/login', options: Options(extra: AuthInterceptor.skipAuth)),
      throwsA(isA<DioException>()),
    );
    expect(api.requests.single.headers['Authorization'], isNull);
    expect(refresh.requests, isEmpty);
    expect(signInRequests, 0);
  });
}
