---
name: add-endpoint
description: Wire a new API endpoint into an existing feature: models from the JSON, endpoint constant, remote source method, repository (and use case for full features), optional notifier/UI, tests, green `make check`. Use when given an endpoint, curl command, sample response or API spec to integrate.
---

# Add an endpoint to a feature

For a feature that doesn't exist yet, use `new-feature` instead. Rules and naming are in `AGENTS.md`. Each step ends on its **done** line.

## 1. Pin down the endpoint

Collect, from the request or by asking:

- **Feature** it belongs to. **Full** if `lib/features/<f>/domain/` exists, otherwise **lite**: this decides steps 4–5.
- **Method + path**, path/query parameters, request body.
- **A real response sample** (JSON). Ask for one rather than guessing fields; for an error-prone API also ask for an error response. Note which fields can be missing or null.
- **Auth**: needs the bearer token (default) or public (`skipAuth`)?
- **Paginated?** (skip/limit, page, cursor) → `PageResult` + `PaginatedNotifier` (`docs/architecture/pagination.md`).
- **Use**: page data shown on a screen, an action (submit/delete), or only data-layer for now.

When the answers live in long docs, an OpenAPI/Swagger spec or a Postman collection, in Claude Code delegate to the `api-scout` sub-agent and work from the spec it returns.

Done: every item above has an answer, and you have a response sample.

## 2. Models (`data/models/`)

- One freezed + json class per JSON object, nested objects included: `XModel`, file `x_model.dart`.
- Field names follow the JSON; for snake_case keys use `@JsonKey(name: 'created_at')` (or switch `field_rename` in `build.yaml` if the whole API is snake_case).
- Fields that can be absent → nullable or `@Default(...)`. Dates → `DateTime`. Enums → Dart `enum` with `@JsonValue`, plus an `unknown` fallback via `@JsonKey(unknownEnumValue: ...)`.
- Request bodies get their own `XRequestModel` with `toJson`.
- Full feature: add/extend the entity in `domain/entities/` (only what the app needs) and a `toEntity()` extension in the model file.

Done: `make gen` succeeds.

## 3. Endpoint + remote source

- Add a constant (or a function for path params) to `lib/core/network/api_endpoints.dart`.
- Add a method to the feature's `XRemoteSource`, wrapping the request in `callApi(request, parse)`. Public endpoint → `options: Options(extra: AuthInterceptor.skipAuth)`. Envelopes (`{data: ...}`) are unwrapped in `parse`.

Done: the method returns models and every Dio call in it goes through `callApi`.

## 4. Repository (and use case)

- **Lite**: a method on `XRepository`, returning models (or `PageResult<XModel>`).
- **Full**: the method on the `XRepository` interface (entities in, entities out), implemented in `XRepositoryImpl` with `toEntity()`; a use case in `domain/usecases/` when it's a distinct action or carries rules (validation, combining calls); its provider in `<feature>_providers.dart`.

Done: callers can reach the endpoint through the repository/use case without touching `data/sources/`.

## 5. Notifier and UI (only if asked in step 1)

- Page data: a notifier whose `build()` returns the future (family `build(int id)` for detail by ID), rendered with `asyncBody`. Paginated: `PaginatedNotifier` + `PagingListView`.
- Action: a method on the screen's notifier using `callDataService` (`with BaseNotifier`); refresh affected page data afterwards with `ref.invalidate(...)`.
- New strings in both ARB files; a new screen also needs a route (`docs/architecture/routing.md`).

Done: the data is visible or the action is triggerable in the app.

## 6. Tests

- Model: `fromJson` on the real sample (kept as a const map in the test), including the missing/null fields.
- Repository: mock the remote source with mocktail; check mapping, paging math, and that an `AppException` passes through.
- Use case (full): its rules.
- Notifier/screen if added: success and failure (`thenAnswer((_) async => throw const NetworkException())`).

In Claude Code you can delegate this step to the `test-writer` sub-agent, naming the changed files and the response sample.

Done: each new method has a success and a failure test.

## 7. Verify and review

`make check` until green. Then get a second opinion on the changed files: in Claude Code, the `reviewer` sub-agent; elsewhere, `.agents/skills/review/SKILL.md`. Fix every **must fix** and re-run `make check`.

Done: green with no must-fix open. Report the endpoint as wired (method, path, which layers changed), any assumption made about fields, and the review verdict.
