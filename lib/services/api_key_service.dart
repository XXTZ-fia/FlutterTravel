import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyService {
  static const String _keyDeepSeek = 'deepseek_api_key';

  static Future<void> save(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeepSeek, key.trim());
  }

  static Future<String> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDeepSeek) ?? '';
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeepSeek);
  }

  static Future<bool> get isConfigured async {
    final String key = await load();
    return key.isNotEmpty;
  }
}
