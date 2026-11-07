import 'package:riverpod_clean_architecture/features/auth/domain/entities/user.dart';
import 'package:riverpod_clean_architecture/features/auth/domain/repositories/auth_repository.dart';

/// Business rules around signing in live here, not in the notifier or repository.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call({required String username, required String password}) =>
      _repository.login(username: username.trim(), password: password);
}
