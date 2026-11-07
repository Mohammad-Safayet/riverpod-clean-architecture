# State and screens

Everything a screen shares lives in `core/base/base_screen.dart`, so a change there reaches every screen.

## BaseScreen

```dart
class OrdersScreen extends BaseScreen {
  const OrdersScreen({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context, WidgetRef ref) =>
      AppBar(title: Text(context.l10n.ordersTitle));

  @override
  Widget body(BuildContext context, WidgetRef ref) => asyncBody(
    ref.watch(ordersProvider),
    onRetry: ref.read(ordersProvider.notifier).retry,
    data: (orders) => OrderList(orders: orders),
  );
}
```

- `BaseScreen` is a `ConsumerWidget`. Use `BaseStatefulScreen` + `BaseScreenState<T>` when the screen owns controllers (`TextEditingController`, `ScrollController`, animations) or needs `initState`/`dispose`. Both share `BaseScreenMixin`, which holds everything below.
- **Hooks** (override as needed): `body` (required), `appBar`, `floatingActionButton`, `bottomNavigationBar`, `drawer`, `backgroundColor`, `systemOverlayStyle`, `useSafeArea`, `resizeToAvoidBottomInset`.
- **Shared data**: `logger`, `buildConfig`, `currentUser(ref)`; and from `ContextX` in any widget: `context.l10n`, `context.colors`, `context.textStyles`, `context.theme`. To give every screen something new, add a getter to `BaseScreenMixin`.
- **asyncBody**: the one loading/error/data renderer. Old data stays visible while refreshing; a retry after an error shows the loader. The loader is `AppLoading`, the error view is `AppErrorView`: change them there.

## Page data vs actions

| | Page data | Action |
|---|---|---|
| Example | product list, profile | login, submit, delete |
| Lives in | notifier `build()` returning a `Future` | notifier method |
| UI | `asyncBody` / `PagingListView` | global overlay + snackbar |
| Errors | `AsyncError` → `AppErrorView` with Retry | `callDataService` → error snackbar |

### callDataService

Mix `BaseNotifier` into the notifier:

```dart
@riverpod
class CheckoutNotifier extends _$CheckoutNotifier with BaseNotifier {
  @override
  CheckoutState build() => const CheckoutState();

  Future<void> placeOrder() => callDataService(
    ref.read(placeOrderUseCaseProvider)(state.cart),
    onSuccess: (order) => ref.read(appMessengerProvider.notifier).showSuccess('...'),
    onError: (e) => state = state.copyWith(failed: true),
  );
}
```

It shows the global blocking loader, catches every error (non-`AppException`s become `UnknownException`), posts it to the app messenger, and returns `null` on failure. Options: `showLoading: false` for background actions, `showErrorMessage: false` to handle the error yourself in `onError`. Pass a future from an `async` function so errors arrive as a failed future.

## Shared building blocks

- **Remote images**: `AppNetworkImage(url, width:, height:, borderRadius:)` and `AppAvatar(url:, name:)` (`core/widgets/app_network_image.dart`). Disk/memory cached, one placeholder and one error look for the app; invalid or empty URLs show the error look without a request. Never `Image.network` / `NetworkImage` directly.
- **Form validation**: `context.validators` (`core/utils/validators.dart`) gives localized rules: `required`, `email`, `phone` (BD mobile; adjust per market), `minLength`, `maxLength`, `match`, combined with `all([...])`. Every rule except `required` passes on empty input, so optional fields just leave `required` out.

```dart
final v = context.validators;
TextFormField(validator: v.all([v.required(), v.email()]));
TextFormField(validator: v.all([v.required(), v.minLength(8)]));
TextFormField(validator: v.match(() => _password.text));
```

New rule → a method on `Validators` + a `validation*` key in both ARB files + a test in `test/core/utils/validators_test.dart`.

## App-wide UI: AppOverlayHost

`core/widgets/app_overlay_host.dart` wraps the whole app via `MaterialApp.builder` and owns the UI that must exist exactly once: offline banner, global loader (`globalLoadingProvider`, a counter), and snackbars (`appMessengerProvider`). It isn't in `BaseScreen` because nested screens (shell + tab) would duplicate it.

Show a message from anywhere: `ref.read(appMessengerProvider.notifier).showSuccess(text)` / `showInfo` / `showError(exception)`.

## Riverpod conventions

- Codegen only (`@riverpod` / `@Riverpod(keepAlive: true)`). Keep-alive is for app-wide state (session, locale, connectivity, Dio); everything else auto-disposes.
- **Automatic retry is off app-wide** (`ProviderScope(retry: noProviderRetry)`), so errors show immediately with a Retry button instead of a long spinner. Opt in per provider with `@Riverpod(retry: ...)` if you need it.
- Inside notifiers, check `ref.mounted` before touching `state` after an `await` (the helpers already do).
- UI state with more than one field is a freezed class in `presentation/state/`.
