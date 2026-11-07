import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gen/sign_in_prompt_notifier.g.dart';

/// Asks the app to open login so a guest can sign in and come back to the
/// current screen. `core/` can't navigate, so `App` listens and pushes login on
/// every request; the state is only a request counter.
///
/// Raised by `BaseNotifier.requireSignIn` and by the auth interceptor when a
/// guest's request gets 401.
@Riverpod(keepAlive: true)
class SignInPromptNotifier extends _$SignInPromptNotifier {
  @override
  int build() => 0;

  void request() => state++;
}
