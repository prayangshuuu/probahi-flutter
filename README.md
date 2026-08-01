# Probahi (Flutter)

Mobile client for the Probahi multi-tenant LMS. Student-facing only: browse courses, sign in, enroll, and view lesson content. Communicates with one tenant subdomain at a time over its REST API and the `django-allauth` headless authentication API.

## Requirements

- Flutter 3.44+, Dart 3.12+
- Xcode (iOS) or Android SDK (Android), for a simulator/device

## Setup

```bash
cd flutterapp
flutter pub get
flutter run
```

`flutter analyze` should report no issues.

## Configuration

The app targets one tenant subdomain, e.g. `https://daniel.probahi.com`. There is no endpoint to list available tenants; the target subdomain must be known in advance.

- Default value: `AppConfig.defaultBaseUrl` in `lib/core/config.dart`.
- Runtime override: Profile → "Academy / server", when `AppConfig.allowServerOverride` is `true`. Persisted with `shared_preferences`. Changing it while signed in ends the current session, since a session token is valid only for the tenant it was issued on.

To produce a per-academy build (app name, icon, splash screen, default base URL, with the runtime override screen locked/hidden), use `tool/brand_app.dart` — see `tool/README.md`.

## Project structure

```
lib/
  core/
    config.dart          Default base URL, storage keys, timeouts
    app_colors.dart       Color values
    app_theme.dart        ThemeData
    api_client.dart        Dio instance: base URL, X-Session-Token header, token capture
    api_exception.dart      Parses the three API error response shapes
    session_store.dart      Secure storage (session token), SharedPreferences (base URL)

  models/
    app_user.dart, course.dart, module.dart, lesson.dart

  services/
    auth_service.dart       Calls to /_allauth/app/v1/
    course_service.dart     Calls to /api/courses/, /api/modules/, enroll, tenant-info
    payment_service.dart    Calls to /api/initiate/

  state/
    auth_provider.dart       Current user and auth status
    settings_provider.dart    Current base URL, cached tenant name/id

  screens/
    common/     Splash screen, AuthGate (root widget)
    auth/       Login, signup, login-by-code, password reset
    home/       Course list, course detail, lesson player, bottom navigation
    payment/    Payment WebView
    profile/    Account screen
    settings/   Base URL screen

  widgets/
    app_button.dart, app_text_field.dart, course_card.dart, status_banner.dart,
    loading_view.dart, error_view.dart

  main.dart

tool/
  brand_app.dart              Rebrands the app for one academy — see tool/README.md
  create_placeholder_logo.dart Generates the default/fallback logo asset
  example_academy.json        Example config for brand_app.dart --config

assets/
  branding/logo.png    App icon / splash source image; overwritten by tool/brand_app.dart
```

## Authentication

`django-allauth` headless is used with the `app` client (`HEADLESS_CLIENTS = ("app",)`), which authenticates with a session token instead of cookies.

Every response has the form:

```json
{
  "status": 200,
  "data": {},
  "meta": {},
  "errors": []
}
```

When a response includes `meta.session_token`, it is stored and sent as the `X-Session-Token` header on subsequent requests, including calls to `/api/`. This is implemented in `lib/core/api_client.dart`. A `410` response means the stored token is no longer valid.

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/_allauth/app/v1/auth/signup` | No | Create an account. Body: `email`, `password`. |
| POST | `/_allauth/app/v1/auth/login` | No | Authenticate. Body: `email`, `password`. |
| POST | `/_allauth/app/v1/auth/code/request` | No | Request a one-time login code by email. Body: `email`. |
| POST | `/_allauth/app/v1/auth/code/resend` | No | Resend the pending one-time login code. |
| POST | `/_allauth/app/v1/auth/code/confirm` | No | Confirm a one-time login code. Body: `code`. |
| GET | `/_allauth/app/v1/auth/session` | Yes | Retrieve the current session state. |
| DELETE | `/_allauth/app/v1/auth/session` | Yes | End the current session. |
| POST | `/_allauth/app/v1/auth/password/request` | No | Send a password reset email. Body: `email`. |
| POST | `/_allauth/app/v1/auth/password/reset` | No | Reset password. Body: `key`, `password`. |
| POST | `/_allauth/app/v1/account/password/change` | Yes | Change password. Body: `current_password` (optional), `new_password`. |
| GET | `/_allauth/app/v1/config` | No | Retrieve auth configuration. |

## Course and enrollment API

Base path `/api/`. Read endpoints are unauthenticated unless noted. List endpoints are not paginated.

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/courses/` | No | List active courses: `id`, `name`, `small_description`, `price`, `currency`. |
| GET | `/api/courses/{id}/` | No | Retrieve a course, including `description`, `is_enrolled`, and `modules`. |
| GET | `/api/courses/{course_id}/modules/` | No | List modules for a course. |
| GET | `/api/modules/{id}/` | No | Retrieve a single module. |
| POST | `/api/courses/{id}/enroll/` | Yes | Enroll the authenticated user. No payment check is performed. |
| GET | `/api/tenant-info/` | No | Retrieve `tenant_id` and `tenant_name`. |

`price` is a decimal-formatted string, not a JSON number.

Each lesson is `YoutubeLesson` or `LinkLesson`, identified by matching `resourcetype` and `model_name` fields. The content field (`video_id` or `url`) is present only if the lesson is free, or the caller is authenticated and enrolled; otherwise it is absent from the response object. This is handled in `lib/models/lesson.dart` (`Lesson.isUnlocked`).

## Payment API

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/initiate/` | No | Create a payment and return a PayStation checkout URL. Body: `tenant_id`, `course_id`, `buyer_id`. |

The charged amount is derived server-side from `course.price`. This endpoint does not authenticate the caller or verify that `buyer_id` matches the caller; the app always sends the signed-in user's own id.

On completion, PayStation redirects to one of the following server-rendered (non-JSON) pages on the tenant host:

| Path | Meaning |
|---|---|
| `/payment/success/` | Payment verified; enrollment created. |
| `/payment/failure/` | Payment failed. |
| `/payment/pending/` | Payment not yet confirmed. |

`PaymentWebViewScreen` (`lib/screens/payment/payment_webview_screen.dart`) watches the WebView's navigation URL for these paths. The caller re-fetches course detail afterward to confirm `is_enrolled` rather than trusting the redirect alone.

## Error responses

Three shapes occur depending on which subsystem returns the error; all are normalized by `ApiException.fromResponse()` in `lib/core/api_exception.dart`.

1. Headless auth: `{"status": 400, "errors": [{"message": "...", "code": "...", "param": "email"}]}`
2. DRF default: `{"field": ["error message"]}` or `{"detail": "error message"}`
3. Payment API: `{"status_code": 404, "error": "...", "message": "...", "details": {}}`

## Data models

| Model | Fields |
|---|---|
| Course | `id`, `name`, `small_description`, `description`, `price`, `currency` (`BDT`), `is_enrolled` (detail endpoint only), `modules` |
| Module | `id`, `title`, `description`, `order`, `lessons` |
| Lesson | `id`, `title`, `description`, `is_free`, `order`, `model_name` / `resourcetype` (`YoutubeLesson` \| `LinkLesson`), `video_id` or `url` (conditionally present) |

## Known limitations

- No endpoint lists available tenants; the subdomain must be known in advance.
- No endpoint exposes user profile fields beyond `id`, `email`, `display`, `has_usable_password`.
- No instructor-facing API.
- Lesson content is access-controlled, not signed or expiring.
- `POST /api/initiate/` does not authenticate the caller or verify `buyer_id` server-side.
