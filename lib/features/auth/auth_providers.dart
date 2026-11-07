// Wiring for the auth feature: the only file that sees both data/ and domain/.
// Presentation imports this (and domain/), never data/ directly.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';
import 'package:riverpod_clean_architecture/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:riverpod_clean_architecture/features/auth/data/sources/auth_remote_source.dart';
import 'package:riverpod_clean_architecture/features/auth/domain/repositories/auth_repository.dart';
import 'package:riverpod_clean_architecture/features/auth/domain/usecases/login_usecase.dart';

part 'gen/auth_providers.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(authRemoteSourceProvider), ref.watch(sessionProvider.notifier));

@riverpod
LoginUseCase loginUseCase(Ref ref) => LoginUseCase(ref.watch(authRepositoryProvider));
