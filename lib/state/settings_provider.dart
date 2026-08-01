import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/session_store.dart';
import '../services/course_service.dart';

/// Owns the tenant base URL the whole app talks to. Backed by
/// [SessionStore] (SharedPreferences) so a change survives restarts, and
/// pushed into [ApiClient] so every service picks it up immediately.
///
/// This is the "easily editable" base URL surface: see SettingsScreen for
/// the UI, or [AppConfig.defaultBaseUrl] for the built-in default.
class SettingsProvider extends ChangeNotifier {
  String _baseUrl = AppConfig.defaultBaseUrl;
  String? _tenantName;
  int? _tenantId;
  bool _loading = true;

  String get baseUrl => _baseUrl;
  String? get tenantName => _tenantName;
  int? get tenantId => _tenantId;
  bool get loading => _loading;
  bool get isDefaultUrl => _baseUrl == AppConfig.defaultBaseUrl;

  Future<void> load() async {
    _baseUrl = await SessionStore.instance.readBaseUrl();
    ApiClient.instance.setBaseUrl(_baseUrl);
    _loading = false;
    notifyListeners();
    unawaited(refreshTenantInfo());
  }

  Future<void> setBaseUrl(String url) async {
    final normalized = _normalizeUrl(url);
    await SessionStore.instance.writeBaseUrl(normalized);
    _baseUrl = normalized;
    ApiClient.instance.setBaseUrl(normalized);
    _tenantName = null;
    _tenantId = null;
    notifyListeners();
    unawaited(refreshTenantInfo());
  }

  Future<void> resetToDefault() async {
    await setBaseUrl(AppConfig.defaultBaseUrl);
  }

  Future<void> refreshTenantInfo() async {
    try {
      final info = await CourseService().tenantInfo();
      _tenantName = info['tenant_name']?.toString();
      _tenantId = info['tenant_id'] as int?;
      notifyListeners();
    } catch (_) {
      // Best-effort only — surfaced elsewhere (e.g. courses screen) if the
      // host is genuinely unreachable/misconfigured.
    }
  }

  static String _normalizeUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }
}
