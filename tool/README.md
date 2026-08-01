# tool/brand_app.dart

Rebrands this project in place for one academy: app display name, app
icon/splash logo, and the default tenant base URL the app talks to. Intended
to be run once per academy, right before building that academy's APK/IPA,
against a checkout of this repository dedicated to that build.

## Usage

Run from the project root.

```bash
dart run tool/brand_app.dart \
  --name "Daniel's Academy" \
  --base-url https://daniel.probahi.com \
  --logo https://daniel.probahi.com/static/img/logo.png \
  --color 0B5FFF
```

Or with a JSON config file (see `tool/example_academy.json`):

```bash
dart run tool/brand_app.dart --config tool/example_academy.json
```

Command-line flags take precedence over the config file when both are given.

| Flag | Config key | Required | Description |
|---|---|---|---|
| `--name`, `-n` | `name` | Yes | App display name shown under the icon and in the OS app switcher. |
| `--base-url`, `-u` | `base_url` | Yes | Tenant base URL, e.g. `https://daniel.probahi.com`. Must start with `http://` or `https://`. |
| `--logo`, `-l` | `logo` | No | An `http(s)://` URL or a local file path. If omitted, a plain placeholder image is generated instead. |
| `--color` | `color` | No | 6-digit hex splash screen background color, e.g. `0B5FFF`. Defaults to `FAFAFA`. |
| `--allow-server-override` | `lock_server: false` | No | Keeps the in-app "Academy / server" screen enabled. By default the app is locked to `--base-url` and that screen is hidden. |
| `--skip-icons` | — | No | Skip regenerating launcher icons and splash screens (faster iteration on name/URL only). |
| `--config`, `-c` | — | No | Path to a JSON file providing any of the above as `name`, `base_url`, `logo`, `color`, `lock_server`. |

## What it changes

| File | Change |
|---|---|
| `assets/branding/logo.png` | Downloaded/copied from `--logo`, or generated as a placeholder. |
| `lib/core/config.dart` | `appName`, `defaultBaseUrl`, `allowServerOverride`, `hasLogo`. |
| `pubspec.yaml` | `description`, and `flutter_native_splash`'s `color` (both occurrences). |
| `android/app/src/main/AndroidManifest.xml` | `android:label`. |
| `ios/Runner/Info.plist` | `CFBundleDisplayName`, `CFBundleName`. |

It then runs `flutter pub get`, `dart run flutter_launcher_icons`, and
`dart run flutter_native_splash:create` to regenerate the actual icon and
splash screen image files for Android and iOS from
`assets/branding/logo.png`.

## What it does not change

- **Application id / bundle id.** All academy builds produced from this
  script share `com.probahi.probahi` (Android) and the bundle identifier set
  in the iOS Runner target. That's fine for sideloading or a single
  organization's internal distribution, but the App Store and Play Store
  each require a **unique** application id / bundle id per listing. Setting
  those is a separate, manual step (Android: `applicationId` in
  `android/app/build.gradle.kts` plus moving
  `android/app/src/main/kotlin/.../MainActivity.kt` to match; iOS: the
  Runner target's Bundle Identifier in Xcode) — do this before publishing
  two academies' apps as separate store listings.
- **Version number.** `pubspec.yaml`'s `version:` is untouched; bump it
  yourself per release as usual.
- **In-app color theme.** Only the native splash screen background color is
  configurable here. The app's Material theme (`lib/core/app_colors.dart`,
  `lib/core/app_theme.dart`) is shared code, not per-academy.

## Repeated use

Safe to re-run: every substitution targets a specific, already-known line
(by exact pattern, not by diffing against the previous value), so running it
again with different arguments overwrites the previous branding cleanly.
