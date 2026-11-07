import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/l10n/generated/app_localizations.dart';

extension AppExceptionL10n on AppException {
  /// User-facing text for this error. One place to change wording for every screen.
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    NoInternetException() => l10n.errorNoInternet,
    NetworkException() => l10n.errorNetwork,
    RequestTimeoutException() => l10n.errorTimeout,
    UnauthorizedException() => l10n.errorUnauthorized,
    NotFoundException() => l10n.errorNotFound,
    ServiceUnavailableException() => l10n.errorServiceUnavailable,
    ApiException(:final message) => message.isEmpty ? l10n.errorGeneric : message,
    JsonFormatException() => l10n.errorGeneric,
    UnknownException() => l10n.errorGeneric,
  };
}

/// For `AsyncValue.error`, which is typed `Object`.
AppException asAppException(Object error) =>
    error is AppException ? error : UnknownException(error.toString(), error);
