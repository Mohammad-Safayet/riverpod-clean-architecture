import 'package:riverpod_clean_architecture/app/bootstrap.dart';
import 'package:riverpod_clean_architecture/flavors/env_config.dart';
import 'package:riverpod_clean_architecture/flavors/environment.dart';

void main() => bootstrap(
  environment: Environment.prod,
  config: const EnvConfig(appName: 'Riverpod CA', baseUrl: 'https://dummyjson.com'),
);
