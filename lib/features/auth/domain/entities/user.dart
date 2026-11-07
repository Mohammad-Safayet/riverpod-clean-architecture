import 'package:freezed_annotation/freezed_annotation.dart';

part 'gen/user.freezed.dart';

/// What the app means by "user", independent of the API's response shape.
@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    required String username,
    required String email,
    required String fullName,
    String? imageUrl,
  }) = _User;
}
