import 'package:freezed_annotation/freezed_annotation.dart';

part 'gen/session_user.freezed.dart';
part 'gen/session_user.g.dart';

/// The signed-in user as the whole app sees it (BaseScreen.currentUser, settings, ...).
/// Features map their own user model into this when a session starts.
@freezed
abstract class SessionUser with _$SessionUser {
  const factory SessionUser({
    required int id,
    required String username,
    required String fullName,
    required String email,
    String? imageUrl,
  }) = _SessionUser;

  factory SessionUser.fromJson(Map<String, dynamic> json) => _$SessionUserFromJson(json);
}
