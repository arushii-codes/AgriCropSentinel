import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = "jwt_token";

  /// Save JWT token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Remove JWT token (logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> saveBool(String Key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Key, value);
  }

  static Future<bool?> getBool(String Key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Key);
  }
}
