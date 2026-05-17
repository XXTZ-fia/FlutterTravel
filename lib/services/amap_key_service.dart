import 'package:shared_preferences/shared_preferences.dart';

class AmapKeyService {
  static const String _key = 'amap_api_key';

  static Future<void> save(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, key.trim());
  }

  static Future<String> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? '';
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<bool> get isConfigured async {
    final String key = await load();
    return key.isNotEmpty;
  }
}
