import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_clean_architecture/app/router/splash_screen.dart';
import 'package:riverpod_clean_architecture/features/auth/presentation/screens/login_screen.dart';
import 'package:riverpod_clean_architecture/features/main/presentation/screens/main_screen.dart';
import 'package:riverpod_clean_architecture/features/products/presentation/screens/product_detail_screen.dart';
import 'package:riverpod_clean_architecture/features/products/presentation/screens/products_screen.dart';
import 'package:riverpod_clean_architecture/features/settings/presentation/screens/settings_screen.dart';

part 'gen/routes.g.dart';

// Every route in the app. Navigate with the generated helpers:
//   const ProductsRoute().go(context);
//   ProductDetailRoute(id: 5).push(context);
// Path/query parameters are constructor fields, so they're checked at compile time.

/// Screens a guest (signed-out user) may browse, with everything under them.
/// Any other route needs a session: new routes are protected until listed here.
final _publicPaths = [const ProductsRoute().location, const SettingsRoute().location];

/// Whether a guest may open [path]. Used by `sessionRedirect` and by login's
/// close button (going back to a protected `from` would bounce to login).
bool isPublicPath(String path) => _publicPaths.any((p) => path == p || path.startsWith('$p/'));

@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SplashScreen();
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute({this.from});

  /// Where to return after signing in or closing (query parameter). Always open
  /// login with `go`, never `push`: a pushed route doesn't change the router's
  /// location, so the redirect couldn't send the user back.
  final String? from;

  @override
  Widget build(BuildContext context, GoRouterState state) => LoginScreen(from: from);
}

@TypedStatefulShellRoute<MainShellRoute>(
  branches: [
    TypedStatefulShellBranch<ProductsBranch>(
      routes: [
        TypedGoRoute<ProductsRoute>(
          path: '/products',
          routes: [TypedGoRoute<ProductDetailRoute>(path: ':id')],
        ),
      ],
    ),
    TypedStatefulShellBranch<SettingsBranch>(
      routes: [TypedGoRoute<SettingsRoute>(path: '/settings')],
    ),
  ],
)
class MainShellRoute extends StatefulShellRouteData {
  const MainShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) => MainScreen(navigationShell: navigationShell);
}

class ProductsBranch extends StatefulShellBranchData {
  const ProductsBranch();
}

class SettingsBranch extends StatefulShellBranchData {
  const SettingsBranch();
}

class ProductsRoute extends GoRouteData with $ProductsRoute {
  const ProductsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ProductsScreen();
}

class ProductDetailRoute extends GoRouteData with $ProductDetailRoute {
  const ProductDetailRoute({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, GoRouterState state) => ProductDetailScreen(id: id);
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SettingsScreen();
}
