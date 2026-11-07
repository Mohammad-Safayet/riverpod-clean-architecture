import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_clean_architecture/core/utils/app_logger.dart';
import 'package:riverpod_clean_architecture/flavors/env_config.dart';

/// Logs HTTP calls through [appLogger] with secrets masked, so logs are safe to
/// share in bug reports. Level comes from [EnvConfig.networkLogLevel].
///
/// Masked everywhere: [sensitiveHeaders], and any JSON/query key in
/// [sensitiveKeys] (compared lowercase, ignoring `_` and `-`), at any depth.
class NetworkLogInterceptor extends Interceptor {
  NetworkLogInterceptor(this.level, {this.maxBodyLength = 2000});

  final NetworkLogLevel level;
  final int maxBodyLength;

  static const mask = '***';
  static const sensitiveHeaders = {'authorization', 'cookie', 'set-cookie', 'x-api-key'};
  static const sensitiveKeys = {
    'password', 'newpassword', 'oldpassword', 'confirmpassword', 'token', 'accesstoken', //
    'refreshtoken', 'idtoken', 'secret', 'clientsecret', 'apikey', 'otp', 'pin', 'cvv',
  };

  static const _startKey = 'network_log_start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (level != NetworkLogLevel.none) {
      options.extra[_startKey] = DateTime.now();
      appLogger.d(
        [
          '→ ${options.method} ${redactUri(options.uri)}',
          'headers: ${redactHeaders(options.headers)}',
          if (level == NetworkLogLevel.body && options.data != null) 'body: ${_body(options.data)}',
        ].join('\n'),
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (level != NetworkLogLevel.none) {
      final o = response.requestOptions;
      appLogger.d(
        [
          '← ${response.statusCode} ${o.method} ${redactUri(o.uri)} ${_elapsed(o)}',
          if (level == NetworkLogLevel.body) 'body: ${_body(response.data)}',
        ].join('\n'),
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (level != NetworkLogLevel.none) {
      final o = err.requestOptions;
      final status = err.response?.statusCode ?? err.type.name;
      appLogger.w(
        [
          '✗ $status ${o.method} ${redactUri(o.uri)} ${_elapsed(o)}',
          if (level == NetworkLogLevel.body && err.response?.data != null)
            'body: ${_body(err.response!.data)}',
        ].join('\n'),
      );
    }
    handler.next(err);
  }

  String _elapsed(RequestOptions o) => switch (o.extra[_startKey]) {
    final DateTime start => '(${DateTime.now().difference(start).inMilliseconds}ms)',
    _ => '',
  };

  String _body(Object? data) {
    final text = switch (data) {
      FormData() => '<form data: ${data.fields.map((f) => f.key).join(', ')}>',
      String() => _tryJson(data),
      _ => jsonEncode(redactJson(data)),
    };
    return text.length > maxBodyLength
        ? '${text.substring(0, maxBodyLength)}… (${text.length} chars)'
        : text;
  }

  String _tryJson(String data) {
    try {
      return jsonEncode(redactJson(jsonDecode(data)));
    } on FormatException {
      return data;
    }
  }

  static bool _isSensitive(String key) =>
      sensitiveKeys.contains(key.toLowerCase().replaceAll(RegExp('[_-]'), ''));

  /// Copy of [headers] with [sensitiveHeaders] masked.
  static Map<String, Object?> redactHeaders(Map<String, Object?> headers) => {
    for (final MapEntry(:key, :value) in headers.entries)
      key: sensitiveHeaders.contains(key.toLowerCase()) ? mask : value,
  };

  /// Copy of [json] with every [sensitiveKeys] value masked, at any depth.
  static Object? redactJson(Object? json) => switch (json) {
    Map() => {
      for (final MapEntry(:key, :value) in json.entries)
        key: _isSensitive('$key') ? mask : redactJson(value),
    },
    List() => [for (final item in json) redactJson(item)],
    _ => json,
  };

  /// [uri] with sensitive query parameter values masked.
  static String redactUri(Uri uri) {
    if (!uri.hasQuery) return '$uri';
    final query = {
      for (final MapEntry(:key, :value) in uri.queryParametersAll.entries)
        key: _isSensitive(key) ? [mask] : value,
    };
    return '${uri.replace(queryParameters: query)}';
  }
}
