import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_clean_architecture/app/router/app_router.dart';
import 'package:riverpod_clean_architecture/app/router/routes.dart';
import 'package:riverpod_clean_architecture/core/crash/crash_reporter.dart';
import 'package:riverpod_clean_architecture/core/l10n/locale_notifier.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';
import 'package:riverpod_clean_architecture/core/session/sign_in_prompt_notifier.dart';
import 'package:riverpod_clean_architecture/core/theme/app_theme.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_overlay_host.dart';
import 'package:riverpod_clean_architecture/flavors/build_config.dart';
import 'package:riverpod_clean_architecture/l10n/generated/app_localizations.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = BuildConfig.instance;
    // Tag crash reports with the signed-in user's ID (never name or email).
    ref
      ..listen(
        sessionProvider.select((s) => s.user?.id),
        (_, id) => CrashReporter.instance.setUserId(id?.toString()),
      )
      // A guest tried to act: open login, returning here after sign-in.
      ..listen(signInPromptProvider, (_, _) => _openLogin(ref.read(routerProvider)));
    return MaterialApp.router(
      title: config.config.appName,
      debugShowCheckedModeBanner: !config.isProd,
      theme: AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
      scaffoldMessengerKey: scaffoldMessengerKey,
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => AppOverlayHost(child: child ?? const SizedBox.shrink()),
    );
  }

  /// Goes to login remembering the current screen; the redirect returns there
  /// after sign-in.
  void _openLogin(GoRouter router) {
    final here = router.routerDelegate.currentConfiguration.uri;
    if (here.path == const LoginRoute().location) return;
    router.go(LoginRoute(from: here.toString()).location);
  }
}
