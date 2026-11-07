import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:riverpod_clean_architecture/core/session/session_user.dart';
import 'package:riverpod_clean_architecture/features/auth/domain/entities/user.dart';

part 'gen/login_response_model.freezed.dart';
part 'gen/login_response_model.g.dart';

/// Exact shape of DummyJSON's `POST /auth/login` response.
@freezed
abstract class LoginResponseModel with _$LoginResponseModel {
  const factory LoginResponseModel({
    required int id,
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    String? image,
    required String accessToken,
    required String refreshToken,
  }) = _LoginResponseModel;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseModelFromJson(json);
}

extension LoginResponseModelX on LoginResponseModel {
  User toEntity() => User(
    id: id,
    username: username,
    email: email,
    fullName: '$firstName $lastName'.trim(),
    imageUrl: image,
  );

  SessionUser toSessionUser() => SessionUser(
    id: id,
    username: username,
    email: email,
    fullName: '$firstName $lastName'.trim(),
    imageUrl: image,
  );
}
