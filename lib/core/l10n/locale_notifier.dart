import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_clean_architecture/core/storage/storage_providers.dart';
import 'package:riverpod_clean_architecture/l10n/generated/app_localizations.dart';

part 'gen/locale_notifier.g.dart';

/// Selected app language, persisted. `null` means follow the device.
@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale? build() {
    final code = ref.watch(preferenceManagerProvider).languageCode;
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    await ref.read(preferenceManagerProvider).setLanguageCode(locale.languageCode);
    state = locale;
  }

  static List<Locale> get supported => AppLocalizations.supportedLocales;
}
