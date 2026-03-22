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

  static String? getToken() => _prefs?.getString(AppConstants.tokenKey);

  static Future<void> clear() async {
    final prefs = await _ensurePrefs();
    await prefs.clear();
  }
}
