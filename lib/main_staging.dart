import 'package:logger/logger.dart';

import 'package:riverpod_clean_architecture/app/bootstrap.dart';
import 'package:riverpod_clean_architecture/flavors/env_config.dart';
import 'package:riverpod_clean_architecture/flavors/environment.dart';

void main() => bootstrap(
  environment: Environment.staging,
  config: const EnvConfig(
    appName: 'Riverpod CA Stg',
    baseUrl: 'https://dummyjson.com',
    networkLogLevel: NetworkLogLevel.basic,
    logLevel: Level.debug,
  ),
);
