# Flavors

| Flavor | Entry point | Android app ID | iOS bundle ID | App name |
|---|---|---|---|---|
| dev | `lib/main_dev.dart` | `latif.safayet.riverpod_clean_architecture.dev` | `latif.safayet.riverpod-clean-architecture.dev` | Riverpod CA Dev |
| staging | `lib/main_staging.dart` | `….staging` | `….staging` | Riverpod CA Stg |
| prod | `lib/main_prod.dart` | `latif.safayet.riverpod_clean_architecture` | `latif.safayet.riverpod-clean-architecture` | Riverpod CA |

iOS IDs use hyphens because bundle IDs can't contain underscores. All three install side by side.

Run: `make run-dev`, or `fvm flutter run --flavor dev -t lib/main_dev.dart`, or the IDE launch configs.

## Dart side

`main_<env>.dart` calls `bootstrap(environment:, config: EnvConfig(...))`, which locks `BuildConfig.instance` (read anywhere: `BuildConfig.instance.config.baseUrl`, `.isDev`, …; screens have `buildConfig`). To add a setting: add a field to `EnvConfig`, set it in all three `main_*.dart`.

Secrets don't belong in `EnvConfig` (it ships in the binary). Keep API keys server-side, or inject with `--dart-define` from CI.

## Android

`android/app/build.gradle.kts`: `productFlavors` dev/staging/prod with `applicationIdSuffix` and a `resValue` `app_name` (needs `buildFeatures.resValues = true` on AGP 9+). Release signing reads `android/key.properties` (copy from `key.properties.example`); without it release builds fall back to debug keys.

`android/gradle.properties` sets `kotlin.incremental=false`: on Windows the Kotlin cache breaks when the project and the pub cache are on different drives. Remove it on macOS/Linux for faster builds if you like.

## iOS

Flavors need build configurations (`Debug-dev`, `Release-dev`, `Profile-dev`, … ×3) and a shared scheme per flavor. `tool/ios_flavors.dart` created them (no Xcode needed). It sets `PRODUCT_BUNDLE_IDENTIFIER` and `APP_DISPLAY_NAME` per flavor; `Info.plist` uses `$(APP_DISPLAY_NAME)`. `ios/Podfile` maps each config to debug/release for CocoaPods.

The script is idempotent; rerun it only on a fresh `ios/` folder. To rename the app, change the constants at its top and the values in the pbxproj (search for the old ID).

**Not yet verified on a Mac**: open `ios/Runner.xcworkspace` once in Xcode, pick the `dev` scheme, and run. Signing is automatic for debug builds (set your team in Xcode); release signing is fastlane match (see `release.md`).

## Launcher icons

`assets/launcher/icon_<flavor>.png` (1024×1024; placeholders made by `tool/placeholder_icons.dart`) + `flutter_launcher_icons-<flavor>.yaml`. After replacing the images:

```
make icons
fvm dart run tool/ios_flavors.dart --flavor-icons   # only once: points each flavor at AppIcon-<flavor>
```
