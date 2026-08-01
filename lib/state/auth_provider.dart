import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// App-wide auth state. Screens call the async methods directly and catch
/// [ApiException] themselves for form-level error display; this class only
/// tracks the resulting session state.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  AppUser? _user;
  AuthStatus _status = AuthStatus.unknown;
  bool _busy = false;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get busy => _busy;

  Future<void> restoreSession() async {
    _setBusy(true);
    try {
      final user = await _authService.getSession();
      _user = user;
      _status = user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } catch (_) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    _setBusy(true);
    try {
      final user = await _authService.login(email: email, password: password);
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signup({required String email, required String password}) async {
    _setBusy(true);
    try {
      final user = await _authService.signup(email: email, password: password);
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> requestLoginCode(String email) async {
    _setBusy(true);
    try {
      await _authService.requestLoginCode(email);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> confirmLoginCode(String code) async {
    _setBusy(true);
    try {
      final user = await _authService.confirmLoginCode(code);
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    _setBusy(true);
    try {
      await _authService.requestPasswordReset(email);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> resetPassword({required String key, required String password}) async {
    _setBusy(true);
    try {
      await _authService.resetPassword(key: key, password: password);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    try {
      await _authService.logout();
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
