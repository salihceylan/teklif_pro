import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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
    } catch (error) {
      if (_isTokenInvalid(error)) {
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
    } catch (error) {
      _error = _parseError(error);
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
    } catch (error) {
      _error = _parseError(error);
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

  String _parseError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Bağlantı hatası';
      }
    }
    return 'Bir hata oluştu';
  }

  bool _isTokenInvalid(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return statusCode == 401 || statusCode == 403;
    }
    return false;
  }
}
