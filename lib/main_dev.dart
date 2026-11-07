import 'package:logger/logger.dart';

import 'package:riverpod_clean_architecture/app/bootstrap.dart';
import 'package:riverpod_clean_architecture/flavors/env_config.dart';
import 'package:riverpod_clean_architecture/flavors/environment.dart';

void main() => bootstrap(
  environment: Environment.dev,
  config: const EnvConfig(
    appName: 'Riverpod CA Dev',
    baseUrl: 'https://dummyjson.com',
    networkLogLevel: NetworkLogLevel.body,
    logLevel: Level.trace,
  ),
);
