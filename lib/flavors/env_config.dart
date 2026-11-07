import 'package:logger/logger.dart';

/// How much of each HTTP call the network log shows. Secrets are always masked.
enum NetworkLogLevel {
  /// Nothing. Use for prod.
  none,

  /// Method, URL, status, duration and (masked) headers. No bodies.
  basic,

  /// [basic] plus request/response bodies (sensitive keys masked, long bodies cut).
  body,
}

/// Per-environment values. Add new keys here and set them in every `main_<env>.dart`.
class EnvConfig {
  const EnvConfig({
    required this.appName,
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.networkLogLevel = NetworkLogLevel.none,
    this.logLevel = Level.warning,
    this.reachabilityUrl = 'https://www.gstatic.com/generate_204',
  });

  final String appName;
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final NetworkLogLevel networkLogLevel;
  final Level logLevel;

  /// Pinged to confirm real internet access (a Wi-Fi connection alone isn't proof).
  final String reachabilityUrl;
}
