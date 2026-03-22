import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class Storage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    await _prefs!.setString(AppConstants.tokenKey, token);
  }

  static String? getToken() => _prefs!.getString(AppConstants.tokenKey);

  static Future<void> clear() async => await _prefs!.clear();
}
