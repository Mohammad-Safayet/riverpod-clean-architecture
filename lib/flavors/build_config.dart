import 'package:riverpod_clean_architecture/flavors/env_config.dart';
import 'package:riverpod_clean_architecture/flavors/environment.dart';

/// Set once at startup by `main_<env>.dart`, then read anywhere via [BuildConfig.instance].
class BuildConfig {
  BuildConfig._();

  static final BuildConfig instance = BuildConfig._();

  late final Environment environment;
  late final EnvConfig config;
  bool _locked = false;

  static BuildConfig instantiate({required Environment environment, required EnvConfig config}) {
    if (instance._locked) return instance;
    instance
      ..environment = environment
      ..config = config
      .._locked = true;
    return instance;
  }

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;
}
