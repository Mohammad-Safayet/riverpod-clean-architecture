import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';

/// A one-off message for the user, shown as a snackbar by `AppOverlayHost`.
sealed class AppMessage {
  AppMessage() : id = _nextId++;

  /// Makes two identical messages in a row still count as a new state.
  final int id;
  static int _nextId = 0;
}

final class ErrorMessage extends AppMessage {
  ErrorMessage(this.exception);
  final AppException exception;
}

final class SuccessMessage extends AppMessage {
  SuccessMessage(this.text);
  final String text;
}

final class InfoMessage extends AppMessage {
  InfoMessage(this.text);
  final String text;
}
