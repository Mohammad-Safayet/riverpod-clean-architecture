# AGENTS.md

Flutter template: Riverpod 3 (codegen), feature-first clean architecture, Dio, go_router typed routes, freezed. Flutter is pinned by fvm (`.fvmrc`): always run `fvm flutter …` / `fvm dart …`, never bare `flutter`.

## Commands

`make` targets (Windows: `./setup.ps1 <same name>`). The ones you need:

- `make gen`: run after touching anything annotated (`@riverpod`, `@freezed`, `@TypedGoRoute`), any `.arb` file, or assets. Generated files go in a `gen/` folder beside their source and are gitignored; a missing `gen/*.g.dart` means "run gen", not "write it by hand".
- `make check`: format check + l10n check + analyze (incl. riverpod_lint) + all tests. **Done means `make check` is green.**
- `make feature name=<plural> model=<singular> [lite=true]`, `make screen name=<x> feature=<f>`: scaffolding (Mason bricks in `bricks/`).

## Layout

```
lib/
  main_<env>.dart     flavor entry points → app/bootstrap.dart
  app/                composition root: App, bootstrap, router (routes.dart = every route)
  core/               shared by all features; imports nothing from features/ or app/
  features/<name>/    one folder per feature, full or lite (below)
  flavors/            BuildConfig singleton + per-env EnvConfig
  l10n/               app_en.arb, app_bn.arb
```

## Features: full or lite

Pick per feature. **Lite** is the default for screens that mostly show API data; choose **full** when there is business logic worth isolating or a second data source is coming.

- **full**: `domain/` (entities, repository interface, use cases) + `data/` (models, sources, repository impl) + `presentation/` + `<name>_providers.dart` (the only file that wires data to domain). Example: `features/auth`.
- **lite**: `data/` (models, sources, one concrete repository) + `presentation/`. Presentation uses the freezed models directly. Example: `features/products`.

The **repository** is the seam in both: notifiers talk only to the repository (lite) or use cases (full), never to a remote source. Caching/offline goes behind it later. Promoting lite → full: `docs/architecture/layers.md`.

## Layer rules (enforced by `test/architecture_test.dart`)

- `core/`, `flavors/` → never import `features/` or `app/`.
- A feature never imports another feature. Shared needs go to `core/` (e.g. session, locale).
- From `app/`, features may import only `app/router/routes.dart` (to navigate).
- `domain/` is pure Dart: `dart:`, `freezed_annotation`, `core/`, its own `domain/`.
- `data/` never imports `presentation/`.
- `presentation/` never imports `data/sources/`; in a **full** feature it imports no `data/` at all.

When the test fails, fix the import. Changing a rule means editing this file, `docs/architecture/layers.md` and the test together.

## Naming

| Thing | Class | File |
|---|---|---|
| Screen | `OrderDetailScreen extends BaseScreen` | `presentation/screens/order_detail_screen.dart` |
| Notifier | `OrderDetailNotifier` (`@riverpod`, generates `orderDetailProvider`) | `presentation/notifiers/order_detail_notifier.dart` |
| UI state | `OrderDetailState` (freezed) | `presentation/state/order_detail_state.dart` |
| API model | `OrderModel` (freezed + json) | `data/models/order_model.dart` |
| Entity (full) | `Order` (freezed, no json); `OrderModel.toEntity()` extension | `domain/entities/order.dart` |
| Remote source | `OrderRemoteSource extends BaseRemoteSource` | `data/sources/order_remote_source.dart` |
| Repository | lite: `OrderRepository`; full: `OrderRepository` interface + `OrderRepositoryImpl` | `data/repositories/`, `domain/repositories/` |
| Use case (full) | `GetOrderListUseCase` with `call()` | `domain/usecases/get_order_list_usecase.dart` |

"Screen", never "view" or "page". Provider names come from the generator, which strips the `Notifier` suffix.

## Writing code

