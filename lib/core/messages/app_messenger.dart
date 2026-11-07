import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/messages/app_message.dart';

part 'gen/app_messenger.g.dart';

/// App-wide snackbar channel. Anything (usually `callDataService`) posts here;
/// `AppOverlayHost` listens once and shows it, so messages never duplicate
/// across nested screens.
@Riverpod(keepAlive: true)
class AppMessenger extends _$AppMessenger {
  @override
  AppMessage? build() => null;

  void showError(AppException exception) => state = ErrorMessage(exception);
  void showSuccess(String text) => state = SuccessMessage(text);
  void showInfo(String text) => state = InfoMessage(text);
}

/// Global blocking loader. A counter, so overlapping actions don't hide it early.
@Riverpod(keepAlive: true)
class GlobalLoading extends _$GlobalLoading {
  @override
  int build() => 0;

  void show() => state++;
  void hide() => state = state > 0 ? state - 1 : 0;
}
