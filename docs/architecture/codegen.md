# Code generation

Generated: Riverpod providers, json and typed routes (`*.g.dart`), freezed (`*.freezed.dart`), assets (`lib/gen/`), l10n (`lib/l10n/generated/`). None of it is committed; `make gen` (or CI) recreates it.

## Where generated files go

Each one lands in a `gen/` folder beside its source, so no source file needs a `../` path:

```
data/models/
  product_model.dart              part 'gen/product_model.freezed.dart';
                                  part 'gen/product_model.g.dart';
  gen/
    product_model.freezed.dart    part of '../product_model.dart';  (generated)
    product_model.g.dart
```

Set up by the two `build_extensions` rules in `build.yaml` (source_gen's combining builder for `.g.dart`, and freezed). The `part` line must be exactly `part 'gen/<file>.g.dart';` / `part 'gen/<file>.freezed.dart';`: source_gen matches it as literal text (a `package:` URI is rejected), and the build warns with the exact line if it's wrong. Moving a file keeps its part lines valid; just regenerate. The bricks already write them this way.

Tried and rejected: one shared `lib/gen/` tree. It works, but every source would need `part '../../../../gen/…'`.

## Never forgetting to run it

- **Keep `build_runner watch` running**: it regenerates on every save, so hot reload always sees fresh code.
- **VS Code**: `.vscode/tasks.json` starts the watcher when the folder opens (VS Code asks once: "Allow automatic tasks"). Every launch config (dev/staging/prod) has it as `preLaunchTask`: started if not running, reused if running, and the launch waits for the current build to finish.
- **Android Studio**: shared run configs in `.run/` (dev/staging/prod) run `build_runner build` before each launch. For regeneration during hot reload, start the `build_runner watch` run config. Note: a `build` stops a running `watch` ("Exiting as requested by another build_runner process"), so restart the watch after launching if you rely on it. The before-launch step is a Shell Script config; on Windows set Settings → Tools → Terminal's shell to PowerShell if it can't find `fvm`.
- **Terminal**: `make watch` / `./setup.ps1 watch`. `make run-dev` runs `gen` first.
- **CI** generates before analyze/test, so stale or missing code fails the PR, not production.

`.vscode/settings.json` keeps `gen/` folders out of search. No IDE setup is needed to keep feature folders tidy.

## build_runner notes

- This build_runner version dropped `--delete-conflicting-outputs`; plain `build` handles conflicts.
- `build.yaml` limits `go_router_builder` to `lib/app/router/` and sets json_serializable defaults (`explicit_to_json: true`; change `field_rename` to `snake` if your API uses snake_case).
- Generated code isn't formatted at our 100-column width, so the format check (`tool/format_check.dart`) skips generated files.