- **Screens** extend `BaseScreen`, or `BaseStatefulScreen` when they own controllers. Override `body` and only the hooks you need (`appBar`, `floatingActionButton`, …). **Page data** (loads on open) is an `AsyncNotifier` rendered with `asyncBody(...)`. **Actions** (submit, delete, login) are notifier methods using `callDataService(...)` from `with BaseNotifier`: it shows the global loader and the error snackbar. The loader, error view and snackbar exist once, in `core/`; screens never build their own. Details: `docs/architecture/state-and-screens.md`.
- **Shared UI**: remote images through `AppNetworkImage` / `AppAvatar` (never `Image.network`); form validation through `context.validators` (never inline validator lambdas with literal messages). Details: `docs/architecture/state-and-screens.md`.
- **Errors**: data code throws an `AppException` subtype; `BaseRemoteSource.callApi` does the mapping. User-facing text comes from `AppException.localizedMessage`. Unexpected errors reach `CrashReporter` automatically (zone, Flutter, providers, `callDataService`); don't call a crash SDK directly. Details: `docs/architecture/errors.md`.
- **Networking**: endpoints are constants in `core/network/api_endpoints.dart`; every request goes through `callApi`. Auth/refresh/offline are interceptors. Details: `docs/architecture/networking.md`.
- **Lists that page**: `PaginatedNotifier` mixin + `PagingListView`. Details: `docs/architecture/pagination.md`.
- **Navigation**: typed routes only (`ProductDetailRoute(id: 1).go(context)`); add routes in `app/router/routes.dart`. Details: `docs/architecture/routing.md`.
- **Guests**: the app is open to browse, login to act. A new route is login-only until added to `_publicPaths` in `app/router/routes.dart`; an action that needs an account starts with `if (!requireSignIn()) return;` (from `BaseNotifier`). Details: `docs/architecture/routing.md`.
- **Strings**: every user-visible string is an ARB key in both `app_en.arb` and `app_bn.arb`, read as `context.l10n.key`. Colors/text styles come from `context.colors` / `context.textStyles`; spacing from `AppValues`. Details: `docs/architecture/l10n.md`.
- **Imports**: always `package:riverpod_clean_architecture/...`, never relative (`../`), sorted (lints `always_use_package_imports`, `directives_ordering`; `make format` fixes both). Only two things stay relative: part lines, which are always exactly `part 'gen/<file>.g.dart';` / `part 'gen/<file>.freezed.dart';` (build.yaml routes output there), and test files importing `test/helpers/`, since `test/` isn't part of the package.
- **Reuse first**, in this order, before writing something new: what `core/` already has (base classes, widgets, `AppValues`, `callApi`, `PaginatedNotifier`, extensions), then the Dart/Flutter SDK and packages already in `pubspec.yaml`, then a small owned implementation. A new package comes last and needs a stated reason a few owned lines wouldn't do. This applies to code, not to the architecture: the layers, `BaseScreen` and the test requirements stay as specified.
- **Surgical changes**: touch only what the task needs. No drive-by refactors, renames or reformatting of unrelated code in the same change; note them as follow-ups instead, so every diff stays reviewable.
- **State assumptions**: when the request leaves something open (API shape, full vs lite, which screen, edge-case behaviour), ask if it changes the outcome; otherwise pick, and say what you assumed in your report. Never guess silently.
- **Visible shortcuts**: a deliberate simplification (hardcoded limit, skipped edge case, temporary workaround) gets `// shortcut: <what and why>, revisit when <condition>` on the line. Never leave one silent.
- **Stable APIs only**: nothing marked experimental (e.g. Riverpod `Mutation`, offline persistence). This template ships production apps.
- **Tests** mirror `lib/`. Use `mocktail`, `pumpTestApp(...)` from `test/helpers/test_app.dart` for widgets, and `ProviderContainer(retry: noProviderRetry, overrides: [...])` for notifiers. Mock async failures with `thenAnswer((_) async => throw …)`.

## Skills

This project's conventions win over general Flutter skills (e.g. the `dart-flutter` plugin's): networking is Dio via `callApi` (not `http`), models are freezed + json_serializable (not hand-written `fromJson`), layers follow this file, and routing, l10n and architecture are already set up, so never re-scaffold them. Use that plugin for its tooling: runtime errors, hot reload, widget inspector, integration tests, package conflicts.

Step-by-step workflows in `.agents/skills/<name>/SKILL.md`. When a task matches, read that file and follow it:

- `start-project`: turn the template into a new app (rename IDs/package/names, drop demo features).
- `new-feature`: a new feature or a screen.
- `add-endpoint`: wire an API endpoint into an existing feature.
- `localize`: hardcoded strings, missing/untranslated keys, a new language.
- `review`: review a diff/branch/files against these rules before a PR.

## Other references

- Flavors, app IDs, icons, iOS schemes: `docs/architecture/flavors.md`
- Code generation setup (watch, IDEs): `docs/architecture/codegen.md`
- Store release, signing, CI secrets: `docs/architecture/release.md`
