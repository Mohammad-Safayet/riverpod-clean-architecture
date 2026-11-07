# Release

Pushing a tag `vX.Y.Z` runs `.github/workflows/release.yml`:

1. **version**: fails unless `X.Y.Z` equals the `version:` in `pubspec.yaml` (the part before `+`).
2. **android**: builds the prod app bundle and uploads it to the Play **internal** track (`android/fastlane`, lane `deploy_internal`).
3. **ios**: builds prod, signs with fastlane match, uploads to **TestFlight** (`ios/fastlane`, lane `deploy_beta`).

Production is promoted by hand: Play Console (or `cd android && bundle exec fastlane promote_production`) and App Store Connect → submit for review. Staging isn't distributed.

## Shipping a version

```
# pubspec.yaml: version: 1.2.0+12   (build number must go up every upload)
git commit -am "Release 1.2.0"
git tag v1.2.0
git push && git push --tags
```

## Obfuscation and symbols

Release builds (CI, `make aab-prod`, `make ipa-prod`, the iOS lane) use `--obfuscate --split-debug-info=build/symbols/<platform>`: Dart class and function names are scrambled in the shipped app, and the symbol files needed to read stack traces are written next to the build. CI keeps them as the `symbols-android-vX.Y.Z` / `symbols-ios-vX.Y.Z` artifacts (with Android's R8 `mapping.txt`) for 90 days. Download and archive them for every version still in users' hands.

Reading an obfuscated stack trace:

```
fvm flutter symbolize -i crash.txt -d build/symbols/android/app.android-arm64.symbols
```

Crash services do this automatically once the symbols are uploaded (Sentry: `sentry_dart_plugin`; Crashlytics: `firebase crashlytics:symbols:upload`). Add that upload as a CI step when you plug in a `CrashReporter`.

Obfuscation renames types, so never base logic on `runtimeType.toString()` (logging it is fine).

## One-time setup

### Android

1. Create the upload keystore: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`. Keep it safe; losing it means contacting Google to reset.
2. Play Console: create the app with ID `latif.safayet.riverpod_clean_architecture`, upload the **first** bundle by hand (`make aab-prod`), enrol in Play App Signing.
3. Google Cloud: service account with Play Console access ("Release manager"); download its JSON key.
4. `cd android && bundle install` and commit `android/Gemfile.lock`.

### iOS (needs a Mac once)

1. Apple Developer: register the bundle IDs (prod, `.dev`, `.staging`); App Store Connect: create the app for the prod ID.
2. Create a **private** git repo for certificates; set `MATCH_GIT_URL`.
3. `cd ios && bundle install && bundle exec fastlane match appstore`: creates the distribution certificate and profiles and stores them encrypted (remember the passphrase = `MATCH_PASSWORD`). Commit `ios/Gemfile.lock`.
4. App Store Connect → Users and Access → Integrations → **App Store Connect API** key (App Manager). Download the `.p8`.

## GitHub secrets

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` | from step 1 |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | the JSON key contents |
| `APPLE_TEAM_ID` | 10-character team ID |
| `MATCH_GIT_URL` | certificates repo URL |
| `MATCH_PASSWORD` | match passphrase |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `base64("<github-user>:<token with repo read>")` for the certificates repo |
| `ASC_KEY_ID`, `ASC_ISSUER_ID` | from the API key page |
| `ASC_KEY_P8_BASE64` | `base64 -i AuthKey_XXXX.p8` |

## Locally

```
make aab-prod && cd android && bundle exec fastlane deploy_internal
cd ios && bundle exec fastlane deploy_beta      # with the env vars above exported
```

None of this has run against real store accounts yet: expect to adjust on the first release (e.g. the first Play upload must be manual).
