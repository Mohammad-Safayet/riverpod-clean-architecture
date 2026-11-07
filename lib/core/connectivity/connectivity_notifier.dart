import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/flavors/build_config.dart';

part 'gen/connectivity_notifier.g.dart';

/// `true` while the device can actually reach the internet.
///
/// connectivity_plus only reports the link type (a captive-portal Wi-Fi still says
/// "wifi"), so every change is confirmed by pinging [EnvConfig.reachabilityUrl].
/// Starts optimistic (`true`) so the first request isn't blocked while we check.
@Riverpod(keepAlive: true)
class ConnectivityNotifier extends _$ConnectivityNotifier {
  late final Dio _probe = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      validateStatus: (_) => true,
    ),
  );

  @override
  bool build() {
    final sub = Connectivity().onConnectivityChanged.listen(_onChanged);
    ref.onDispose(sub.cancel);
    unawaited(Connectivity().checkConnectivity().then(_onChanged));
    return true;
  }

  Future<void> _onChanged(List<ConnectivityResult> results) async {
    final hasLink = results.any((r) => r != ConnectivityResult.none);
    final online = hasLink && await _isReachable();
    if (ref.mounted) state = online;
  }

  Future<bool> _isReachable() async {
    try {
      final res = await _probe.head<void>(BuildConfig.instance.config.reachabilityUrl);
      return res.statusCode != null && res.statusCode! < 500;
    } catch (_) {
      return false;
    }
  }

  /// Re-check now, e.g. from the offline banner's retry button.
  Future<void> recheck() async => _onChanged(await Connectivity().checkConnectivity());
}
