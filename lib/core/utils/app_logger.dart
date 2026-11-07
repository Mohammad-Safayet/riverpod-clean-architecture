import 'package:logger/logger.dart';

import 'package:riverpod_clean_architecture/flavors/build_config.dart';

/// App-wide logger. Level comes from the flavor's [EnvConfig.logLevel].
final Logger appLogger = Logger(
  level: BuildConfig.instance.config.logLevel,
  printer: PrettyPrinter(methodCount: 0, errorMethodCount: 6, lineLength: 100),
);
