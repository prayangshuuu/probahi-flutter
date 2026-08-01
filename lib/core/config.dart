/// App-wide configuration.
///
/// The four fields marked `// brand:*` below are what `tool/brand_app.dart`
/// rewrites to produce a per-academy build — see `tool/README.md`. Editing
/// them by hand works too; the markers just tell the script where to look.
class AppConfig {
  AppConfig._();

  // brand:app_name
  static const String appName = 'Probahi';

  /// Default tenant host the app talks to. Editable at runtime from the
  /// Settings screen (see [SettingsProvider]) and persisted locally, unless
  /// [allowServerOverride] is false.
  // brand:base_url
  static const String defaultBaseUrl = 'https://daniel.probahi.com';

  /// Whether the user can point the app at a different tenant host at
  /// runtime (Profile → Academy / server). A white-label build for a single
  /// academy should set this to `false` so the app stays locked to
  /// [defaultBaseUrl].
  // brand:lock_server
  static const bool allowServerOverride = true;

  /// Whether `assets/branding/logo.png` is a real logo (as opposed to the
  /// template placeholder). Screens that can show a logo check this before
  /// rendering the asset.
  // brand:has_logo
  static const bool hasLogo = false;

  static const String logoAssetPath = 'assets/branding/logo.png';

  /// SharedPreferences key the user-editable base URL is stored under.
  static const String baseUrlPrefKey = 'probahi.base_url';

  /// Secure-storage key the allauth headless session token is stored under.
  static const String sessionTokenKey = 'probahi.session_token';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
