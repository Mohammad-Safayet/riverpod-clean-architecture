import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';
import 'package:riverpod_clean_architecture/features/auth/data/models/login_request_model.dart';
import 'package:riverpod_clean_architecture/features/auth/data/models/login_response_model.dart';
import 'package:riverpod_clean_architecture/features/auth/data/sources/auth_remote_source.dart';
import 'package:riverpod_clean_architecture/features/auth/domain/entities/user.dart';
import 'package:riverpod_clean_architecture/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._session);

  final AuthRemoteSource _remote;
  final SessionNotifier _session;

  @override
  Future<User> login({required String username, required String password}) async {
    final response = await _remote.login(LoginRequestModel(username: username, password: password));
    await _session.start(
      tokens: (accessToken: response.accessToken, refreshToken: response.refreshToken),
      user: response.toSessionUser(),
    );
    return response.toEntity();
  }

  @override
  Future<void> logout() => _session.end();
}
