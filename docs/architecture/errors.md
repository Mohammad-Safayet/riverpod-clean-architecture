# Errors

One sealed type, `AppException` (`core/exceptions/app_exception.dart`), is the only error the UI ever sees.

| Subtype | When |
|---|---|
| `NoInternetException` | offline, rejected before sending (connectivity interceptor) |
| `NetworkException` | DNS/socket/TLS failure |
| `RequestTimeoutException` | connect/send/receive timeout |
| `UnauthorizedException` | 401 after the refresh-token retry also failed (session already ended) |
| `NotFoundException` | 404 |
| `ServiceUnavailableException` | 5xx |
| `ApiException` | any other non-2xx; `message` is the server's message |
| `JsonFormatException` | response didn't match the model |
| `UnknownException` | anything else, with the original `cause` |

## Flow

```
Dio error ─► error_mapper.dart ─► AppException ─► thrown by BaseRemoteSource.callApi
                                                   │
                         repository / use case ◄───┘ (let it propagate; catch only to recover)
                                                   │
          page data: AsyncError → asyncBody → AppErrorView (localized + Retry)
          action:    callDataService → app messenger → snackbar (localized)
```

- **Status codes and the server's error body** are read in one place, `core/network/error_mapper.dart`. Adapt `_serverMessage` to your backend's error JSON.
- **Wording** lives in one place, `app_exception_l10n.dart` (`localizedMessage`), backed by ARB keys `error*`. Because the class is sealed, adding a subtype makes that `switch` fail to compile until you give it a message.
- `asAppException(error)` converts the `Object` from `AsyncValue.error`.

## Crash reporting

`CrashReporter` (`core/crash/crash_reporter.dart`) is where unexpected errors go. The template's default, `LogCrashReporter`, only logs. Already wired to it:

| Source | Where |
|---|---|
| uncaught async errors | `runZonedGuarded` in `bootstrap()` (fatal) |
| engine/platform errors | `PlatformDispatcher.instance.onError` (fatal) |
| framework errors (build/layout) | `FlutterError.onError` |
| page data failing in a provider's `build()` | `CrashReportingObserver` on the `ProviderScope` |
| actions | `callDataService` |
| signed-in user ID | `App` listens to the session and calls `setUserId` (ID only, no personal data) |

`shouldReport` decides what counts: anything that isn't an `AppException`, plus `UnknownException` and `JsonFormatException` (the API broke its contract). Handled failures like no internet or 404 aren't crashes and aren't reported.

To plug in a service, implement `CrashReporter` and pass it from `main_<env>.dart`:

```dart
class SentryCrashReporter implements CrashReporter {
  @override
  Future<void> init() => SentryFlutter.init((o) => o.dsn = '...');
  @override
  Future<void> recordError(Object e, StackTrace? s, {bool fatal = false, String? reason}) =>
      Sentry.captureException(e, stackTrace: s, hint: Hint.withMap({'reason': reason}));
  @override
  Future<void> setUserId(String? id) async =>
      Sentry.configureScope((scope) => scope.setUser(id == null ? null : SentryUser(id: id)));
  @override
  void log(String message) => Sentry.addBreadcrumb(Breadcrumb(message: message));
}

void main() => bootstrap(environment: ..., config: ..., crashReporter: SentryCrashReporter());
```

Typically only prod (and maybe staging) gets the real reporter. Release builds are obfuscated, so upload the symbols to the service (see `release.md`).

## Adding an error type

1. Add a `final class FooException extends AppException` in `app_exception.dart`.
2. Produce it in `error_mapper.dart` (or throw it from a repository for a domain rule).
3. Add an `errorFoo` key to both ARB files and a case in `localizedMessage`.
4. Test the mapping in `test/core/network/error_mapper_test.dart`.
