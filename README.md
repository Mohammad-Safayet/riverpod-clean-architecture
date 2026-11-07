# Riverpod Clean Architecture

A Flutter starter for production apps: Riverpod 3 (codegen), feature-first clean architecture with an optional "lite" shape for simple features, Dio with token refresh, go_router typed routes, three flavors, en/bn localization, store release via fastlane, and an AI workflow that builds features by the same rules.

## Quick start

Needs [fvm](https://fvm.app). Flutter version is pinned in `.fvmrc`.

```bash
make setup        # Windows: ./setup.ps1
make run-dev      # Windows: ./setup.ps1 run-dev
```

`setup` also installs the git pre-commit hook (format, analyze and l10n checks on staged files). On Windows, clone with `git clone -c core.longpaths=true …`: the Mason brick templates have long paths.

Or open in VS Code and press F5 (dev/staging/prod configs; code generation starts automatically). Android Studio: pick a run config from the toolbar.

The demo runs against [DummyJSON](https://dummyjson.com). In the dev flavor the login is prefilled (`emilys` / `emilyspass`).

## What's inside

| | |
|---|---|
| **Screens** | `BaseScreen` / `BaseStatefulScreen`: one scaffold, loader, error view and set of hooks for every screen |
| **State** | Riverpod 3 `@riverpod` notifiers; page data via `AsyncValue`, actions via `callDataService` |
| **Data** | Dio + `BaseRemoteSource.callApi`, sealed `AppException`, auth + refresh-token + offline interceptors, network logs with secrets masked |
| **UI kit** | `AppNetworkImage` / `AppAvatar` (cached), localized form `Validators`, one loader/error/empty view |
| **Production** | `CrashReporter` hook (plug in Sentry/Crashlytics in one place), obfuscated release builds with symbols kept |
| **Features** | full (domain/data/presentation) or lite (data/presentation), chosen per feature |
| **Lists** | `PaginatedNotifier` + `PagingListView` |
| **Navigation** | go_router typed routes, bottom-nav shell, session-based redirect |
| **Flavors** | dev / staging / prod: separate app IDs, names, icons, `EnvConfig` |
| **Quality** | architecture test (fails on layer violations), l10n check, riverpod_lint, package-imports lint, pre-commit hook |
| **Tooling** | Mason bricks (`make feature`, `make screen`), CI on every PR, fastlane release on tag |
| **AI** | `AGENTS.md` (Codex, Claude Code via `CLAUDE.md`, others) + a `new-feature` skill |

## Daily commands

```bash
make watch                                   # keep generated code fresh (VS Code does this for you)
make feature name=orders model=order         # full feature;  lite=true for a lite one
make screen name=order_detail feature=orders # add a screen to a feature
make check                                   # format + analyze + test (what CI runs)
```

`make help` lists everything.

## Project structure

```
lib/
  main_dev.dart · main_staging.dart · main_prod.dart
  app/            bootstrap, App, router (routes.dart)
  core/           base classes, network, session, storage, theme, widgets, l10n
  features/
    auth/         full example (login)
    products/     lite example (paginated list + detail)
    settings/     language + sign out
    main/         bottom-nav shell
  flavors/        BuildConfig, EnvConfig
  l10n/           app_en.arb, app_bn.arb
bricks/           Mason templates (feature, screen)
docs/architecture/  how each part works
tool/             rename, iOS flavor setup, icons, format + l10n checks
```

## Docs

Start with [AGENTS.md](AGENTS.md) (the rules, short), then:

[layers](docs/architecture/layers.md) · [state & screens](docs/architecture/state-and-screens.md) · [errors](docs/architecture/errors.md) · [networking](docs/architecture/networking.md) · [pagination](docs/architecture/pagination.md) · [routing](docs/architecture/routing.md) · [l10n & theme](docs/architecture/l10n.md) · [flavors](docs/architecture/flavors.md) · [codegen](docs/architecture/codegen.md) · [release](docs/architecture/release.md)

## Building with AI

The repo ships skills for Claude Code (`.claude/skills/`) and Codex (`.agents/skills/`, the canonical copies); other agents reach them through `AGENTS.md`. Just describe the task:

| Skill | Say something like |
|---|---|
| `start-project` | "Start a new app called Shop, package `shop`, ID `com.acme.shop`" |
| `new-feature` | "Add an orders feature that lists `/orders`" |
| `add-endpoint` | "Add `POST /orders/{id}/cancel` to orders, here's the response: …" |
| `localize` | "Translate the checkout screen", "Add Arabic" |
| `review` | "Review my changes before I open a PR" |

Each one ends on a green `make check`, and the checks (architecture test, l10n check, riverpod_lint) make mistakes fail loudly instead of slipping through.

### Sub-agents (Claude Code)

`.claude/agents/` defines workers with their own context, which the skills hand off to automatically:

| Sub-agent | Role | Can edit |
|---|---|---|
| `api-scout` | API docs / OpenAPI / public endpoint → compact endpoint spec | nothing |
| `test-writer` | writes tests in the template's style and runs them until green (Sonnet) | `test/` only |
| `reviewer` | fresh-eyes review against `AGENTS.md` + correctness, findings by severity | nothing |

Flow for an API-backed feature: `api-scout` → `new-feature`/`add-endpoint` → `test-writer` → `reviewer`. You can also call one directly: "use the reviewer on my changes". Other agents run the same steps from the skills.

### Dart and Flutter plugin

The Flutter team's official [`dart-flutter` plugin](https://github.com/flutter/agent-plugins) adds the Dart MCP server (analyzer, hot reload, runtime errors, widget inspector, pub.dev search) and Flutter skills (integration tests, layout fixes, package conflicts).

- **Claude Code**: `.claude/settings.json` registers it, so you're asked to install it when you trust the folder. Or run `/plugin marketplace add flutter/agent-plugins` then `/plugin install dart-flutter@dart-flutter`.
- **Codex, Cursor, others**: follow [Get started developing with AI](https://docs.flutter.dev/ai/get-started).

The MCP server runs the `dart` on your PATH; with fvm, make sure that's the pinned SDK (`fvm global 3.47.9`, or `.fvm/flutter_sdk/bin` on PATH). Where its general skills disagree with this template (e.g. `http`, hand-written JSON), `AGENTS.md` takes precedence.

## Using this template for a new app

Ask your agent to run `start-project`, or by hand:

1. Rename everything (package, Android/iOS IDs, flavor names, base URL):
   ```bash
   fvm dart run tool/rename_app.dart --name "Shop" --package shop --android-id com.acme.shop --dry-run
   ```
   Drop `--dry-run` to apply. The iOS ID defaults to the Android one with `_` → `-`; pass `--ios-id` to choose it.
2. Delete the demo features you don't need (`lib/features/<f>`, `test/features/<f>`, their routes in `lib/app/router/routes.dart`, endpoints, ARB keys).
3. **API**: per-flavor `baseUrl` in `main_*.dart`, error body in `core/network/error_mapper.dart`, refresh call in `core/network/interceptors/auth_interceptor.dart`.
4. **Icons**: replace `assets/launcher/icon_*.png`, `make icons`.
5. `fvm flutter clean && make setup && make check`.

## License

[MIT](LICENSE)
