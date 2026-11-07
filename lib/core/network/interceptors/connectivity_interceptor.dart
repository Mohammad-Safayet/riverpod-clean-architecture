import 'package:dio/dio.dart';

import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';

/// Fails fast with [NoInternetException] when we already know we're offline,
/// instead of waiting for a timeout.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._isOnline);

  final bool Function() _isOnline;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isOnline()) return handler.next(options);
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: const NoInternetException(),
      ),
    );
  }
}
