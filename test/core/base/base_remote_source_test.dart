import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/core/base/base_remote_source.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';

import '../../helpers/test_app.dart';

class _Source extends BaseRemoteSource {
  _Source() : super(Dio());
}

void main() {
  setUpAll(setUpTestConfig);

  final source = _Source();
  final options = RequestOptions(path: '/x');

  test('returns the parsed body on success', () async {
    final result = await source.callApi(
      Future.value(Response<dynamic>(requestOptions: options, data: {'id': 1})),
      (data) => (data as Map)['id'] as int,
    );
    expect(result, 1);
  });

  test('turns DioException into AppException', () {
    final call = source.callApi(
      Future<Response<dynamic>>.error(
        DioException(requestOptions: options, type: DioExceptionType.receiveTimeout),
      ),
      (data) => data,
    );
    expect(call, throwsA(isA<RequestTimeoutException>()));
  });

  test('turns a parsing error into JsonFormatException', () {
    final call = source.callApi(
      Future.value(Response<dynamic>(requestOptions: options, data: 'not a map')),
      (data) => (data as Map)['id'] as int,
    );
    expect(call, throwsA(isA<JsonFormatException>()));
  });
}
