import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/core/network/interceptors/network_log_interceptor.dart';

void main() {
  const mask = NetworkLogInterceptor.mask;

  test('masks auth headers and cookies, case-insensitively', () {
    final headers = NetworkLogInterceptor.redactHeaders({
      'Authorization': 'Bearer abc',
      'cookie': 'sid=1',
      'Accept': 'application/json',
    });
    expect(headers, {'Authorization': mask, 'cookie': mask, 'Accept': 'application/json'});
  });

  test('masks sensitive keys at any depth, in any casing/style', () {
    final body = NetworkLogInterceptor.redactJson({
      'username': 'emilys',
      'password': 'secret',
      'data': {
        'accessToken': 'a',
        'refresh_token': 'r',
        'items': [
          {'id': 1, 'otp': '1234'},
        ],
      },
    });
    expect(body, {
      'username': 'emilys',
      'password': mask,
      'data': {
        'accessToken': mask,
        'refresh_token': mask,
        'items': [
          {'id': 1, 'otp': mask},
        ],
      },
    });
  });

  test('masks sensitive query parameters and keeps the rest', () {
    final uri = Uri.parse('https://api.test/x?token=abc&page=2');
    final logged = NetworkLogInterceptor.redactUri(uri);
    expect(logged, contains('page=2'));
    expect(logged, isNot(contains('abc')));
  });
}
