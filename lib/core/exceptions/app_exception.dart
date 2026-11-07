/// Every error the data layer throws is one of these. Sealed, so a `switch`
/// over an [AppException] must handle every case (see `app_exception_l10n.dart`).
///
/// Repositories and remote sources throw; notifiers let `AsyncValue` catch
/// (page data) or use `callDataService` (actions).
sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  /// Developer-facing detail, also used as the UI text for [ApiException].
  final String message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType(${statusCode ?? '-'}): $message';
}

/// Device has no usable internet connection (checked before the request is sent).
final class NoInternetException extends AppException {
  const NoInternetException([super.message = 'No internet connection']);
}

/// Connection failed: DNS, refused, TLS, socket errors.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error']);
}

/// Connect/send/receive timeout.
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException([super.message = 'Request timed out']);
}

/// 401, after the refresh-token retry also failed. The session is already ended.
final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized']) : super(statusCode: 401);
}

/// 404.
final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']) : super(statusCode: 404);
}

/// 5xx.
final class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException([super.message = 'Service unavailable', int? statusCode])
    : super(statusCode: statusCode ?? 503);
}

/// Any other non-2xx response. [message] is the server's own message when it sent one.
final class ApiException extends AppException {
  const ApiException(super.message, {super.statusCode});
}

/// Response body didn't match the expected model.
final class JsonFormatException extends AppException {
  const JsonFormatException([super.message = 'Unexpected response format']);
}

/// Anything not covered above. Logged with its original error.
final class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong', this.cause]);

  final Object? cause;
}
