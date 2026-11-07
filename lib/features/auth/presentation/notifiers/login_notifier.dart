import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/core/base/base_notifier.dart';
import 'package:riverpod_clean_architecture/features/auth/auth_providers.dart';
import 'package:riverpod_clean_architecture/features/auth/presentation/state/login_state.dart';

part 'gen/login_notifier.g.dart';

@riverpod
class LoginNotifier extends _$LoginNotifier with BaseNotifier {
  @override
  LoginState build() => const LoginState();

  void togglePasswordVisibility() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  /// On success the session changes and the router redirects; nothing else to do.
  Future<void> login({required String username, required String password}) =>
      callDataService(ref.read(loginUseCaseProvider)(username: username, password: password));
}
