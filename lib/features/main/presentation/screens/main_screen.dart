import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:riverpod_clean_architecture/core/base/base_screen.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';

/// Bottom-navigation shell. Each tab is a branch with its own navigation stack,
/// defined in `app/router/routes.dart`.
class MainScreen extends BaseScreen {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Tab screens draw their own SafeArea/app bar.
  @override
  bool get useSafeArea => false;

  @override
  Widget body(BuildContext context, WidgetRef ref) => navigationShell;

  @override
  Widget? bottomNavigationBar(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        // Tapping the current tab pops it back to its first screen.
        initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.storefront_outlined),
          selectedIcon: const Icon(Icons.storefront),
          label: l10n.navProducts,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.navSettings,
        ),
      ],
    );
  }
}
