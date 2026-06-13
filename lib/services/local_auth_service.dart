import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const String _accountsKey = 'local_accounts';

  static Future<List<Map<String, dynamic>>> getAccounts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    return (jsonDecode(raw) as List<dynamic>)
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<bool> register({
    required String phone,
    required String password,
  }) async {
    final List<Map<String, dynamic>> accounts = await getAccounts();
    final bool exists = accounts.any((Map<String, dynamic> account) {
      return (account['phone'] as String? ?? '') == phone;
    });
    if (exists) return false;

    accounts.add(<String, dynamic>{
      'phone': phone,
      'password': password,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _saveAccounts(accounts);
    return true;
  }

  static Future<bool> login({
    required String phone,
    required String password,
  }) async {
    final List<Map<String, dynamic>> accounts = await getAccounts();
    return accounts.any((Map<String, dynamic> account) {
      return (account['phone'] as String? ?? '') == phone &&
          (account['password'] as String? ?? '') == password;
    });
  }

  static Future<bool> exists(String phone) async {
    final List<Map<String, dynamic>> accounts = await getAccounts();
    return accounts.any((Map<String, dynamic> account) {
      return (account['phone'] as String? ?? '') == phone;
    });
  }

  static Future<void> _saveAccounts(List<Map<String, dynamic>> accounts) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }
}
