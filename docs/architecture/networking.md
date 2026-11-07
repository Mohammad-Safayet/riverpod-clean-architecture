# Networking

## Pieces

| File | Role |
|---|---|
| `core/network/dio_provider.dart` | `dioClientProvider`: the one Dio, base URL/timeouts from `EnvConfig`, interceptors |
| `core/network/api_endpoints.dart` | every path, as constants |
| `core/base/base_remote_source.dart` | `callApi(request, parse)`: errors → `AppException`, parse failure → `JsonFormatException` |
| `core/network/interceptors/connectivity_interceptor.dart` | rejects with `NoInternetException` when offline |
| `core/network/interceptors/auth_interceptor.dart` | Bearer token, refresh on 401, retry once |
| `core/network/error_mapper.dart` | `DioException` → `AppException` (see `errors.md`) |

Interceptor order: connectivity → auth → log.

## Network logs

`NetworkLogInterceptor` (`core/network/interceptors/network_log_interceptor.dart`) writes through `appLogger` at the flavor's `EnvConfig.networkLogLevel`: dev `body`, staging `basic` (method, URL, status, timing, headers), prod `none`. Secrets are masked at every level, so logs are safe to paste into a bug report:

- headers `Authorization`, `Cookie`, `Set-Cookie`, `X-Api-Key`;
- any JSON or query key named like `password`, `token`, `accessToken`, `refresh_token`, `otp`, `pin`, `secret`, `apiKey` (case, `_` and `-` ignored), at any depth.

A new kind of secret in your API → add its key to `sensitiveKeys` (covered by `test/core/network/network_log_interceptor_test.dart`).

## A remote source

```dart
class OrderRemoteSource extends BaseRemoteSource {
  OrderRemoteSource(super.dio);

  Future<OrderModel> getOrder(int id) => callApi(
    dio.get<dynamic>(ApiEndpoints.order(id)),
    (data) => OrderModel.fromJson(data as Map<String, dynamic>),
  );

  Future<void> cancel(int id) => callApi(
    dio.post<dynamic>(ApiEndpoints.cancelOrder(id)),
    (_) {},
  );
}

@riverpod
OrderRemoteSource orderRemoteSource(Ref ref) => OrderRemoteSource(ref.watch(dioClientProvider));
```

Public endpoints (no token): `options: Options(extra: AuthInterceptor.skipAuth)`.

## Auth and refresh

- Tokens: `core/session/token_storage.dart` (flutter_secure_storage, cached in memory).
- Session: `core/session/session_notifier.dart` (`sessionProvider`): status `unknown → authenticated | unauthenticated` and the `SessionUser`. The router redirects on status.
- On 401 the auth interceptor (a `QueuedInterceptor`, so concurrent 401s refresh once) calls `/auth/refresh` with a plain Dio, saves the new tokens and retries the request on the plain Dio. If refresh fails it calls `session.expire()` and the request fails with `UnauthorizedException`; the router sends the user to login if the screen is protected (a public screen stays, as a guest). A 401 on a request made with no tokens (a guest) skips the refresh and asks the app to open login (`signInPromptProvider`; see `routing.md`).
- **Adapt to your backend**: the refresh request body/response keys in `AuthInterceptor._refresh`, and `ApiEndpoints.refreshToken`.

Retries go through the plain Dio on purpose: going back through the queued interceptor would put the retry's own error behind the one waiting for it, and deadlock. `test/core/network/auth_interceptor_test.dart` covers this.

## Connectivity

`connectivityProvider` (`core/connectivity/connectivity_notifier.dart`) is `true` while the internet is actually reachable: `connectivity_plus` reports the link, then a HEAD to `EnvConfig.reachabilityUrl` confirms it (captive portals report Wi-Fi with no internet). The offline banner and the connectivity interceptor read it. Future offline support plugs in at the repository (see `layers.md`).
