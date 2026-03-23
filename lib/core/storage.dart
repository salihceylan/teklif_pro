import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class Storage {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> init() async {
    await _ensurePrefs();
  }

  static Future<void> saveToken(String token) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(key, value);
  }

  static String? getToken() => _prefs?.getString(AppConstants.tokenKey);

  static bool getBool(String key, {bool defaultValue = false}) =>
      _prefs?.getBool(key) ?? defaultValue;

  static Future<void> remove(String key) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(key);
  }

  static Future<void> clear() async {
    await remove(AppConstants.tokenKey);
    await remove(AppConstants.userKey);
  }
}
