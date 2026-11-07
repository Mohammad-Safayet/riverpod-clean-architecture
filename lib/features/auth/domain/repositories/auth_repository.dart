import 'package:riverpod_clean_architecture/features/auth/domain/entities/user.dart';

/// Contract the data layer fulfils. Presentation and use cases depend on this,
/// never on `AuthRepositoryImpl`.
abstract interface class AuthRepository {
  /// Signs in and starts the session. Throws `AppException` on failure.
  Future<User> login({required String username, required String password});

  /// Ends the session locally.
  Future<void> logout();
}
