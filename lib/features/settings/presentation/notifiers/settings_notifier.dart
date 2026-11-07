import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/core/base/base_notifier.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';

part 'gen/settings_notifier.g.dart';

/// Lite feature with no data layer: only actions on app-wide state.
@riverpod
class SettingsNotifier extends _$SettingsNotifier with BaseNotifier {
  @override
  void build() {}

  /// The router sends the user to login once the session ends.
  Future<void> logout() => callDataService(ref.read(sessionProvider.notifier).end());
}
