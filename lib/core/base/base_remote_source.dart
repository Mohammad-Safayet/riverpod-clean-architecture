import 'package:dio/dio.dart';

import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/network/error_mapper.dart';
import 'package:riverpod_clean_architecture/core/utils/app_logger.dart';

/// Parent of every `XxxRemoteSource`. Wrap each request in [callApi] so callers
/// only ever see an [AppException], never a [DioException] or a parsing error.
///
/// ```dart
/// Future<ProductModel> getProduct(int id) => callApi(
///   dio.get(ApiEndpoints.product(id)),
///   (data) => ProductModel.fromJson(data as Map<String, dynamic>),
/// );
/// ```
abstract class BaseRemoteSource {
  BaseRemoteSource(this.dio);

  final Dio dio;

  Future<T> callApi<T>(Future<Response<dynamic>> request, T Function(dynamic data) parse) async {
    final Response<dynamic> response;
    try {
      response = await request;
    } on DioException catch (e) {
      final exception = mapDioException(e);
      appLogger.e('API ${e.requestOptions.method} ${e.requestOptions.path} → $exception');
      throw exception;
    } catch (e, st) {
      appLogger.e('API unexpected error', error: e, stackTrace: st);
      throw UnknownException(e.toString(), e);
    }

    try {
      return parse(response.data);
    } catch (e, st) {
      appLogger.e('API parse error ${response.requestOptions.path}', error: e, stackTrace: st);
      throw JsonFormatException(e.toString());
    }
  }
}
