import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const String _keyViewed = 'history_viewed';
  static const String _keyLiked = 'history_liked';
  static const int _maxHistory = 20;

  static Future<void> recordView(String name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> history = await getViewed();
    history.remove(name);
    history.insert(0, name);
    if (history.length > _maxHistory) history.removeLast();
    await prefs.setString(_keyViewed, jsonEncode(history));
  }

  static Future<void> toggleLike(String name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> liked = await getLiked();
    if (liked.contains(name)) {
      liked.remove(name);
    } else {
      liked.add(name);
    }
    await prefs.setString(_keyLiked, jsonEncode(liked));
  }

  static Future<bool> isLiked(String name) async {
    return (await getLiked()).contains(name);
  }

  static Future<List<String>> getLiked() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_keyLiked);
    if (raw == null) return <String>[];
    return List<String>.from(jsonDecode(raw) as List);
  }

  static Future<List<String>> getViewed() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_keyViewed);
    if (raw == null) return <String>[];
    return List<String>.from(jsonDecode(raw) as List);
  }
}
