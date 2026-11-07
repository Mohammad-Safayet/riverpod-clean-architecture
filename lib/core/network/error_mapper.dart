import 'package:dio/dio.dart';

import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';

/// Turns any [DioException] into an [AppException]. The single place that knows
/// about HTTP status codes and how the backend formats error bodies.
AppException mapDioException(DioException e) {
  // Interceptors reject with an AppException already (no internet, session expired).
  if (e.error case final AppException appException) return appException;

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const RequestTimeoutException(),
    DioExceptionType.connectionError => NetworkException(e.message ?? 'Connection error'),
    DioExceptionType.badResponse => _fromResponse(e.response),
    DioExceptionType.cancel => const UnknownException('Request cancelled'),
    DioExceptionType.badCertificate => const NetworkException('Bad certificate'),
    DioExceptionType.unknown => NetworkException(e.message ?? 'Network error'),
  };
}

AppException _fromResponse(Response<dynamic>? response) {
  final status = response?.statusCode ?? 0;
  final serverMessage = _serverMessage(response?.data);
  return switch (status) {
    401 => UnauthorizedException(serverMessage ?? 'Unauthorized'),
    404 => NotFoundException(serverMessage ?? 'Not found'),
    >= 500 => ServiceUnavailableException(serverMessage ?? 'Service unavailable', status),
    _ => ApiException(serverMessage ?? '', statusCode: status),
  };
}

/// Adjust to your backend's error body. DummyJSON sends `{"message": "..."}`.
String? _serverMessage(Object? data) => switch (data) {
  {'message': final String message} => message,
  {'error': final String error} => error,
  _ => null,
};
