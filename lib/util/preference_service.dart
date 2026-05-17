import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _keyTags = 'pref_tags';
  static const String _keyBudget = 'pref_budget';
  static const String _keyDone = 'pref_setup_done';

  static const List<String> allTags = <String>[
    'Beach',
    'Adventure',
    'Culture',
    'Food',
    'Shopping',
    'Budget',
  ];

  static Future<void> save({
    required List<String> tags,
    required String budget,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTags, jsonEncode(tags));
    await prefs.setString(_keyBudget, budget);
    await prefs.setBool(_keyDone, true);
  }

  static Future<List<String>> getTags() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_keyTags);
    if (raw == null) return <String>[];
    return List<String>.from(jsonDecode(raw) as List);
  }

  static Future<String> getBudget() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBudget) ?? 'mid';
  }

  static Future<bool> get isSetupDone async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDone) ?? false;
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTags);
    await prefs.remove(_keyBudget);
    await prefs.remove(_keyDone);
  }
}
