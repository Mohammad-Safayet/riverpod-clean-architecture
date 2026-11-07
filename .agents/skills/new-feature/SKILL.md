---
name: new-feature
description: Add a feature or a screen to this Flutter app the template way: scaffold with the Mason bricks, fill every layer, wire route and strings, test, and finish on a green `make check`. Use when asked to build, add or scaffold a feature, screen, page, or an API-backed list/detail.
---

# New feature or screen

Rules and naming live in `AGENTS.md`; this is the order of work. Each step ends on its **done** line.

## 1. Decide the shape

Settle with the user, or infer from the request and state your choice:

- **Feature or screen?** A new area of the app with its own data → feature. Another screen inside an existing feature → screen (skip to step 2b).
- **Full or lite?** Lite unless there's business logic to isolate (validation, combining sources, rules) or a second data source is planned. See `AGENTS.md` → Features.
- **Names**: feature folder plural snake_case (`orders`), model singular (`order`).
- **The API**: endpoint path(s), response JSON shape, pagination (skip/limit? page?), auth required? If the answer is buried in docs or a spec, in Claude Code delegate to the `api-scout` sub-agent and work from its spec.

Done: feature/screen, full/lite, names and endpoint shape are known.

## 2a. Scaffold a feature

```
make feature name=<plural> model=<singular> lite=<true|false>
```

(Windows without make: `./setup.ps1 feature -Name <plural> -Model <singular> [-Lite]`.)

The brick creates every layer plus a notifier test, adds `ApiEndpoints.<name>` and a `<name>Title` string to both ARB files. Done: the brick printed "Created … feature".

## 2b. Scaffold a screen

```
make screen name=<screen> feature=<feature> [stateful=true]
```

`stateful=true` when the screen owns text/scroll/animation controllers. Done: the brick printed "Created …Screen".

## 3. Fill the layers, bottom up

Replace every placeholder (`id`/`name` fields, the `TODO`s) with the real thing:

1. `data/models/*_model.dart`: fields exactly as the JSON. Nested objects get their own model.
2. `core/network/api_endpoints.dart`: the real path(s).
3. `data/sources/*_remote_source.dart`: one method per endpoint, each through `callApi(request, parse)`.
4. Full only: `domain/entities` (what the UI needs, not the JSON), `toEntity()`, repository interface, use cases (one per action; add rules here), `<name>_providers.dart`.
5. Repository: maps/combines, returns models (lite) or entities (full).
6. Notifier: page data in `build()`; paginated lists use `PaginatedNotifier` (`docs/architecture/pagination.md`); user actions are methods using `callDataService` (add `with BaseNotifier`); an action that needs an account starts with `if (!requireSignIn()) return;`. Public (guest-browsable) screens: add their path to `_publicPaths` in `app/router/routes.dart`, otherwise the route is login-only.
7. Screen: `BaseScreen` hooks, `asyncBody(...)` for page data, `context.l10n` / `context.colors` / `context.textStyles` / `AppValues` for everything visual. Extract widgets into `presentation/widgets/` once a build method passes ~60 lines.

Done: no `TODO` or placeholder field left in the new files; `make gen` succeeds.

## 4. Wire it in

- Route: add a `TypedGoRoute` in `lib/app/router/routes.dart` (inside a shell branch if it lives under a bottom-nav tab) and navigate with the generated `XRoute(...).go(context)`. See `docs/architecture/routing.md`.
- Strings: every new user-visible text is a key in **both** `app_en.arb` and `app_bn.arb` (Bangla translation, not English copied).
- Run `make gen`.

Done: the screen is reachable from the app, and no string literal is shown to the user.

## 5. Test

Extend the generated notifier test and add:

- repository test (mock the remote source): mapping, paging math, error passthrough;
- notifier test: success, failure (`thenAnswer((_) async => throw const NetworkException())`), and each action;
- widget test with `pumpTestApp` for each new screen: data, loading and error states.

In Claude Code, delegate this step to the `test-writer` sub-agent (one per layer for big features, in parallel), naming the files to cover.

Done: each new public class/method has a test exercising its success and failure paths.

## 6. Verify

```
make check
```

Fix every finding at its cause. `architecture_test.dart` failures mean a wrong import: move code to the right layer rather than editing the test. Done: `make check` is green.

## 7. Review

Get a second opinion on the new files: in Claude Code, hand them to the `reviewer` sub-agent; elsewhere, follow `.agents/skills/review/SKILL.md` on them. Fix every **must fix**, re-run `make check`.

Done: no must-fix finding open and `make check` green. Report what was created, any assumption about the API, the review verdict (with should-fix items you left), and anything left for the user (e.g. real Bangla wording to confirm).
