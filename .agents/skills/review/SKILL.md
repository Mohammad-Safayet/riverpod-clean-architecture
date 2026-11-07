---
name: review
description: Review changes in this app against its architecture and conventions (the rules `make check` can't see) plus correctness, and report findings by severity with fixes. Use before opening a PR, after an AI or teammate wrote code, or when asked to review a diff, branch or files.
---

# Review

`make check` already enforces formatting, layer imports (`architecture_test.dart`), l10n keys/hardcoded strings and lints. This review covers what those can't see. The rules come from `AGENTS.md` and `docs/architecture/`; read the doc for any area the diff touches.

## 1. Scope

Pick, in order of what applies:

- the files or PR the user named;
- in a git repo: the branch versus its base (`git diff $(git merge-base HEAD main)...HEAD`, base `master` if there's no `main`) plus uncommitted changes (`git diff HEAD`);
- not a git repo: ask which files or features to review.

Read each changed file in full, not only the hunks: most violations are about what surrounds the change.

Done: the list of files under review is fixed and every one has been read.

## 2. Mechanical gate

Run `make check`. Every failure is a **must fix** finding; don't repeat what it already says in detail, link it to the file.

Done: the check result is recorded.

## 3. Rules pass

Go through every changed file against each group. A finding needs a concrete location and a concrete fix.

**Screens**
- Extends `BaseScreen` / `BaseStatefulScreen`; no own `Scaffold`, `CircularProgressIndicator`, error widget or `ScaffoldMessenger.showSnackBar`: those come from `asyncBody`, `AppLoading`, `AppErrorView`, `appMessengerProvider`.
- `BaseStatefulScreen` only when it owns controllers, and it disposes them.
- Remote images through `AppNetworkImage` / `AppAvatar`; `Image.network` / `NetworkImage` is a finding. Form validators from `context.validators`; an inline validator with its own message is a finding.
- Colors from `context.colors`, text from `context.textStyles`, spacing/radii from `AppValues`. Raw `Color(0x…)`, `Colors.*` (beyond `transparent`), inline `TextStyle(fontSize: …)` and magic paddings are findings.
- Build methods stay readable (~60 lines); larger pieces become widgets in `presentation/widgets/`.

**State (Riverpod)**
- Page data: `AsyncNotifier` `build()` + `asyncBody`/`PagingListView`. Actions: notifier method with `callDataService`. `try/catch` in a widget is a finding.
- `ref.watch` in `build`, `ref.read` in callbacks and methods; `ref.mounted` checked before touching `state` after an `await` (outside the helpers).
- No `BuildContext` or user-facing text built inside notifiers.
- `keepAlive` only for app-wide state; per-screen state auto-disposes. Families for per-ID data.
- UI state with several fields is a freezed class in `presentation/state/`.

**Data**
- Notifiers reach data only through the repository (lite) or use cases (full).
- Every Dio call inside `callApi`; endpoints in `ApiEndpoints`; no new `Dio()` instances.
- Data code throws `AppException` subtypes; nothing swallows an error into `null`/empty without a stated reason. A new `AppException` subtype has a `localizedMessage` case.
- Models: freezed; JSON keys match the API; absent fields nullable or defaulted.
- Full features: entities carry no JSON; `toEntity()` mapping is complete.

**Navigation**: typed routes only (`XRoute(...).go/push`); no string paths, no `Navigator.push(MaterialPageRoute(...))` for screens (dialogs/sheets are fine); access rules live in `sessionRedirect`.

**Scope**: changes unrelated to the task (refactors, renames, reformatting of untouched code) are a **should fix**: split them into their own change.

**Reuse and shortcuts**: new code that duplicates something `core/`, the SDK or an installed package already does is a finding (name the existing thing). A deliberate simplification without a `// shortcut: …, revisit when …` comment is a finding. List every `shortcut:` in the diff in the report so the debt stays visible.

**Dependencies and APIs**: anything new in `pubspec.yaml` needs a reason a small owned implementation wouldn't do. Nothing experimental (`@experimental`, Riverpod `Mutation`, offline persistence). No edited or committed `*.g.dart` / `*.freezed.dart`.

**Security and privacy**: no secrets, keys or tokens in code or `EnvConfig`; logs never print tokens, passwords or personal data (a new secret field in an API → its key belongs in `NetworkLogInterceptor.sensitiveKeys`); tokens only through `TokenStorage`; crash reports carry a user ID only.

**Tests**: new or changed public behaviour has a success and a failure test in the mirrored path under `test/`, using `pumpTestApp`, mocktail and `noProviderRetry`; failures mocked with `thenAnswer((_) async => throw …)`.

**Correctness**: then read the logic itself: edge cases (empty lists, null fields, last page), race conditions around `await`, wrong provider invalidated after an action, off-by-one in paging, error paths that leave the UI stuck loading.

Done: every changed file has been checked against every group above.

## 4. Report

Group findings by severity, most severe first:

- **Must fix**: breaks a rule in `AGENTS.md`, a bug, a security issue, or a `make check` failure.
- **Should fix**: works but drifts from the conventions (will confuse the next reader or the next agent).
- **Nit**: optional polish.

Each finding: `path:line`, what's wrong, which rule (or why it's a bug), and the fix (a code snippet when it's short). After the findings, a **Shortcuts** list (`path:line`: the comment) if the diff added any. End with a one-line verdict: ready, ready after must-fixes, or needs rework. If nothing is found in a group, say so briefly rather than inventing findings.

Fix things only when the user asks; then re-run `make check` and report it green.
