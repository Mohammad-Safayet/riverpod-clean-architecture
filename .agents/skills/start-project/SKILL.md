---
name: start-project
description: Turn this template into a new app: rename package, Android/iOS IDs, display names and base URL, drop unwanted demo features, and finish on a green `make check`. Use when starting a new project from this template or renaming the app.
---

# Start a project from the template

The renaming is done by `tool/rename_app.dart` (deterministic, reads the current values itself). Your job is collecting the inputs, removing demo code cleanly, and verifying. Each step ends on its **done** line.

## 1. Collect the inputs

Ask for anything not given; propose defaults from the app name:

| Input | Example | Rule |
|---|---|---|
| App name | `Shop` | flavors become "Shop Dev" / "Shop Stg" / "Shop" |
| Dart package | `shop` | lower_snake_case |
| Android app ID | `com.acme.shop` | lowercase segments, `_` allowed |
| iOS bundle ID | `com.acme.shop` | default: Android ID with `_` → `-` (iOS forbids `_`) |
| Base URL | `https://api.acme.com` | optional; same for all flavors until the user splits them in `main_*.dart` |
| Demo features to keep | `auth`, `products`, `settings` | `main/` (bottom-nav shell) stays unless the app has no tabs |

Repeat the values back as a table and get a yes before touching files: IDs are painful to change after a store upload.

Done: the user confirmed every value.

## 2. Rename

```
fvm dart run tool/rename_app.dart --name "<name>" --package <pkg> --android-id <id> [--ios-id <id>] [--base-url <url>] --dry-run
```

Check the list looks right, then run it again without `--dry-run`. Afterwards set the Bangla `appName` in `lib/l10n/app_bn.arb` (the script only updates English).

Done: the script printed "Renamed in N files" and `grep -r "<old package>" lib test` finds nothing.

## 3. Remove unwanted demo features

For each feature to drop, remove everything that references it, then let the compiler find leftovers:

- `lib/features/<f>/` and `test/features/<f>/`
- its routes, branch classes and imports in `lib/app/router/routes.dart`; its `NavigationDestination` in `features/main/presentation/screens/main_screen.dart` (indexes must match the shell branches)
- its endpoints in `core/network/api_endpoints.dart`
- its ARB keys in **both** `app_en.arb` and `app_bn.arb` (`products*`, `login*`, `nav*`, …)

Special cases:

- **Dropping `products`** (the home screen): change `home` in `sessionRedirect` (`app/router/app_router.dart`) and the entry in `_publicPaths` (`app/router/routes.dart`) to the new home route, point the login close button (`login_screen.dart`) there, and update `test/app/router/session_redirect_test.dart`.
- **Dropping `auth`** (no login in the app): make `sessionRedirect` let `unauthenticated` users through everywhere (keep `core/session/`: the interceptor and settings use it), remove the sign-in/sign-out tiles from settings, the `signInPromptProvider` listener in `app/app.dart` and `LoginRoute`, and update the redirect test. Keep `AuthInterceptor` only if the API still uses tokens.
- **Dropping everything**: keep `main/` with one placeholder tab, or replace the shell route with a single home route.

Done: `make gen` succeeds and `fvm dart analyze` reports no errors.

## 4. Icons and platforms

- Ask whether real icons exist. If yes: replace `assets/launcher/icon_{dev,staging,prod}.png` (1024×1024), run `make icons`. Otherwise leave the placeholders and say so.
- Ask whether web/desktop (`web/`, `windows/`, `macos/`, `linux/`) are needed; delete the folders that aren't.

Done: both questions answered and acted on.

## 5. Verify

```
fvm flutter clean
make setup
make check
```

Done: `make check` is green. Report the final IDs, what was removed, what's still placeholder (icons, base URL per flavor, Bangla app name), and point to `docs/architecture/release.md` for store/signing setup. Offer `git init` + first commit if the folder isn't a repository.
