import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/network/error_mapper.dart';

void main() {
  final options = RequestOptions(path: '/x');

  DioException response(int status, [Object? data]) => DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );

  test('timeouts map to RequestTimeoutException', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(
        mapDioException(DioException(requestOptions: options, type: type)),
        isA<RequestTimeoutException>(),
      );
    }
  });

  test('connection error maps to NetworkException', () {
    final e = DioException(requestOptions: options, type: DioExceptionType.connectionError);
    expect(mapDioException(e), isA<NetworkException>());
  });

  test('status codes map to their exception types', () {
    expect(mapDioException(response(401)), isA<UnauthorizedException>());
    expect(mapDioException(response(404)), isA<NotFoundException>());
    expect(mapDioException(response(503)), isA<ServiceUnavailableException>());
  });

  test('other 4xx keeps the server message', () {
    final mapped = mapDioException(response(400, {'message': 'Invalid credentials'}));
    expect(mapped, isA<ApiException>());
    expect(mapped.message, 'Invalid credentials');
    expect(mapped.statusCode, 400);
  });

  test('an AppException set by an interceptor passes through', () {
    final e = DioException(requestOptions: options, error: const NoInternetException());
    expect(mapDioException(e), isA<NoInternetException>());
  });
}
