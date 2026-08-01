import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/session_store.dart';
import '../models/app_user.dart';

/// Talks to django-allauth's headless "app" client API
/// (`/_allauth/app/v1/...`). See REST_API.md §2.
class AuthService {
  AuthService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  static const _base = '/_allauth/app/v1';

  AppUser? _userFromResponse(Response response) {
    final data = response.data;
    if (response.statusCode == 200 &&
        data is Map &&
        data['data'] is Map &&
        (data['data'] as Map)['user'] is Map) {
      return AppUser.fromJson(
        Map<String, dynamic>.from((data['data'] as Map)['user'] as Map),
      );
    }
    return null;
  }

  Future<AppUser> signup({required String email, required String password}) async {
    final response = await _dio.post(
      '$_base/auth/signup',
      data: {'email': email, 'password': password},
    );
    final user = _userFromResponse(response);
    if (user == null) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
    return user;
  }

  Future<AppUser> login({required String email, required String password}) async {
    final response = await _dio.post(
      '$_base/auth/login',
      data: {'email': email, 'password': password},
    );
    final user = _userFromResponse(response);
    if (user == null) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
    return user;
  }

  /// Requests a one-time login code be emailed. A `401` here is the
  /// *expected* outcome (flow pending) — only a real `400` is an error.
  Future<void> requestLoginCode(String email) async {
    final response = await _dio.post(
      '$_base/auth/code/request',
      data: {'email': email},
    );
    if (response.statusCode == 400) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
  }

  Future<void> resendLoginCode() async {
    final response = await _dio.post('$_base/auth/code/resend');
    if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode != 409) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
  }

  Future<AppUser> confirmLoginCode(String code) async {
    final response = await _dio.post(
      '$_base/auth/code/confirm',
      data: {'code': code},
    );
    final user = _userFromResponse(response);
    if (user == null) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
    return user;
  }

  /// Returns the current authenticated user, or `null` if there is no
  /// active session (including: no token stored, or it was rejected).
  Future<AppUser?> getSession() async {
    final token = await SessionStore.instance.readSessionToken();
    if (token == null || token.isEmpty) return null;

    final response = await _dio.get('$_base/auth/session');
    if (response.statusCode == 410) {
      await SessionStore.instance.clearSessionToken();
      return null;
    }
    return _userFromResponse(response);
  }

  Future<void> logout() async {
    try {
      await _dio.delete('$_base/auth/session');
    } finally {
      await SessionStore.instance.clearSessionToken();
    }
  }

  Future<void> requestPasswordReset(String email) async {
    final response = await _dio.post(
      '$_base/auth/password/request',
      data: {'email': email},
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
  }

  /// [key] is the token embedded in the emailed reset link
  /// (`?key=...`), pasted in by the user.
  Future<void> resetPassword({required String key, required String password}) async {
    final response = await _dio.post(
      '$_base/auth/password/reset',
      data: {'key': key, 'password': password},
    );
    final user = _userFromResponse(response);
    if (user == null && (response.statusCode ?? 500) >= 400) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
  }

  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    final response = await _dio.post(
      '$_base/account/password/change',
      data: {
        'current_password': ?currentPassword,
        'new_password': newPassword,
      },
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
  }

  /// `GET /_allauth/app/v1/config` — drives which auth methods to show.
  Future<Map<String, dynamic>> getConfig() async {
    final response = await _dio.get('$_base/config');
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return {};
  }
}
