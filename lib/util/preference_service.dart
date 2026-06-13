import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_travel/util/travel_tags.dart';
import 'package:flutter_travel/util/user_scope.dart';

class PreferenceService {
  static const String _keyTags = 'pref_tags';
  static const String _keyBudget = 'pref_budget';
  static const String _keyDone = 'pref_setup_done';

  static const List<String> allTags = TravelTags.allTags;

  static Future<void> save({
    required List<String> tags,
    required String budget,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String tagsKey = await UserScope.key(_keyTags);
    final String budgetKey = await UserScope.key(_keyBudget);
    final String doneKey = await UserScope.key(_keyDone);
    await prefs.setString(tagsKey, jsonEncode(tags));
    await prefs.setString(budgetKey, budget);
    await prefs.setBool(doneKey, true);
  }

  static Future<List<String>> getTags() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = await UserScope.key(_keyTags);
    final String? raw = prefs.getString(key);
    if (raw == null) return <String>[];
    return List<String>.from(jsonDecode(raw) as List);
  }

  static Future<String> getBudget() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = await UserScope.key(_keyBudget);
    return prefs.getString(key) ?? 'mid';
  }

  static Future<bool> get isSetupDone async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = await UserScope.key(_keyDone);
    return prefs.getBool(key) ?? false;
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String tagsKey = await UserScope.key(_keyTags);
    final String budgetKey = await UserScope.key(_keyBudget);
    final String doneKey = await UserScope.key(_keyDone);
    await prefs.remove(tagsKey);
    await prefs.remove(budgetKey);
    await prefs.remove(doneKey);
  }
}
