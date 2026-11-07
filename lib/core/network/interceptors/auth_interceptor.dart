import 'package:dio/dio.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/network/api_endpoints.dart';
import 'package:riverpod_clean_architecture/core/session/token_storage.dart';
import 'package:riverpod_clean_architecture/core/utils/app_logger.dart';

/// Adds `Authorization: Bearer <token>` and, on 401, refreshes the token once
/// and retries the request. A guest (no tokens) who gets 401 is asked to sign in.
///
/// It's a [QueuedInterceptor], so when several requests fail with 401 at the same
/// time only the first one refreshes; the rest wait and reuse the new token.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required this._plainDio,
    required this._onSessionExpired,
    required this._onSignInRequired,
  }) : _tokens = tokenStorage;

  final TokenStorage _tokens;

  /// Same base options but without this interceptor. Used for the refresh call
  /// and for the retry: going back through this interceptor would queue the
  /// retry's own error behind the one waiting for it, and deadlock.
  final Dio _plainDio;
  final Future<void> Function() _onSessionExpired;

  /// Called when a request made without a session gets 401: the endpoint needs an account.
  final void Function() _onSignInRequired;

  static const _skipAuthKey = 'skip_auth';

  /// Pass as `Options(extra: AuthInterceptor.skipAuth)` for public endpoints like login.
  static const skipAuth = {_skipAuthKey: true};

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[_skipAuthKey] != true) {
      final tokens = await _tokens.read();
      if (tokens != null) options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[_skipAuthKey] == true) {
      return handler.next(err);
    }

    final current = await _tokens.read();
    if (current == null) {
      _onSignInRequired();
      return handler.next(err);
    }

    // Another queued request may have refreshed already.
    if (options.headers['Authorization'] != 'Bearer ${current.accessToken}') {
      return _retry(options, current.accessToken, handler);
    }

    final refreshed = await _refresh(current.refreshToken);
    if (refreshed == null) {
      await _onSessionExpired();
      return handler.reject(
        DioException(
          requestOptions: options,
          response: err.response,
          type: DioExceptionType.badResponse,
          error: const UnauthorizedException('Session expired'),
        ),
      );
    }
    await _tokens.save(refreshed);
    return _retry(options, refreshed.accessToken, handler);
  }

  Future<void> _retry(
    RequestOptions options,
    String accessToken,
    ErrorInterceptorHandler handler,
  ) async {
    options.headers['Authorization'] = 'Bearer $accessToken';
    try {
      handler.resolve(await _plainDio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Adjust body/response keys to your backend.
  Future<AuthTokens?> _refresh(String refreshToken) async {
    try {
      final res = await _plainDio.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(extra: skipAuth),
      );
      final data = res.data;
      if (data == null) return null;
      return (
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } catch (e) {
      appLogger.w('Token refresh failed', error: e);
      return null;
    }
  }
}
