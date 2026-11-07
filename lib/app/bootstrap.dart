import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_clean_architecture/app/app.dart';
import 'package:riverpod_clean_architecture/core/crash/crash_reporter.dart';
import 'package:riverpod_clean_architecture/core/crash/crash_reporting_observer.dart';
import 'package:riverpod_clean_architecture/core/storage/storage_providers.dart';
import 'package:riverpod_clean_architecture/core/utils/provider_retry.dart';
import 'package:riverpod_clean_architecture/flavors/build_config.dart';
import 'package:riverpod_clean_architecture/flavors/env_config.dart';
import 'package:riverpod_clean_architecture/flavors/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared startup for every flavor. Add SDK init (Firebase, ...) here.
///
/// [crashReporter]: pass a Sentry/Crashlytics implementation of [CrashReporter]
/// from `main_<env>.dart`; the default only logs.
Future<void> bootstrap({
  required Environment environment,
  required EnvConfig config,
  CrashReporter crashReporter = const LogCrashReporter(),
}) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      BuildConfig.instantiate(environment: environment, config: config);

      CrashReporter.instance = crashReporter;
      await crashReporter.init();

      // Framework errors (build/layout/paint).
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        crashReporter.recordError(details.exception, details.stack, reason: 'FlutterError');
      };
      // Errors thrown by the engine/platform outside the zone.
      PlatformDispatcher.instance.onError = (error, stack) {
        crashReporter.recordError(error, stack, fatal: true, reason: 'PlatformDispatcher');
        return true;
      };

      final prefs = await SharedPreferences.getInstance();

      runApp(
        ProviderScope(
          retry: noProviderRetry,
          observers: const [CrashReportingObserver()],
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const App(),
        ),
      );
    },
    // Uncaught async errors.
    (error, stack) => crashReporter.recordError(error, stack, fatal: true, reason: 'zone'),
  );
}
