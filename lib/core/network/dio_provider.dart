import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_clean_architecture/core/connectivity/connectivity_notifier.dart';
import 'package:riverpod_clean_architecture/core/network/interceptors/auth_interceptor.dart';
import 'package:riverpod_clean_architecture/core/network/interceptors/connectivity_interceptor.dart';
import 'package:riverpod_clean_architecture/core/network/interceptors/network_log_interceptor.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';
import 'package:riverpod_clean_architecture/core/session/token_storage.dart';
import 'package:riverpod_clean_architecture/flavors/build_config.dart';

part 'gen/dio_provider.g.dart';

BaseOptions _baseOptions() {
  final config = BuildConfig.instance.config;
  return BaseOptions(
    baseUrl: config.baseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  );
}

/// The app's HTTP client. Remote sources get it through their provider.
@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final dio = Dio(_baseOptions());
  final plainDio = Dio(_baseOptions());
  final logLevel = BuildConfig.instance.config.networkLogLevel;

  dio.interceptors.addAll([
    ConnectivityInterceptor(() => ref.read(connectivityProvider)),
    AuthInterceptor(
      tokenStorage: ref.read(tokenStorageProvider),
      plainDio: plainDio,
      onSessionExpired: () => ref.read(sessionProvider.notifier).expire(),
    ),
    NetworkLogInterceptor(logLevel),
  ]);
  plainDio.interceptors.add(NetworkLogInterceptor(logLevel));

  ref
    ..onDispose(dio.close)
    ..onDispose(plainDio.close);
  return dio;
}
