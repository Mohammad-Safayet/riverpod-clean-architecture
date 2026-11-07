import 'dart:async';
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_clean_architecture/core/session/session_user.dart';
import 'package:riverpod_clean_architecture/core/session/token_storage.dart';
import 'package:riverpod_clean_architecture/core/storage/storage_providers.dart';
import 'package:riverpod_clean_architecture/core/utils/app_logger.dart';

part 'gen/session_notifier.freezed.dart';
part 'gen/session_notifier.g.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

@freezed
abstract class SessionState with _$SessionState {
  const factory SessionState({
    @Default(SessionStatus.unknown) SessionStatus status,
    SessionUser? user,
  }) = _SessionState;
}

/// Who is signed in. The router redirects on [SessionState.status]; the auth
/// interceptor calls [expire] when a refresh fails.
@Riverpod(keepAlive: true)
class SessionNotifier extends _$SessionNotifier {
  @override
  SessionState build() {
    unawaited(_restore());
    return const SessionState();
  }

  Future<void> _restore() async {
    final tokens = await ref.read(tokenStorageProvider).read();
    final userJson = ref.read(preferenceManagerProvider).sessionUserJson;
    if (tokens != null && userJson != null) {
      final user = SessionUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      state = SessionState(status: SessionStatus.authenticated, user: user);
    } else {
      state = const SessionState(status: SessionStatus.unauthenticated);
    }
  }

  Future<void> start({required AuthTokens tokens, required SessionUser user}) async {
    await ref.read(tokenStorageProvider).save(tokens);
    await ref.read(preferenceManagerProvider).setSessionUserJson(jsonEncode(user.toJson()));
    state = SessionState(status: SessionStatus.authenticated, user: user);
  }

  /// User-initiated sign out.
  Future<void> end() async {
    await ref.read(tokenStorageProvider).clear();
    await ref.read(preferenceManagerProvider).setSessionUserJson(null);
    state = const SessionState(status: SessionStatus.unauthenticated);
  }

  /// Tokens are no longer valid (refresh failed).
  Future<void> expire() async {
    appLogger.w('Session expired, signing out');
    await end();
  }
}
