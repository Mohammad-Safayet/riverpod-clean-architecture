import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_clean_architecture/app/router/routes.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';
import 'package:riverpod_clean_architecture/flavors/build_config.dart';

part 'gen/app_router.g.dart';

/// Single place that decides where the user may go based on the session.
String? sessionRedirect(SessionStatus status, String location) {
  final atSplash = location == const SplashRoute().location;
  final atLogin = location == const LoginRoute().location;
  return switch (status) {
    SessionStatus.unknown => atSplash ? null : const SplashRoute().location,
    SessionStatus.unauthenticated => atLogin ? null : const LoginRoute().location,
    SessionStatus.authenticated => atSplash || atLogin ? const ProductsRoute().location : null,
  };
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Re-run redirect when the session status changes, without rebuilding the router.
  final status = ValueNotifier(ref.read(sessionProvider).status);
  ref
    ..listen(sessionProvider.select((s) => s.status), (_, next) => status.value = next)
    ..onDispose(status.dispose);

  final router = GoRouter(
    initialLocation: const SplashRoute().location,
    debugLogDiagnostics: BuildConfig.instance.isDev,
    refreshListenable: status,
    routes: $appRoutes,
    redirect: (context, state) => sessionRedirect(status.value, state.matchedLocation),
  );
  ref.onDispose(router.dispose);
  return router;
}
