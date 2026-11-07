import 'package:freezed_annotation/freezed_annotation.dart';

part 'gen/login_state.freezed.dart';

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({@Default(true) bool obscurePassword}) = _LoginState;
}
