import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/storage.dart';

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
    if (token == null) return;
    try {
      _user = await _service.me();
      notifyListeners();
    } catch (_) {
      await Storage.clear();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.login(email, password);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
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
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map) return data['detail']?.toString() ?? 'Bir hata oluştu';
    } catch (_) {}
    return 'Bağlantı hatası';
  }
}
