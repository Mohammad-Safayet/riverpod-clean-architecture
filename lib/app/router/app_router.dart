import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_clean_architecture/app/router/routes.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';
import 'package:riverpod_clean_architecture/flavors/build_config.dart';

part 'gen/app_router.g.dart';

/// Single place that decides where the user may go based on the session.
///
/// Guests browse public screens (`isPublicPath` in routes.dart); opening a
/// protected one sends them to login with `from`, and signing in returns them there.
String? sessionRedirect(SessionStatus status, Uri uri) {
  final path = uri.path;
  final splash = const SplashRoute().location;
  final login = const LoginRoute().location;
  final home = const ProductsRoute().location;
  return switch (status) {
    SessionStatus.unknown => path == splash ? null : splash,
    SessionStatus.unauthenticated when path == splash => home,
    SessionStatus.unauthenticated when path == login || isPublicPath(path) => null,
    SessionStatus.unauthenticated => LoginRoute(from: uri.toString()).location,
    SessionStatus.authenticated when path == splash => home,
    SessionStatus.authenticated when path == login => _returnPath(uri) ?? home,
    SessionStatus.authenticated => null,
  };
}

/// The `from` of a login URI if it is an in-app path (not another site, not
/// splash/login, which would loop).
String? _returnPath(Uri loginUri) {
  final from = loginUri.queryParameters['from'];
  if (from == null || !from.startsWith('/') || from.startsWith('//')) return null;
  final path = Uri.parse(from).path;
  if (path == const SplashRoute().location || path == const LoginRoute().location) return null;
  return from;
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
    redirect: (context, state) => sessionRedirect(status.value, state.uri),
  );
  ref.onDispose(router.dispose);
  return router;
}
