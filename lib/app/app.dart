import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_clean_architecture/app/router/app_router.dart';
import 'package:riverpod_clean_architecture/core/crash/crash_reporter.dart';
import 'package:riverpod_clean_architecture/core/l10n/locale_notifier.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';
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
    ref.listen(
      sessionProvider.select((s) => s.user?.id),
      (_, id) => CrashReporter.instance.setUserId(id?.toString()),
    );
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
}
