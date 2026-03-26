import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/browser_push_manager.dart';
import '../core/storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> tryAutoLogin() async {
    final token = Storage.getToken();
    if (token == null) {
      return;
    }
    try {
      _user = await _service.me();
      await BrowserPushManager.instance.syncCurrentUser();
      notifyListeners();
    } catch (e) {
      if (_isTokenInvalid(e)) {
        await Storage.clear();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.login(email, password);
      await BrowserPushManager.instance.syncCurrentUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseApiError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? companyName,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        companyName: companyName,
      );
      await BrowserPushManager.instance.syncCurrentUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseApiError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await BrowserPushManager.instance.unsubscribeCurrentUser();
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> completeExternalLogin({
    required String accessToken,
    required User user,
  }) async {
    await Storage.saveToken(accessToken);
    _user = user;
    await BrowserPushManager.instance.syncCurrentUser();
    notifyListeners();
  }

  bool _isTokenInvalid(Object error) => isTokenExpiredError(error);
}
