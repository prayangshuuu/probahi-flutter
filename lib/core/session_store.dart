import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// Local persistence for the allauth headless session token (secure
/// storage) and the user-editable tenant base URL (shared preferences).
class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  Future<String?> readSessionToken() {
    return _secureStorage.read(key: AppConfig.sessionTokenKey);
  }

  Future<void> writeSessionToken(String token) {
    return _secureStorage.write(key: AppConfig.sessionTokenKey, value: token);
  }

  Future<void> clearSessionToken() {
    return _secureStorage.delete(key: AppConfig.sessionTokenKey);
  }

  Future<String> readBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppConfig.baseUrlPrefKey);
    if (stored == null || stored.trim().isEmpty) {
      return AppConfig.defaultBaseUrl;
    }
    return stored;
  }

  Future<void> writeBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.baseUrlPrefKey, url);
  }

  Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.baseUrlPrefKey);
  }
}
