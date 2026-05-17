import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _keyPhone = 'user_phone';
  static const String _keyProvider = 'user_provider';

  static Future<void> save(String phone, String provider) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyProvider, provider);
  }

  static Future<Map<String, String>?> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? phone = prefs.getString(_keyPhone);
    final String? provider = prefs.getString(_keyProvider);
    if (phone == null || provider == null) return null;
    return <String, String>{'phone': phone, 'provider': provider};
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyProvider);
  }

  static Future<bool> get isLoggedIn async {
    final Map<String, String>? session = await load();
    return session != null;
  }
}
