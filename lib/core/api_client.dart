import 'package:dio/dio.dart';

import 'config.dart';
import 'session_store.dart';

/// Thin Dio wrapper shared by every service.
///
/// Responsibilities:
/// - Points at the current tenant base URL (editable at runtime, see
///   [setBaseUrl] / SettingsScreen).
/// - Attaches `X-Session-Token` to every request once we have one.
/// - Watches every response for `meta.session_token` (allauth headless
///   convention, see REST_API.md §2.1) and persists it whenever present,
///   even on non-2xx responses (e.g. a partially-completed signup flow).
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // We handle non-2xx responses ourselves (allauth headless uses
        // 400/401/409/410 as regular, parseable JSON responses).
        validateStatus: (_) => true,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SessionStore.instance.readSessionToken();
          if (token != null && token.isNotEmpty) {
            options.headers['X-Session-Token'] = token;
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          await _persistSessionTokenIfPresent(response.data);
          handler.next(response);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  Dio get dio => _dio;

  String get baseUrl => _dio.options.baseUrl;

  void setBaseUrl(String url) {
    _dio.options.baseUrl = _normalize(url);
  }

  static String _normalize(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Future<void> _persistSessionTokenIfPresent(dynamic data) async {
    if (data is Map && data['meta'] is Map) {
      final token = (data['meta'] as Map)['session_token'];
      if (token is String && token.isNotEmpty) {
        await SessionStore.instance.writeSessionToken(token);
      }
    }
  }
}
