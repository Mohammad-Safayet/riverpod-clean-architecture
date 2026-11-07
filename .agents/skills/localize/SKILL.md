---
name: localize
description: Fix localization in this app: move hardcoded UI strings into ARB keys, fill missing or untranslated keys (real Bangla, not copied English), or add a new language end to end. Use when asked to translate, localize, add a language, or when `tool/l10n_check.dart` reports problems.
---

# Localize

`tool/l10n_check.dart` (part of `make check`) is the referee: it fails on missing/extra keys, lost `{placeholders}` and hardcoded UI strings, and warns on translations identical to English. Conventions are in `docs/architecture/l10n.md`. Each step ends on its **done** line.

## 1. Find the work

```
fvm dart run tool/l10n_check.dart
```

Add the scope the user asked for: a screen or feature ("translate the orders screen"), a new language, or everything the check reports. For a screen, also read its widgets for strings the check can't see: string variables, `SnackBar` text built elsewhere, `showDialog` content, enum labels, validation messages.

Done: a list of every string and key to handle.

## 2. Move hardcoded strings into ARB keys

For each string:

- Key name: `<area><Thing>` in lowerCamelCase (`ordersEmpty`, `checkoutPayButton`, `errorCardDeclined`). Reuse an existing key only when the meaning is identical (`actionRetry`, `actionCancel`).
- Add it to `app_en.arb` (the template). Values with variables become placeholders with metadata:

```json
"ordersCount": "{count, plural, =0{No orders} =1{1 order} other{{count} orders}}",
"@ordersCount": { "placeholders": { "count": { "type": "int" } } }
```

- Use plurals/selects instead of concatenating strings or picking text in Dart. Numbers, dates and money: format with `intl` (`NumberFormat`, `DateFormat` with the current locale) and pass the result as a `String` placeholder.
- Replace the literal with `context.l10n.<key>(...)`. Outside widgets (notifiers, repositories), don't build user text: return data or an `AppException` and let the UI pick the string (`docs/architecture/errors.md`).
- A literal that is genuinely not user-facing (debug label, brand name shown as-is) gets a trailing `// l10n-ignore`.

Done: no hardcoded UI string is left in scope.

## 3. Translate

Every key exists in every `app_<locale>.arb` with a real translation:

- Bangla (`app_bn.arb`): natural Bangla as an app would say it, Bangla digits only if the rest of the app uses them (it currently doesn't). Keep `{placeholders}` and ICU syntax exactly; translate only the words inside plural/select branches.
- Keep tone and length close to English so layouts hold; for long labels check the widget can wrap or ellipsize.
- If unsure of a translation, still write your best one and list it in the report for the user to confirm. Never leave English in a non-English file.

Done: `tool/l10n_check.dart` shows no errors and no "identical to English" warning for the keys you touched.

## 4. Adding a new language

1. Create `lib/l10n/app_<code>.arb` with `"@@locale": "<code>"` and every key from `app_en.arb`, translated (step 3 rules).
2. Add its display name to `SettingsScreen._languageNames`.
3. RTL languages (ar, ur, fa, he): check screens for `EdgeInsets.only(left/right)` / `Alignment.centerLeft` / `Positioned(left:)` and switch to `EdgeInsetsDirectional` / `AlignmentDirectional` / `PositionedDirectional`; icons that imply direction (arrows) should mirror.

Done: the language appears in Settings and every screen renders in it.

## 5. Verify

`make gen && make check`. Widget tests find text by English strings, so update any test whose expected text changed. Done: green. Report the keys added/changed and any translations the user should double-check.
