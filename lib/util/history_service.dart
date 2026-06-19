import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_travel/util/user_scope.dart';

class HistoryService {
  static const String _keyViewed = 'history_viewed';
  static const String _keyLiked = 'history_liked';
  static const String _keyLikedPlacesData = 'history_liked_places_data';
  static const int _maxHistory = 20;

  static Future<void> recordView(String name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> history = await getViewed();
    history.remove(name);
    history.insert(0, name);
    if (history.length > _maxHistory) history.removeLast();
    final String key = await UserScope.key(_keyViewed);
    await prefs.setString(key, jsonEncode(history));
  }

  static Future<void> toggleLike(String name, {Map<String, dynamic>? placeData}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> liked = await getLiked();
    final String key = await UserScope.key(_keyLiked);
    final String dataKey = await UserScope.key(_keyLikedPlacesData);
    if (liked.contains(name)) {
      liked.remove(name);
      final List<Map<String, dynamic>> stored = await getLikedPlacesData();
      stored.removeWhere((Map<String, dynamic> p) => p['name'] == name);
      await prefs.setString(dataKey, jsonEncode(stored));
    } else {
      liked.add(name);
      if (placeData != null) {
        final List<Map<String, dynamic>> stored = await getLikedPlacesData();
        stored.removeWhere((Map<String, dynamic> p) => p['name'] == name);
        stored.add(placeData);
        await prefs.setString(dataKey, jsonEncode(stored));
      }
    }
    await prefs.setString(key, jsonEncode(liked));
  }

  static Future<List<Map<String, dynamic>>> getLikedPlacesData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String dataKey = await UserScope.key(_keyLikedPlacesData);
    final String? raw = prefs.getString(dataKey);
    if (raw == null) return <Map<String, dynamic>>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((dynamic e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<bool> isLiked(String name) async {
    return (await getLiked()).contains(name);
  }

  static Future<List<String>> getLiked() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = await UserScope.key(_keyLiked);
    final String? raw = prefs.getString(key);
    if (raw == null) return <String>[];
    return List<String>.from(jsonDecode(raw) as List);
  }

  static Future<List<String>> getViewed() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = await UserScope.key(_keyViewed);
    final String? raw = prefs.getString(key);
    if (raw == null) return <String>[];
    return List<String>.from(jsonDecode(raw) as List);
  }
}
