import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_clean_architecture/core/connectivity/connectivity_notifier.dart';
import 'package:riverpod_clean_architecture/core/theme/app_theme.dart';
import 'package:riverpod_clean_architecture/core/utils/provider_retry.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_overlay_host.dart';
import 'package:riverpod_clean_architecture/flavors/build_config.dart';
import 'package:riverpod_clean_architecture/flavors/env_config.dart';
import 'package:riverpod_clean_architecture/flavors/environment.dart';
import 'package:riverpod_clean_architecture/l10n/generated/app_localizations.dart';

/// Call in `setUpAll` of every test that touches app code (logger, Dio, screens).
void setUpTestConfig() => BuildConfig.instantiate(
  environment: Environment.dev,
  config: const EnvConfig(appName: 'Test', baseUrl: 'https://test.local', logLevel: Level.off),
);

/// Connectivity without platform channels. `online` is fixed for the test.
class FakeConnectivity extends ConnectivityNotifier {
  FakeConnectivity({this.online = true});

  final bool online;

  @override
  bool build() => online;

  @override
  Future<void> recheck() async {}
}

/// Overrides every screen test needs. Add your own after these.
List<Override> baseOverrides({bool online = true}) => [
  connectivityProvider.overrideWith(() => FakeConnectivity(online: online)),
];

/// Pumps [child] inside the same theme, l10n and overlay host the real app uses.
Future<void> pumpTestApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  bool online = true,
}) => tester.pumpWidget(
  ProviderScope(
    retry: noProviderRetry,
    overrides: [
      ...baseOverrides(online: online),
      ...overrides,
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scaffoldMessengerKey: scaffoldMessengerKey,
      builder: (context, child) => AppOverlayHost(child: child!),
      home: child,
    ),
  ),
);
